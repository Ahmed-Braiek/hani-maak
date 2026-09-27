from __future__ import annotations

import asyncio
import json
from typing import Any

from google.genai import types

from .config import settings
from .google_client import create_google_client

_client = create_google_client()

_ALLOWED = {
    "angry",
    "disgusted",
    "fearful",
    "happy",
    "neutral",
    "other",
    "sad",
    "surprised",
    "unknown",
}


def _clean_distribution(raw: Any) -> dict[str, float]:
    values = {name: 0.0 for name in _ALLOWED}
    if isinstance(raw, dict):
        for key, value in raw.items():
            name = str(key).strip().lower()
            aliases = {
                "anger": "angry",
                "disgust": "disgusted",
                "fear": "fearful",
                "happiness": "happy",
                "sadness": "sad",
                "surprise": "surprised",
            }
            name = aliases.get(name, name)
            if name not in values:
                continue
            try:
                values[name] += max(0.0, float(value))
            except (TypeError, ValueError):
                continue

    total = sum(values.values())
    if total <= 0:
        values["unknown"] = 1.0
        return values
    return {name: value / total for name, value in values.items()}


def _extract_json(text: str) -> dict[str, Any]:
    raw = text.strip()
    if raw.startswith("```"):
        lines = raw.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        raw = "\n".join(lines).strip()
    try:
        parsed = json.loads(raw)
    except ValueError:
        start = raw.find("{")
        end = raw.rfind("}")
        if start < 0 or end <= start:
            return {}
        try:
            parsed = json.loads(raw[start : end + 1])
        except ValueError:
            return {}
    return parsed if isinstance(parsed, dict) else {}


async def analyze_transcript_emotion(
    *,
    conversation_id: str,
    transcripts: list[str],
    audio_duration_ms: int,
    locale: str,
) -> dict[str, Any]:
    cleaned = [text.strip() for text in transcripts if text and text.strip()]
    if not cleaned:
        return {
            "conversation_id": conversation_id,
            "status": "insufficient_audio",
            "model": f"{settings.text_model}-text-fallback",
            "analysis_source": "gemini_text_fallback",
            "audio_duration_ms": audio_duration_ms,
            "analyzed_speech_ms": 0,
            "segments": [],
        }

    transcript = "\n".join(
        f"Turn {index + 1}: {text}"
        for index, text in enumerate(cleaned[-20:])
    )

    prompt = f"""
You are a fallback emotion classifier for Hani Maak.

Classify ONLY the emotional tone expressed by the user's transcript below.
This is a probabilistic text fallback used only when the primary vocal-acoustic
emotion model is unavailable or too slow. It is NOT a psychiatric diagnosis.

Conversation locale: {locale}

Allowed emotions:
angry, disgusted, fearful, happy, neutral, other, sad, surprised, unknown

Return strict JSON only with:
{{
  "dominant_emotion": "one allowed emotion",
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
  "summary": "one short non-diagnostic sentence"
}}

Rules:
- Distribution must sum approximately to 1.
- Confidence must reflect uncertainty.
- For ambiguous everyday speech, prefer neutral/other/unknown rather than
  inventing distress.
- Do not infer depression, anxiety disorders, instability, or any diagnosis.
- Tunisian Derja, Arabic, French, English, and code-switching are valid.

USER TRANSCRIPT:
{transcript}
""".strip()

    response = await asyncio.wait_for(
        _client.aio.models.generate_content(
            model=settings.text_model,
            contents=[types.Content(role="user", parts=[types.Part(text=prompt)])],
            config=types.GenerateContentConfig(
                temperature=0.0,
                max_output_tokens=320,
                response_mime_type="application/json",
            ),
        ),
        timeout=8.0,
    )

    parsed = _extract_json(response.text or "")
    distribution = _clean_distribution(parsed.get("distribution"))
    dominant = str(parsed.get("dominant_emotion") or "").strip().lower()
    if dominant not in _ALLOWED:
        dominant = max(distribution, key=distribution.get)

    try:
        confidence = max(0.0, min(1.0, float(parsed.get("confidence"))))
    except (TypeError, ValueError):
        confidence = float(distribution.get(dominant, 0.0))

    # Text-only fallback confidence is capped because this path does not inspect
    # acoustic cues such as prosody, pitch, energy, or speaking rate.
    confidence = min(confidence, 0.72)

    count = len(cleaned)
    timeline: list[dict[str, Any]] = []
    if count > 0 and audio_duration_ms > 0:
        step = max(1, audio_duration_ms // count)
        for index, text in enumerate(cleaned):
            start = min(audio_duration_ms, index * step)
            end = audio_duration_ms if index == count - 1 else min(
                audio_duration_ms, (index + 1) * step
            )
            timeline.append(
                {
                    "segment_index": index,
                    "start_ms": start,
                    "end_ms": max(start + 1, end),
                    "duration_ms": max(1, end - start),
                    "voiced_duration_ms": max(1, end - start),
                    "dominant_emotion": dominant,
                    "confidence": confidence,
                    "scores": distribution,
                    "text_fallback": True,
                    "text_excerpt": text[:180],
                }
            )

    return {
        "conversation_id": conversation_id,
        "status": "completed",
        "model": f"{settings.text_model}-text-fallback",
        "analysis_source": "gemini_text_fallback",
        "dominant_emotion": dominant,
        "confidence": confidence,
        "distribution": distribution,
        "summary": str(parsed.get("summary") or "").strip()[:400],
        "segments": timeline,
        "audio_duration_ms": audio_duration_ms,
        "analyzed_speech_ms": audio_duration_ms,
        "processing_ms": 0,
    }
