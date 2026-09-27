from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    service_secret: str = os.getenv("EMOTION_SERVICE_SECRET", "")
    model_id: str = os.getenv(
        "EMOTION_MODEL_ID",
        "Aniemore/wavlm-emotion-v1-crosslingual",
    )
    model_subfolder: str = os.getenv("EMOTION_MODEL_SUBFOLDER", "int4")
    device: str = os.getenv("EMOTION_DEVICE", "cpu")
    min_speech_seconds: float = float(os.getenv("EMOTION_MIN_SPEECH_SECONDS", "3"))
    target_segment_seconds: float = float(os.getenv("EMOTION_TARGET_SEGMENT_SECONDS", "6"))
    max_segment_seconds: float = float(os.getenv("EMOTION_MAX_SEGMENT_SECONDS", "10"))
    min_confidence: float = float(os.getenv("EMOTION_MIN_CONFIDENCE", "0.45"))


settings = Settings()


def validate_settings() -> None:
    if not settings.service_secret:
        raise RuntimeError("EMOTION_SERVICE_SECRET is required")
