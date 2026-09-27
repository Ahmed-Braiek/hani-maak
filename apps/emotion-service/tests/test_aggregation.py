from app.aggregation import aggregate_segments
from app.schemas import EmotionSegment


def segment(index: int, emotion: str, confidence: float, voiced_ms: int) -> EmotionSegment:
    scores = {
        "angry": 0.0,
        "disgusted": 0.0,
        "fearful": 0.0,
        "happy": 0.0,
        "neutral": 0.0,
        "other": 0.0,
        "sad": 0.0,
        "surprised": 0.0,
        "unknown": 0.0,
    }
    scores[emotion] = confidence
    scores["neutral"] += max(0.0, 1.0 - confidence)
    return EmotionSegment(
        segment_index=index,
        start_ms=index * 6000,
        end_ms=(index + 1) * 6000,
        duration_ms=6000,
        voiced_duration_ms=voiced_ms,
        dominant_emotion=emotion,
        confidence=confidence,
        scores=scores,
    )


def test_duration_weighted_aggregation_prefers_longer_segment() -> None:
    dominant, confidence, distribution = aggregate_segments(
        [
            segment(0, "happy", 0.9, 1000),
            segment(1, "sad", 0.8, 6000),
        ]
    )
    assert dominant == "sad"
    assert 0.6 < confidence < 0.8
    assert abs(sum(distribution.values()) - 1.0) < 1e-6


def test_empty_segments_returns_unknown() -> None:
    dominant, confidence, distribution = aggregate_segments([])
    assert dominant == "unknown"
    assert confidence == 0
    assert distribution["unknown"] == 1
