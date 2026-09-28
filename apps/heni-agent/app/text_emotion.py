from __future__ import annotations

import asyncio
import json
import re
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


def _extract_json(text: str) -> dict[str, Any]:
    cleaned = text.strip()
    if cleaned.startswith("~~~"):
        cleaned = re.sub(r"^~~~(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*~~~$", "", cleaned)
    try:
        value = json.loads(cleaned)
        return value if isinstance(value, dict) else {}
    except ValueError:
        match = re.search(r"\{.*\}", cleaned, flags=re.S)
        if not match:
            return {}
        try:
            value = json.loads(match.group(0))
            return value if isinstance(value, dict) else {}
        except ValueError:
            return {}


async def analyze_text_emotion(
    *,
    conversation_id: str,
    transcripts: list[str],
    locale: str,
) -> dict[str, Any]:
    cleaned = [item.strip() for item in transcripts if item and item.strip()]
    if not cleaned:
        return {
            "status": "insufficient_audio",
            "model": f"{settings.text_model}:text-emotion-fallback",
            "audio_duration_ms": 0,
            "analyzed_speech_ms": 0,
            "segments": [],
        }

    joined = "\n".join(
        f"{index + 1}. {text}" for index, text in enumerate(cleaned[-12:])
    )
    prompt = f"""
You are a post-call emotion fallback classifier for Hani Maak.

The dedicated acoustic emotion model is slow or unavailable, so estimate ONLY
the emotional tone supported by the user's transcribed words. Do not diagnose
mental illness, depression, anxiety disorder, instability, or medical state.
The text may be Tunisian Derja, Arabic, French, English, or code-switched.

Conversation locale: {locale}
User transcript turns:
{joined}

Return JSON only with exactly this shape:
{{
  "dominant_emotion": "neutral|happy|sad|angry|fearful|surprised|disgusted|other|unknown",
  "confidence": 0.0,
  "distribution": {{
    "neutral": 0.0,
    "happy": 0.0,
    "sad": 0.0,
    "angry": 0.0,
    "fearful": 0.0,
    "surprised": 0.0,
    "disgusted": 0.0,
    "other": 0.0,
    "unknown": 0.0
  }}
}}

Rules:
- Confidence must reflect uncertainty from text-only inference.
- Distribution values must sum approximately to 1.
- Prefer neutral/unknown when the words do not clearly support an emotion.
- Never infer a psychiatric or medical diagnosis.
"""

    try:
        response = await asyncio.wait_for(
            _client.aio.models.generate_content(
                model=settings.text_model,
                contents=[
                    types.Content(role="user", parts=[types.Part(text=prompt)])
                ],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=280,
                    response_mime_type="application/json",
                ),
            ),
            timeout=7.0,
        )
    except Exception as exc:
        return {
            "status": "failed",
            "failure_code": "TEXT_FALLBACK_FAILED",
            "failure_message": type(exc).__name__,
            "model": f"{settings.text_model}:text-emotion-fallback",
            "segments": [],
        }

    body = _extract_json(response.text or "")
    distribution = _normalize_distribution(body.get("distribution"))
    dominant = str(body.get("dominant_emotion") or "").strip().lower()
    aliases = {
        "anger": "angry",
        "disgust": "disgusted",
        "fear": "fearful",
        "happiness": "happy",
        "sadness": "sad",
        "surprise": "surprised",
    }
    dominant = aliases.get(dominant, dominant)
    if dominant not in _CANONICAL:
        dominant = max(distribution, key=distribution.get)

    try:
        confidence = float(body.get("confidence"))
    except (TypeError, ValueError):
        confidence = float(distribution.get(dominant, 0.0))
    confidence = max(0.0, min(1.0, confidence))
    confidence = min(confidence, 0.78)

    return {
        "conversation_id": conversation_id,
        "status": "completed",
        "dominant_emotion": dominant,
        "confidence": confidence,
        "distribution": distribution,
        "segments": [],
        "audio_duration_ms": 0,
        "analyzed_speech_ms": 0,
        "processing_ms": 0,
        "model": f"{settings.text_model}:text-emotion-fallback",
        "model_version": "text-fallback-v1",
        "analysis_source": "gemini_text_fallback",
    }
