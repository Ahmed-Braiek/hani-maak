from __future__ import annotations

import base64
import json
import re
from typing import Any

from google.genai import types

from .config import settings
from .google_client import create_google_client


def _extract_json(text: str) -> dict[str, Any]:
    value = text.strip()
    if value.startswith("```"):
        value = re.sub(r"^```(?:json)?\s*", "", value, flags=re.I)
        value = re.sub(r"\s*```$", "", value)
    start = value.find("{")
    end = value.rfind("}")
    if start >= 0 and end > start:
        value = value[start : end + 1]
    parsed = json.loads(value)
    if not isinstance(parsed, dict):
        raise ValueError("ocr_response_not_object")
    return parsed


async def extract_prescription(
    *,
    image_base64: str,
    mime_type: str,
    document_type: str,
    locale: str,
) -> dict[str, Any]:
    raw = image_base64.split(",", 1)[-1]
    try:
        image_bytes = base64.b64decode(raw, validate=True)
    except Exception as error:
        raise ValueError("invalid_image_base64") from error

    if not image_bytes or len(image_bytes) > 8 * 1024 * 1024:
        raise ValueError("image_size_invalid")

    if mime_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise ValueError("unsupported_image_type")

    prompt = f"""
You are an OCR extraction component for Hani Maak, a caregiver app.
Read the attached {document_type} image carefully.

Extract only text that is actually visible. Never invent a medication, dose,
frequency, duration, prescriber, date, or instruction.

Return strict JSON only with this shape:
{{
  "documentType": "prescription|medication_box",
  "languageHints": ["tn","ar","fr","en"],
  "rawText": "best-effort transcription",
  "prescriber": "string or null",
  "date": "string or null",
  "medications": [
    {{
      "name": "string",
      "dose": "string or null",
      "frequency": "string or null",
      "duration": "string or null",
      "instructions": "string or null",
      "confidence": 0.0
    }}
  ],
  "warnings": ["ambiguous or unreadable fields that require caregiver review"]
}}

The caregiver language is {locale}. The image may contain Tunisian Arabic,
Arabic, French, or English, including code-switching. Do not translate brand
names. Every extracted medication must be reviewed by the caregiver before it
can be saved.
""".strip()

    client = create_google_client()
    response = await client.aio.models.generate_content(
        model=settings.text_model,
        contents=[
            types.Content(
                role="user",
                parts=[
                    types.Part(text=prompt),
                    types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
                ],
            )
        ],
        config=types.GenerateContentConfig(
            temperature=0.0,
            max_output_tokens=1800,
            response_mime_type="application/json",
        ),
    )

    text = (response.text or "").strip()
    if not text:
        raise RuntimeError("empty_ocr_response")

    result = _extract_json(text)
    result["requiresReview"] = True
    result["model"] = settings.text_model
    return result
