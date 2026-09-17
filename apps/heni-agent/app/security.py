from __future__ import annotations

import base64
import hashlib
import hmac
import json
import time
from typing import Any

from .config import settings


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode((data + padding).encode("ascii"))


def secure_compare(a: str, b: str) -> bool:
    if not a or not b:
        return False
    return hmac.compare_digest(a.encode("utf-8"), b.encode("utf-8"))


def verify_internal_key(value: str | None) -> bool:
    return secure_compare(value or "", settings.shared_secret)


def _sign_payload(payload: dict[str, Any], ttl_seconds: int) -> str:
    now = int(time.time())
    body = dict(payload)
    body.setdefault("iat", now)
    body.setdefault("exp", now + ttl_seconds)
    encoded = _b64url_encode(json.dumps(body, separators=(",", ":"), ensure_ascii=False).encode("utf-8"))
    signature = hmac.new(settings.shared_secret.encode("utf-8"), encoded.encode("ascii"), hashlib.sha256).digest()
    return f"{encoded}.{_b64url_encode(signature)}"


def _verify_payload(token: str) -> dict[str, Any] | None:
    try:
        encoded, supplied_sig = token.split(".", 1)
        expected = hmac.new(settings.shared_secret.encode("utf-8"), encoded.encode("ascii"), hashlib.sha256).digest()
        supplied = _b64url_decode(supplied_sig)
        if not hmac.compare_digest(expected, supplied):
            return None
        payload = json.loads(_b64url_decode(encoded).decode("utf-8"))
        if int(payload.get("exp", 0)) < int(time.time()):
            return None
        return payload
    except Exception:
        return None


def sign_voice_token(payload: dict[str, Any], ttl_seconds: int = 120) -> str:
    return _sign_payload({"kind": "voice", **payload}, ttl_seconds)


def verify_voice_token(token: str) -> dict[str, Any] | None:
    payload = _verify_payload(token)
    if not payload or payload.get("kind") not in {None, "voice"}:
        return None
    return payload


def sign_confirmation_token(pending_action: dict[str, Any], patient_id: str, ttl_seconds: int = 300) -> str:
    return _sign_payload(
        {
            "kind": "confirmation",
            "patientId": patient_id,
            "pending": pending_action,
        },
        ttl_seconds,
    )


def verify_confirmation_token(token: str | None, patient_id: str) -> dict[str, Any] | None:
    if not token:
        return None
    payload = _verify_payload(token)
    if not payload or payload.get("kind") != "confirmation" or payload.get("patientId") != patient_id:
        return None
    pending = payload.get("pending")
    return pending if isinstance(pending, dict) else None


def origin_allowed(origin: str | None) -> bool:
    if not origin:
        return False
    normalized = origin.rstrip("/")
    return normalized in settings.allowed_origins
