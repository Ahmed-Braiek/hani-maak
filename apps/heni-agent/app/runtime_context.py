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
    """Load fresh authorized context while keeping caregiver sessions fast."""
    if session.caregiver_id:
        caregiver = await call_hani_tool(
            "get_caregiver_context",
            {},
            patient_id=session.patient_id,
            caregiver_id=session.caregiver_id,
            locale=session.locale,
            source=session.source,
        )
        return {"caregiver": _usable(caregiver)}

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
    return {"patient": _usable(patient), "hospital": _usable(hospital)}


def build_runtime_system_prompt(context: dict[str, Any]) -> str:
    runtime_json = json.dumps(
        context,
        ensure_ascii=False,
        separators=(",", ":"),
        default=str,
    )
    return (
        HENI_SYSTEM_PROMPT
        + "\n\nRUNTIME CONTEXT\n"
        + "The JSON below comes from authenticated/trusted Hani Maak backend tools. "
        + "For caregiver sessions it contains only the authorized caregiver, linked patient, shared care context, "
        + "the caregiver's own private wellbeing/context, approved professional information and recent coordination state. "
        + "Use it actively so the caregiver does not repeat known information. "
        + "Never infer missing clinical facts. Never expose another caregiver's private wellbeing or Hani conversation. "
        + "If a necessary fact is absent, use an approved tool or ask one concise question.\n"
        + runtime_json
    )
