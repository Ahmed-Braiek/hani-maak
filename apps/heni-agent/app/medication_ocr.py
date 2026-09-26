from __future__ import annotations

import base64
import re
from typing import Literal

from google.genai import types
from pydantic import BaseModel, Field

from .config import settings
from .google_client import create_google_client


class MedicationCandidate(BaseModel):
    medicationName: str | None = None
    strengthText: str | None = None
    doseText: str | None = None
    frequencyText: str | None = None
    durationText: str | None = None
    scheduleTimes: list[str] = Field(default_factory=list)
    instructions: str | None = None
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)


class MedicationOcrResult(BaseModel):
    documentType: Literal["prescription", "medication_box", "unknown"] = "unknown"
    medications: list[MedicationCandidate] = Field(default_factory=list)
    visibleText: list[str] = Field(default_factory=list)
    confidenceNotes: list[str] = Field(default_factory=list)
    languageHints: list[Literal["tn", "ar", "fr", "en"]] = Field(default_factory=list)


_DATA_URL = re.compile(
    r"^data:(image/(?:jpeg|jpg|png|webp));base64,([A-Za-z0-9+/=\s]+)$",
    re.IGNORECASE,
)


async def analyze_medication_image(
    *,
    image_data_url: str,
    mode: str = "prescription",
) -> MedicationOcrResult:
    match = _DATA_URL.match(image_data_url.strip())
    if not match:
        raise ValueError("unsupported_medication_image")

    mime_type = match.group(1).lower().replace("image/jpg", "image/jpeg")
    try:
        raw = base64.b64decode(match.group(2), validate=False)
    except Exception as exc:
        raise ValueError("invalid_medication_image") from exc

    if not raw or len(raw) > 7_500_000:
        raise ValueError("medication_image_too_large")

    client = create_google_client()
    prompt = f"""
You are the OCR extraction layer for Hani Maak.
The image is expected to be a {mode}.

Extract ONLY information visibly present in the image.
Allowed output languages for languageHints: Tunisian Arabic/Derja (tn), Arabic (ar), French (fr), English (en).

Important safety rules:
- Do not diagnose.
- Do not recommend a medicine.
- Do not invent a dose, frequency, duration, treatment indication, or schedule.
- If handwriting or print is unclear, leave the field null and add a confidence note.
- A medicine may appear by brand or generic name; reproduce the visible name.
- doseText is the visible amount to take (for example "1 comprimé") only if written.
- strengthText is package/form strength (for example "5 mg") only if written.
- frequencyText is the visible frequency (for example "1 fois/jour", "matin et soir") only if written.
- durationText is the visible treatment duration only if written.
- scheduleTimes may include explicit clock times only when actually written. Do not invent times from "morning/evening".
- Return all readable medication candidates.
- visibleText should contain short meaningful OCR lines, not a fabricated transcription.
""".strip()

    response = client.models.generate_content(
        model=settings.vision_model,
        contents=[
            types.Part.from_bytes(data=raw, mime_type=mime_type),
            prompt,
        ],
        config=types.GenerateContentConfig(
            temperature=0.0,
            response_mime_type="application/json",
            response_schema=MedicationOcrResult,
        ),
    )

    if isinstance(response.parsed, MedicationOcrResult):
        return response.parsed

    if response.text:
        return MedicationOcrResult.model_validate_json(response.text)

    raise RuntimeError("medication_ocr_empty_response")
