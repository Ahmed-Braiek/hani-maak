from __future__ import annotations

from typing import Any

import httpx

from ..config import settings


async def call_hani_tool(
    name: str,
    args: dict[str, Any],
    *,
    patient_id: str,
    locale: str,
    source: str,
    caregiver_id: str | None = None,
) -> dict[str, Any]:
    """Call Hani's deterministic backend without letting transport failures kill the conversation."""
    endpoint = "caregiver-agent/tools" if caregiver_id else "agent/tools"
    url = f"{settings.backend_base_url}/api/v1/{endpoint}"
    headers = {
        "content-type": "application/json",
        "x-heni-agent-key": settings.shared_secret,
    }
    payload = {
        "tool": name,
        "args": args,
        "context": {
            "patientId": patient_id,
            "caregiverId": caregiver_id,
            "locale": locale,
            "source": source,
        },
    }
    timeout = httpx.Timeout(settings.backend_timeout_seconds)
    try:
        async with httpx.AsyncClient(timeout=timeout, follow_redirects=True) as client:
            response = await client.post(url, headers=headers, json=payload)
    except httpx.TimeoutException:
        return {"success": False, "error": "hani_backend_timeout", "retryable": True}
    except httpx.RequestError:
        return {"success": False, "error": "hani_backend_unreachable", "retryable": True}

    try:
        body = response.json()
    except ValueError:
        body = {"error": "invalid_backend_response"}

    if not response.is_success:
        return {
            "success": False,
            "error": str(body.get("error") or body.get("detail") or "hani_backend_error")[:160],
            "status": response.status_code,
            "retryable": response.status_code >= 500,
        }
    return body
