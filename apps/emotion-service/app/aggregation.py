from __future__ import annotations

from .schemas import CANONICAL_EMOTIONS, EmotionSegment


def normalize_distribution(values: dict[str, float]) -> dict[str, float]:
    clean = {name: max(0.0, float(values.get(name, 0.0))) for name in CANONICAL_EMOTIONS}
    total = sum(clean.values())
    if total <= 0:
        clean["unknown"] = 1.0
        return clean
    return {name: score / total for name, score in clean.items()}


def aggregate_segments(
    segments: list[EmotionSegment],
) -> tuple[str, float, dict[str, float]]:
    if not segments:
        return "unknown", 0.0, normalize_distribution({"unknown": 1.0})

    weighted = {name: 0.0 for name in CANONICAL_EMOTIONS}
    total_weight = 0.0
    for segment in segments:
        weight = max(1.0, float(segment.voiced_duration_ms))
        total_weight += weight
        for name in CANONICAL_EMOTIONS:
            weighted[name] += float(segment.scores.get(name, 0.0)) * weight

    distribution = normalize_distribution(
        {name: value / total_weight for name, value in weighted.items()}
    )
    dominant = max(distribution, key=distribution.get)
    return dominant, float(distribution[dominant]), distribution
