from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    service_secret: str = os.getenv("EMOTION_SERVICE_SECRET", "")
    model_id: str = os.getenv(
        "EMOTION_MODEL_ID",
        "onnx-community/wav2vec2-emotion-recognition-ONNX",
    )
    model_filename: str = os.getenv(
        "EMOTION_MODEL_FILENAME",
        "onnx/model_quantized.onnx",
    )
    model_cache_dir: str = os.getenv("EMOTION_MODEL_CACHE_DIR", "/tmp/hf")
    device: str = "cpu"
    onnx_intra_threads: int = int(os.getenv("EMOTION_ONNX_THREADS", "2"))
    min_speech_seconds: float = float(os.getenv("EMOTION_MIN_SPEECH_SECONDS", "3"))
    target_segment_seconds: float = float(os.getenv("EMOTION_TARGET_SEGMENT_SECONDS", "6"))
    max_segment_seconds: float = float(os.getenv("EMOTION_MAX_SEGMENT_SECONDS", "10"))
    min_confidence: float = float(os.getenv("EMOTION_MIN_CONFIDENCE", "0.45"))


settings = Settings()


def validate_settings() -> None:
    if not settings.service_secret:
        raise RuntimeError("EMOTION_SERVICE_SECRET is required")
