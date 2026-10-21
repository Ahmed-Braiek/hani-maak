#!/usr/bin/env python3
"""Authenticated, synthetic-only production smoke test for Hani Maak.

This runner never prints credentials, Supabase access tokens, voice tokens,
response bodies, or WebSocket URLs that contain signed tokens.
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler


WEB_URL = "https://hani-maak.vercel.app"
AGENT_URL = "https://hani-maak-heni-agent.vercel.app"
CAREGIVER_ID = "10000000-0000-0000-0000-000000000001"
PATIENT_ID = "30000000-0000-0000-0000-000000000001"
UNRELATED_PATIENT_ID = "00000000-0000-4000-8000-000000000000"
MAX_RESPONSE_BYTES = 262_144


class SmokeFailure(Exception):
    """Expected smoke-test failure with a deliberately non-sensitive message."""


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None


# Never forward credentials to redirect destinations.
HTTP = build_opener(NoRedirect)


def request(
    label: str,
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    body: dict[str, Any] | None = None,
    expected: tuple[int, ...] = (200,),
    timeout: int = 25,
) -> tuple[int, bytes]:
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = Request(url, data=data, headers=headers or {}, method=method)
    try:
        with HTTP.open(req, timeout=timeout) as response:
            status = response.status
            raw = response.read(MAX_RESPONSE_BYTES + 1)
    except HTTPError as error:
        status, raw = error.code, b""
    except (URLError, TimeoutError, OSError):
        raise SmokeFailure(f"{label}: network request failed") from None

    if status not in expected:
        raise SmokeFailure(f"{label}: HTTP {status}, expected {expected}")
    if len(raw) > MAX_RESPONSE_BYTES:
        raise SmokeFailure(f"{label}: response exceeds safe size limit")
    return status, raw


def json_request(label: str, url: str, **kwargs: Any) -> tuple[int, dict[str, Any]]:
    status, raw = request(label, url, **kwargs)
    if status != 200:
        return status, {}
    try:
        payload = json.loads(raw)
        if not isinstance(payload, dict):
            raise ValueError("JSON object expected")
        return status, payload
    except (ValueError, UnicodeDecodeError):
        raise SmokeFailure(f"{label}: invalid JSON object") from None


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SmokeFailure(f"Missing CI credential/configuration: {name}")
    return value


def verify_hosts() -> None:
    _, body = request("Flutter web host", f"{WEB_URL}/flutter/index.html")
    if b'<base href="/flutter/">' not in body:
        raise SmokeFailure("Flutter web host: wrong base href")
    print("PASS: Flutter web host")

    _, status = json_request("Hani agent health", f"{AGENT_URL}/health")
    if status.get("status") != "ok" or status.get("service") != "heni-agent":
        raise SmokeFailure("Hani agent health: unexpected service status")
    print("PASS: Hani agent health")


def authenticate(supabase_url: str, publishable_key: str, email: str, password: str) -> str:
    _, auth = json_request(
        "Supabase demo login",
        f"{supabase_url}/auth/v1/token?grant_type=password",
        method="POST",
        headers={"apikey": publishable_key, "content-type": "application/json"},
        body={"email": email, "password": password},
    )
    token = auth.get("access_token")
    if not isinstance(token, str) or not token or auth.get("token_type", "").lower() != "bearer":
        raise SmokeFailure("Supabase demo login: no bearer access token returned")

    _, current_user = json_request(
        "Supabase token verification",
        f"{supabase_url}/auth/v1/user",
        headers={"apikey": publishable_key, "Authorization": f"Bearer {token}"},
    )
    if not current_user.get("id"):
        raise SmokeFailure("Supabase token verification: no authenticated user ID")
    print("PASS: authenticated synthetic Supabase session")
    return token


def voice_payload(patient_id: str = PATIENT_ID) -> dict[str, Any]:
    return {"locale": "en", "caregiverId": CAREGIVER_ID, "patientId": patient_id}


def chat_payload(patient_id: str = PATIENT_ID) -> dict[str, Any]:
    return {
        "message": "Hello Hani. Give me one short supportive sentence.",
        "locale": "en",
        "role": "patient",
        "caregiverId": CAREGIVER_ID,
        "patientId": patient_id,
        "history": [],
    }


def check_access_control(token: str) -> None:
    endpoints = (
        ("voice token", f"{WEB_URL}/api/v1/heni/voice-token", voice_payload()),
        ("caregiver chat", f"{WEB_URL}/api/v1/heni/chat", chat_payload()),
    )
    for label, url, payload in endpoints:
        for auth_header, kind in ((None, "missing"), ("Bearer invalid-smoke-session", "invalid")):
            headers = {"content-type": "application/json"}
            if auth_header:
                headers["Authorization"] = auth_header
            request(
                f"{label} ({kind} authentication)", url,
                method="POST", headers=headers, body=payload, expected=(401,),
            )

    # An authenticated identity cannot act for an unrelated patient.
    for label, url, payload in (
        ("voice token", endpoints[0][1], voice_payload(UNRELATED_PATIENT_ID)),
        ("caregiver chat", endpoints[1][1], chat_payload(UNRELATED_PATIENT_ID)),
    ):
        request(
            f"{label} (unrelated patient)", url,
            method="POST",
            headers={"content-type": "application/json", "Authorization": f"Bearer {token}"},
            body=payload,
            expected=(401, 403),
        )
    print("PASS: missing/invalid credentials and unrelated patient access denied")


def authenticated_voice_token(token: str) -> tuple[str, str]:
    _, body = json_request(
        "authenticated voice token",
        f"{WEB_URL}/api/v1/heni/voice-token",
        method="POST",
        headers={"content-type": "application/json", "Authorization": f"Bearer {token}"},
        body=voice_payload(),
    )
    voice_token, ws_url = body.get("token"), body.get("wsUrl")
    if not isinstance(voice_token, str) or not voice_token:
        raise SmokeFailure("authenticated voice token: missing signed token")
    if not isinstance(ws_url, str) or urlsplit(ws_url).scheme != "wss":
        raise SmokeFailure("authenticated voice token: secure WebSocket URL missing")
    if urlsplit(ws_url).username or urlsplit(ws_url).password:
        raise SmokeFailure("authenticated voice token: unexpected WebSocket URL credentials")
    print("PASS: authenticated voice token issued")
    return voice_token, ws_url


async def verify_voice_websocket(voice_token: str, ws_url: str) -> None:
    try:
        import websockets
        separator = "&" if "?" in ws_url else "?"
        signed_url = f"{ws_url}{separator}token={quote(voice_token, safe='')}"
        async with websockets.connect(
            signed_url,
            origin=WEB_URL,
            open_timeout=15,
            close_timeout=5,
        ) as ws:
            saw_session = False
            saw_listening = False
            for _ in range(5):
                raw = await asyncio.wait_for(ws.recv(), timeout=20)
                if not isinstance(raw, str):
                    continue
                try:
                    event = json.loads(raw)
                except ValueError:
                    continue
                if event.get("type") == "session":
                    saw_session = True
                if event.get("type") == "status" and event.get("phase") == "listening":
                    saw_listening = True
                    break
            if not (saw_session and saw_listening):
                raise SmokeFailure("live voice WebSocket: expected session/listening events absent")
    except SmokeFailure:
        raise
    except Exception:
        # A WebSocket exception may embed the signed URL; never print it.
        raise SmokeFailure("live voice WebSocket: handshake or session failed") from None
    print("PASS: live voice WebSocket handshake")


def verify_chat(token: str) -> None:
    _, payload = json_request(
        "authenticated caregiver chat",
        f"{WEB_URL}/api/v1/heni/chat",
        method="POST",
        headers={"content-type": "application/json", "Authorization": f"Bearer {token}"},
        body=chat_payload(), timeout=55,
    )
    if not payload.get("message") or not payload.get("sessionId"):
        raise SmokeFailure("authenticated caregiver chat: missing response or session ID")
    if payload.get("locale") not in ("tn", "ar", "fr", "en"):
        raise SmokeFailure("authenticated caregiver chat: unexpected locale")
    print("PASS: authenticated Hani caregiver chat")


def run() -> None:
    # Fail early if CI credentials are absent; never attempt fallback accounts.
    email = require_env("HANI_SMOKE_DEMO_EMAIL")
    password = require_env("HANI_SMOKE_DEMO_PASSWORD")
    supabase_url = require_env("HANI_SMOKE_SUPABASE_URL").rstrip("/")
    publishable_key = require_env("HANI_SMOKE_SUPABASE_PUBLISHABLE_KEY")
    if urlsplit(supabase_url).scheme != "https":
        raise SmokeFailure("Supabase URL must use HTTPS")

    verify_hosts()
    token = authenticate(supabase_url, publishable_key, email, password)
    check_access_control(token)
    voice_token, ws_url = authenticated_voice_token(token)
    asyncio.run(verify_voice_websocket(voice_token, ws_url))
    verify_chat(token)
    print("PASS: complete authenticated production smoke test")


if __name__ == "__main__":
    try:
        run()
    except SmokeFailure as error:
        # Errors are intentionally sanitized; no secrets, token or raw response data.
        print(f"::error::{error}", file=sys.stderr)
        sys.exit(1)
    except Exception:
        print("::error::Unexpected smoke test failure (details suppressed)", file=sys.stderr)
        sys.exit(1)
