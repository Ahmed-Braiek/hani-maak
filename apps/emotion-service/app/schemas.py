from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

EmotionName = Literal[
    "angry",
    "disgusted",
    "fearful",
    "happy",
    "neutral",
    "other",
    "sad",
    "surprised",
    "unknown",
]

CANONICAL_EMOTIONS: tuple[str, ...] = (
    "angry",
    "disgusted",
    "fearful",
    "happy",
    "neutral",
    "other",
    "sad",
    "surprised",
    "unknown",
)


class EmotionSegment(BaseModel):
    segment_index: int
    start_ms: int
    end_ms: int
    duration_ms: int
    voiced_duration_ms: int
    dominant_emotion: EmotionName
    confidence: float = Field(ge=0, le=1)
    scores: dict[str, float]


class EmotionAnalysisResponse(BaseModel):
    conversation_id: str
    model: str
    model_version: str | None = None
    status: Literal["completed", "insufficient_audio", "failed"]
    dominant_emotion: EmotionName | None = None
    confidence: float | None = Field(default=None, ge=0, le=1)
    distribution: dict[str, float] | None = None
    segments: list[EmotionSegment] = []
    audio_duration_ms: int = 0
    analyzed_speech_ms: int = 0
    processing_ms: int = 0
    failure_code: str | None = None
    failure_message: str | None = None
