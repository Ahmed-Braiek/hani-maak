from __future__ import annotations

import threading
from pathlib import Path
from typing import Any

import numpy as np
import soundfile as sf
import torch
from transformers import AutoFeatureExtractor, AutoModelForAudioClassification

from .config import settings
from .schemas import CANONICAL_EMOTIONS

_MODEL: Any | None = None
_FEATURE_EXTRACTOR: Any | None = None
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
    "enthusiasm": "happy",
    "enthusiastic": "happy",
    "positive": "happy",
    "neutral": "neutral",
    "other": "other",
    "sadness": "sad",
    "sad": "sad",
    "surprise": "surprised",
    "surprised": "surprised",
    "unknown": "unknown",
}


def resolved_device() -> str:
    if settings.device and settings.device != "auto":
        return settings.device
    return "cuda" if torch.cuda.is_available() else "cpu"


def load_model() -> Any:
    global _MODEL, _FEATURE_EXTRACTOR
    if _MODEL is not None and _FEATURE_EXTRACTOR is not None:
        return _MODEL

    with _LOCK:
        if _MODEL is None or _FEATURE_EXTRACTOR is None:
            kwargs: dict[str, Any] = {
                "trust_remote_code": True,
                "low_cpu_mem_usage": True,
            }
            if settings.model_subfolder:
                kwargs["subfolder"] = settings.model_subfolder

            _FEATURE_EXTRACTOR = AutoFeatureExtractor.from_pretrained(
                settings.model_id,
                **kwargs,
            )
            _MODEL = AutoModelForAudioClassification.from_pretrained(
                settings.model_id,
                **kwargs,
            )
            _MODEL.eval()
            _MODEL.to(resolved_device())

    return _MODEL


def model_loaded() -> bool:
    return _MODEL is not None and _FEATURE_EXTRACTOR is not None


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


def normalize_logits(labels: dict[int, str], probabilities: torch.Tensor) -> dict[str, float]:
    values = _empty_distribution()
    for index, probability in enumerate(probabilities.tolist()):
        label = labels.get(index, str(index))
        canonical = _canonical(label)
        values[canonical] += float(probability)

    total = sum(max(0.0, value) for value in values.values())
    if total <= 0:
        values["unknown"] = 1.0
        return values
    return {
        name: max(0.0, value) / total
        for name, value in values.items()
    }


def infer_file(path: str | Path) -> dict[str, float]:
    model = load_model()
    assert _FEATURE_EXTRACTOR is not None

    waveform, sample_rate = sf.read(
        str(path),
        dtype="float32",
        always_2d=False,
    )
    if sample_rate != 16000:
        raise ValueError("audio_must_be_16khz")

    if isinstance(waveform, np.ndarray) and waveform.ndim > 1:
        waveform = waveform.mean(axis=1)
    waveform = np.asarray(waveform, dtype=np.float32)

    inputs = _FEATURE_EXTRACTOR(
        waveform,
        sampling_rate=16000,
        return_tensors="pt",
        padding=True,
    )
    device = resolved_device()
    inputs = {
        key: value.to(device)
        for key, value in inputs.items()
        if isinstance(value, torch.Tensor)
    }

    with torch.inference_mode():
        logits = model(**inputs).logits
        probabilities = logits.softmax(dim=-1)[0].detach().cpu()

    id2label = {
        int(key): str(value)
        for key, value in dict(model.config.id2label).items()
    }
    return normalize_logits(id2label, probabilities)
