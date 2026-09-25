from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from typing import Any

from .config import settings


@dataclass
class Session:
    id: str
    patient_id: str
    caregiver_id: str | None = None
    locale: str = "ar"
    source: str = "voice"
    last_appointment_id: str | None = None
    chat_history: list[Any] = field(default_factory=list)
    last_active_at: float = field(default_factory=time.time)
    last_user_text: str = ""
    pending_action: dict[str, Any] | None = None


_sessions: dict[str, Session] = {}


def get_or_create_session(
    session_id: str | None,
    *,
    patient_id: str,
    caregiver_id: str | None = None,
    locale: str = "ar",
    source: str = "voice",
) -> Session:
    cleanup_stale_sessions()
    sid = session_id or str(uuid.uuid4())
    session = _sessions.get(sid)
    if session is None:
        session = Session(
            id=sid,
            patient_id=patient_id,
            caregiver_id=caregiver_id,
            locale=locale,
            source=source,
        )
        _sessions[sid] = session
    else:
        session.patient_id = patient_id
        session.caregiver_id = caregiver_id or session.caregiver_id
        session.locale = locale or session.locale
        session.source = source or session.source
    session.last_active_at = time.time()
    return session


def touch_session(session_id: str) -> None:
    session = _sessions.get(session_id)
    if session:
        session.last_active_at = time.time()


def cleanup_stale_sessions() -> None:
    now = time.time()
    stale = [
        sid
        for sid, session in _sessions.items()
        if now - session.last_active_at > settings.session_ttl_seconds
    ]
    for sid in stale:
        del _sessions[sid]
