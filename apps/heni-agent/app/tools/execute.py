from __future__ import annotations

from typing import Any

from ..confirmation import guard_write_action
from .hani_backend import call_hani_tool


async def execute_tool(name: str, args: dict[str, Any], session) -> dict[str, Any]:
    allowed, rejection = guard_write_action(name, args, session)
    if not allowed:
        return rejection or {"success": False, "requiresConfirmation": True}
    return await call_hani_tool(
        name,
        args,
        patient_id=session.patient_id,
        caregiver_id=session.caregiver_id,
        locale=session.locale,
        source=session.source,
    )
