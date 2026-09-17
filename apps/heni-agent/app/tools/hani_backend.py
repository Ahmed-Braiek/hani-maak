from __future__ import annotations

from typing import Any

import httpx

from ..config import settings


async def call_hani_tool(name: str, args: dict[str, Any], *, patient_id: str, locale: str, source: str) -> dict[str, Any]:
    url = f"{settings.backend_base_url}/api/v1/agent/tools"
    headers = {
        "content-type": "application/json",
        "x-heni-agent-key": settings.shared_secret,
    }
    payload = {
        "tool": name,
        "args": args,
        "context": {
            "patientId": patient_id,
            "locale": locale,
            "source": source,
        },
    }
    timeout = httpx.Timeout(settings.backend_timeout_seconds)
    async with httpx.AsyncClient(timeout=timeout, follow_redirects=False) as client:
        response = await client.post(url, headers=headers, json=payload)
    try:
        body = response.json()
    except ValueError:
        body = {"error": "invalid_backend_response"}
    if not response.is_success:
        return {
            "success": False,
            "error": body.get("error", "hani_backend_error"),
            "status": response.status_code,
        }
    return body
