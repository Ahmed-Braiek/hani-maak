from __future__ import annotations

import threading
from pathlib import Path
from typing import Any

import torch
from funasr import AutoModel

from .config import settings
from .schemas import CANONICAL_EMOTIONS

_MODEL: Any | None = None
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
    "neutral": "neutral",
    "other": "other",
    "sadness": "sad",
    "sad": "sad",
    "surprise": "surprised",
    "surprised": "surprised",
    "unknown": "unknown",
}


def resolved_device() -> str:
    if settings.device != "auto":
        return settings.device
    return "cuda" if torch.cuda.is_available() else "cpu"


def load_model() -> Any:
    global _MODEL
    if _MODEL is not None:
        return _MODEL
    with _LOCK:
        if _MODEL is None:
            _MODEL = AutoModel(
                model=settings.model_id,
                hub="hf",
                device=resolved_device(),
            )
    return _MODEL


def model_loaded() -> bool:
    return _MODEL is not None


def _canonical(label: str) -> str:
    normalized = label.strip().lower().replace("-", "_").replace(" ", "_")
    if normalized in ALIASES:
        return ALIASES[normalized]
    for key, value in ALIASES.items():
        if key in normalized:
            return value
    return "unknown"


def normalize_model_result(raw: Any) -> dict[str, float]:
    item = raw[0] if isinstance(raw, list) and raw else raw
    if not isinstance(item, dict):
        return {name: (1.0 if name == "unknown" else 0.0) for name in CANONICAL_EMOTIONS}

    labels = item.get("labels") or item.get("label") or item.get("emotion_labels")
    scores = item.get("scores") or item.get("score") or item.get("emotion_scores")

    values = {name: 0.0 for name in CANONICAL_EMOTIONS}
    if isinstance(labels, list) and isinstance(scores, list):
        for label, score in zip(labels, scores):
            try:
                values[_canonical(str(label))] += float(score)
            except (TypeError, ValueError):
                continue
    elif isinstance(scores, dict):
        for label, score in scores.items():
            try:
                values[_canonical(str(label))] += float(score)
            except (TypeError, ValueError):
                continue
    elif isinstance(item.get("text"), str):
        values[_canonical(item["text"])] = float(item.get("confidence") or 1.0)
    else:
        for key, score in item.items():
            canonical = _canonical(str(key))
            if canonical == "unknown" and str(key).lower() not in {"unknown", "other"}:
                continue
            try:
                values[canonical] += float(score)
            except (TypeError, ValueError):
                continue

    total = sum(max(0.0, score) for score in values.values())
    if total <= 0:
        values["unknown"] = 1.0
        return values
    return {name: max(0.0, value) / total for name, value in values.items()}


def infer_file(path: str | Path) -> dict[str, float]:
    model = load_model()
    raw = model.generate(
        str(path),
        granularity="utterance",
        extract_embedding=False,
    )
    return normalize_model_result(raw)
