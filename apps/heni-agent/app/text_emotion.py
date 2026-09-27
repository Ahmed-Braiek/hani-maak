from __future__ import annotations

import asyncio
import json
from typing import Any

from google.genai import types

from .config import settings
from .google_client import create_google_client

_client = create_google_client()

_CANONICAL = (
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


def _normalize_distribution(raw: Any) -> dict[str, float]:
    values = {name: 0.0 for name in _CANONICAL}
    if isinstance(raw, dict):
        for key, value in raw.items():
            label = str(key).strip().lower()
            aliases = {
                "anger": "angry",
                "disgust": "disgusted",
                "fear": "fearful",
                "happiness": "happy",
                "joy": "happy",
                "sadness": "sad",
                "surprise": "surprised",
            }
            label = aliases.get(label, label)
            if label not in values:
                label = "other"
            try:
                values[label] += max(0.0, float(value))
            except (TypeError, ValueError):
                continue

    total = sum(values.values())
    if total <= 0:
        values["unknown"] = 1.0
        return values
    return {key: value / total for key, value in values.items()}


def _canonical(label: Any) -> str:
    value = str(label or "").strip().lower()
    aliases = {
        "anger": "angry",
        "disgust": "disgusted",
        "fear": "fearful",
        "happiness": "happy",
        "joy": "happy",
        "sadness": "sad",
        "surprise": "surprised",
    }
    value = aliases.get(value, value)
    return value if value in _CANONICAL else "unknown"


def _timeline(
    turns: list[str],
    turn_results: list[dict[str, Any]],
    *,
    audio_duration_ms: int,
) -> list[dict[str, Any]]:
    if not turns or audio_duration_ms <= 0:
        return []

    weights = [max(1, len(turn.strip())) for turn in turns]
    total_weight = max(1, sum(weights))
    cursor = 0
    timeline: list[dict[str, Any]] = []

    for index, turn in enumerate(turns):
        duration = (
            audio_duration_ms - cursor
            if index == len(turns) - 1
            else max(1, round(audio_duration_ms * weights[index] / total_weight))
        )
        end = min(audio_duration_ms, cursor + duration)
        item = turn_results[index] if index < len(turn_results) else {}
        scores = _normalize_distribution(item.get("distribution"))
        dominant = _canonical(item.get("emotion"))
        if dominant == "unknown":
            dominant = max(scores, key=scores.get)
        try:
            confidence = float(item.get("confidence"))
        except (TypeError, ValueError):
            confidence = float(scores.get(dominant, 0.0))

        timeline.append(
            {
                "segment_index": index,
                "start_ms": cursor,
                "end_ms": max(cursor + 1, end),
                "duration_ms": max(1, end - cursor),
                "voiced_duration_ms": max(1, end - cursor),
                "dominant_emotion": dominant,
                "confidence": max(0.0, min(1.0, confidence)),
                "scores": scores,
            }
        )
        cursor = end

    return timeline


async def analyze_transcript_emotion(
    *,
    conversation_id: str,
    turns: list[str],
    locale: str,
    audio_duration_ms: int,
) -> dict[str, Any]:
    cleaned = [turn.strip() for turn in turns if turn and turn.strip()]
    if not cleaned:
        return {
            "status": "insufficient_audio",
            "model": f"gemini_text_emotion_fallback:{settings.text_model}",
            "analysis_version": "v2-text-fallback",
            "audio_duration_ms": max(0, audio_duration_ms),
            "analyzed_speech_ms": 0,
            "segments": [],
        }

    transcript = "\n".join(
        f"{index + 1}. {turn[:900]}" for index, turn in enumerate(cleaned[-24:])
    )

    prompt = f"""
You are the Hani Maak post-call emotion fallback classifier.
Analyze ONLY the patient's transcribed words below. This is a fallback when the
vocal emotion model is slow or unavailable. It is NOT a psychiatric or medical
diagnosis and must not infer disorders.

Conversation locale: {locale}
Allowed labels exactly:
angry, disgusted, fearful, happy, neutral, other, sad, surprised, unknown

Return JSON only with this exact shape:
{{
  "dominant_emotion": "neutral",
  "confidence": 0.0,
  "distribution": {{
    "angry": 0.0,
    "disgusted": 0.0,
    "fearful": 0.0,
    "happy": 0.0,
    "neutral": 0.0,
    "other": 0.0,
    "sad": 0.0,
    "surprised": 0.0,
    "unknown": 0.0
  }},
  "turns": [
    {{
      "index": 0,
      "emotion": "neutral",
      "confidence": 0.0,
      "distribution": {{"neutral": 1.0}}
    }}
  ]
}}

The distribution must sum approximately to 1. Confidence must be 0..1.
Use linguistic emotional signals only. If the text is ambiguous, prefer neutral
or unknown and lower confidence. Preserve Tunisian Derja, Arabic, French,
English, and code-switching as valid language.

PATIENT TRANSCRIPT:
{transcript}
""".strip()

    try:
        response = await asyncio.wait_for(
            _client.aio.models.generate_content(
                model=settings.text_model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    temperature=0.1,
                    max_output_tokens=700,
                ),
            ),
            timeout=min(8.5, max(4.0, settings.model_timeout_seconds)),
        )
        payload = json.loads((response.text or "{}").strip())
        if not isinstance(payload, dict):
            raise ValueError("invalid_json_shape")
    except Exception as exc:
        return {
            "status": "failed",
            "failure_code": "TEXT_FALLBACK_FAILED",
            "failure_message": type(exc).__name__,
            "model": f"gemini_text_emotion_fallback:{settings.text_model}",
            "analysis_version": "v2-text-fallback",
            "audio_duration_ms": max(0, audio_duration_ms),
            "analyzed_speech_ms": 0,
            "segments": [],
        }

    distribution = _normalize_distribution(payload.get("distribution"))
    dominant = _canonical(payload.get("dominant_emotion"))
    if dominant == "unknown":
        dominant = max(distribution, key=distribution.get)
    try:
        confidence = float(payload.get("confidence"))
    except (TypeError, ValueError):
        confidence = float(distribution.get(dominant, 0.0))
    confidence = max(0.0, min(1.0, confidence))

    raw_turns = payload.get("turns")
    turn_results = raw_turns if isinstance(raw_turns, list) else []
    segments = _timeline(
        cleaned[-24:],
        [item for item in turn_results if isinstance(item, dict)],
        audio_duration_ms=max(0, audio_duration_ms),
    )

    return {
        "conversation_id": conversation_id,
        "status": "completed",
        "dominant_emotion": dominant,
        "confidence": confidence,
        "distribution": distribution,
        "segments": segments,
        "audio_duration_ms": max(0, audio_duration_ms),
        "analyzed_speech_ms": max(0, audio_duration_ms),
        "processing_ms": 0,
        "model": f"gemini_text_emotion_fallback:{settings.text_model}",
        "analysis_version": "v2-text-fallback",
        "fallback_source": "patient_transcript",
    }
