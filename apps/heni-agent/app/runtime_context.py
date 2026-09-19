from __future__ import annotations

import asyncio
import json
from typing import Any

from .heni_prompt import HENI_SYSTEM_PROMPT
from .tools.hani_backend import call_hani_tool


def _usable(result: dict[str, Any]) -> dict[str, Any] | None:
    if result.get("success") is True:
        return result
    return None


async def fetch_runtime_context(session) -> dict[str, Any]:
    """Load fresh authorized patient and public hospital context on every turn/session."""
    patient, hospital = await asyncio.gather(
        call_hani_tool(
            "get_patient_context",
            {},
            patient_id=session.patient_id,
            locale=session.locale,
            source=session.source,
        ),
        call_hani_tool(
            "get_public_hospital_info",
            {},
            patient_id=session.patient_id,
            locale=session.locale,
            source=session.source,
        ),
    )
    return {
        "patient": _usable(patient),
        "hospital": _usable(hospital),
    }


def build_runtime_system_prompt(context: dict[str, Any]) -> str:
    safe_context = {
        "patient": context.get("patient"),
        "hospital": context.get("hospital"),
    }
    runtime_json = json.dumps(
        safe_context,
        ensure_ascii=False,
        separators=(",", ":"),
        default=str,
    )
    return (
        HENI_SYSTEM_PROMPT
        + "\n\nRUNTIME CONTEXT\n"
        + "The JSON below comes from authenticated/trusted Hani Maak backend tools for this session. "
        + "Use it actively so the patient does not have to repeat known information. "
        + "Patient context may include appointment history, upcoming appointment, service details, required documents, "
        + "provider-approved preparation/follow-up, journey steps, reminders, caregiver scopes and waitlist state. "
        + "When asked about what is next, summarize the relevant current step directly. "
        + "Do not expose unrelated personal fields, and never turn administrative context into clinical advice. "
        + "If a field is absent, use a tool or ask instead of inventing it.\n"
        + runtime_json
    )
