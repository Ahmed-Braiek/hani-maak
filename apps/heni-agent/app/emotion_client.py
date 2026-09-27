from __future__ import annotations

from pathlib import Path
from typing import Any

import httpx

from .config import settings


async def analyze_patient_audio(
    *,
    conversation_id: str,
    wav_path: Path,
) -> dict[str, Any]:
    if not settings.emotion_analysis_enabled:
        return {"status": "disabled"}
    if not settings.emotion_service_url or not settings.emotion_service_secret:
        return {
            "status": "failed",
            "failure_code": "MODEL_UNAVAILABLE",
            "failure_message": "emotion_service_not_configured",
        }

    url = f"{settings.emotion_service_url}/v1/emotions/analyze"
    headers = {
        "authorization": f"Bearer {settings.emotion_service_secret}",
    }
    timeout = httpx.Timeout(settings.emotion_request_timeout_seconds)

    try:
        async with httpx.AsyncClient(timeout=timeout, follow_redirects=True) as client:
            with wav_path.open("rb") as audio:
                response = await client.post(
                    url,
                    headers=headers,
                    data={"conversation_id": conversation_id},
                    files={"audio": ("patient.wav", audio, "audio/wav")},
                )
    except httpx.TimeoutException:
        return {
            "status": "failed",
            "failure_code": "SERVICE_TIMEOUT",
            "failure_message": "emotion_service_timeout",
        }
    except httpx.RequestError:
        return {
            "status": "failed",
            "failure_code": "MODEL_UNAVAILABLE",
            "failure_message": "emotion_service_unreachable",
        }

    try:
        body = response.json()
    except ValueError:
        body = {}

    if not response.is_success:
        return {
            "status": "failed",
            "failure_code": "MODEL_INFERENCE_FAILED",
            "failure_message": str(body.get("detail") or f"emotion_http_{response.status_code}")[:240],
        }

    if not isinstance(body, dict):
        return {
            "status": "failed",
            "failure_code": "RESULT_INVALID",
            "failure_message": "invalid_emotion_response",
        }
    return body
