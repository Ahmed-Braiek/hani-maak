from __future__ import annotations

import json
import threading
from pathlib import Path
from typing import Any

import numpy as np
import onnxruntime as ort
import soundfile as sf
from huggingface_hub import hf_hub_download

from .config import settings
from .schemas import CANONICAL_EMOTIONS

_SESSION: ort.InferenceSession | None = None
_ID2LABEL: dict[int, str] | None = None
_LOCK = threading.Lock()

ALIASES = {
    "anger": "angry",
    "angry": "angry",
    "disgust": "disgusted",
    "disgusted": "disgusted",
    "fear": "fearful",
    "fearful": "fearful",
    "happiness": "happy",
    "happy": "happy",
    "joy": "happy",
    "neutral": "neutral",
    "neutrality": "neutral",
    "calm": "neutral",
    "sadness": "sad",
    "sad": "sad",
    "surprise": "surprised",
    "surprised": "surprised",
    "ps": "surprised",
    "other": "other",
    "unknown": "unknown",
}


def resolved_device() -> str:
    return "cpu"


def _download(filename: str) -> str:
    return hf_hub_download(
        repo_id=settings.model_id,
        filename=filename,
        cache_dir=settings.model_cache_dir,
    )


def load_model() -> ort.InferenceSession:
    global _SESSION, _ID2LABEL
    if _SESSION is not None and _ID2LABEL is not None:
        return _SESSION

    with _LOCK:
        if _SESSION is None:
            model_path = _download(settings.model_filename)
            options = ort.SessionOptions()
            options.intra_op_num_threads = settings.onnx_intra_threads
            options.inter_op_num_threads = 1
            options.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
            # Railway Hobby has a hard 1 GB memory ceiling. Avoid retaining
            # large activation arenas between post-call segments.
            options.enable_cpu_mem_arena = False
            options.enable_mem_pattern = False
            options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            _SESSION = ort.InferenceSession(
                model_path,
                sess_options=options,
                providers=["CPUExecutionProvider"],
            )

        if _ID2LABEL is None:
            config_path = _download("config.json")
            config = json.loads(Path(config_path).read_text())
            raw = config.get("id2label") or {}
            _ID2LABEL = {int(key): str(value) for key, value in raw.items()}
            if not _ID2LABEL:
                _ID2LABEL = {
                    0: "angry",
                    1: "disgust",
                    2: "fear",
                    3: "happy",
                    4: "neutral",
                    5: "sad",
                    6: "surprise",
                }

    return _SESSION


def model_loaded() -> bool:
    return _SESSION is not None and _ID2LABEL is not None


def _canonical(label: str) -> str:
    normalized = label.strip().lower().replace("-", "_").replace(" ", "_")
    if normalized in ALIASES:
        return ALIASES[normalized]
    for key, value in ALIASES.items():
        if key in normalized:
            return value
    return "unknown"


def _empty_distribution() -> dict[str, float]:
    return {name: 0.0 for name in CANONICAL_EMOTIONS}


def _softmax(logits: np.ndarray) -> np.ndarray:
    values = np.asarray(logits, dtype=np.float32)
    values = values - np.max(values)
    exp = np.exp(values)
    total = float(np.sum(exp))
    if total <= 0:
        return np.zeros_like(values)
    return exp / total


def normalize_logits(probabilities: np.ndarray) -> dict[str, float]:
    values = _empty_distribution()
    labels = _ID2LABEL or {}

    for index, probability in enumerate(probabilities.tolist()):
        label = labels.get(index, str(index))
        values[_canonical(label)] += float(probability)

    total = sum(max(0.0, value) for value in values.values())
    if total <= 0:
        values["unknown"] = 1.0
        return values
    return {
        name: max(0.0, value) / total
        for name, value in values.items()
    }


def _normalize_waveform(waveform: np.ndarray) -> np.ndarray:
    waveform = np.asarray(waveform, dtype=np.float32)
    if waveform.size == 0:
        return waveform
    mean = float(np.mean(waveform))
    variance = float(np.var(waveform))
    return (waveform - mean) / np.sqrt(variance + 1e-7)


def infer_waveform(waveform: np.ndarray) -> dict[str, float]:
    session = load_model()

    normalized = _normalize_waveform(waveform)
    input_meta = session.get_inputs()[0]
    input_name = input_meta.name

    result = session.run(
        None,
        {input_name: normalized.reshape(1, -1).astype(np.float32, copy=False)},
    )
    if not result:
        raise RuntimeError("onnx_no_output")

    logits = np.asarray(result[0])
    if logits.ndim == 2:
        logits = logits[0]
    probabilities = _softmax(logits)
    return normalize_logits(probabilities)


def infer_file(path: str | Path) -> dict[str, float]:
    waveform, sample_rate = sf.read(
        str(path),
        dtype="float32",
        always_2d=False,
    )
    if sample_rate != 16000:
        raise ValueError("audio_must_be_16khz")
    if isinstance(waveform, np.ndarray) and waveform.ndim > 1:
        waveform = waveform.mean(axis=1)
    return infer_waveform(np.asarray(waveform, dtype=np.float32))
