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
    """Load current patient and public hospital context from the Hani Maak backend.

    This data is refreshed on every turn/session. It is deliberately not learned
    by the model and is never accepted from browser-provided patient fields.
    """
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
        + "Use it to personalize the conversation and understand the patient's current journey. "
        + "Do not reveal fields the user did not ask for, and never treat it as clinical advice. "
        + "If a field is null or absent, ask or use a tool instead of inventing it.\n"
        + runtime_json
    )
