from __future__ import annotations

import json
import re
import uuid
from typing import Any

WRITE_TOOLS = {
    "create_appointment",
    "reschedule_appointment",
    "cancel_appointment",
    "share_incident",
    "request_care_task",
    "create_professional_contact_request",
    "create_caregiver_appointment",
}

_AFFIRMATIVE_PATTERNS = [
    r"\byes\b",
    r"\bconfirm\b",
    r"\bi confirm\b",
    r"\bokay\b",
    r"\bok\b",
    r"\boui\b",
    r"\bje confirme\b",
    r"\bd'accord\b",
    r"\bconfirme\b",
    r"نأكد",
    r"نعم",
    r"اي\b",
    r"إي\b",
    r"موافق",
]


def is_explicit_confirmation(text: str) -> bool:
    value = (text or "").strip().lower()
    return any(re.search(pattern, value, flags=re.IGNORECASE) for pattern in _AFFIRMATIVE_PATTERNS)


def _action_args(args: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in args.items() if key != "idempotencyKey"}


def normalize_action(name: str, args: dict[str, Any]) -> str:
    return json.dumps({"name": name, "args": _action_args(args)}, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def guard_write_action(name: str, args: dict[str, Any], session) -> tuple[bool, dict[str, Any] | None]:
    if name not in WRITE_TOOLS:
        return True, None

    normalized = normalize_action(name, args)
    pending = session.pending_action
    if not pending or pending.get("normalized") != normalized:
        session.pending_action = {
            "name": name,
            "args": _action_args(args),
            "normalized": normalized,
            "idempotencyKey": f"heni-{uuid.uuid4()}",
        }
        return False, {
            "success": False,
            "requiresConfirmation": True,
            "action": name,
            "details": _action_args(args),
            "message": "Ask the user to explicitly confirm these exact details before retrying the same action.",
        }

    if not is_explicit_confirmation(session.last_user_text):
        return False, {
            "success": False,
            "requiresConfirmation": True,
            "action": name,
            "details": pending.get("args", _action_args(args)),
            "message": "The most recent user turn is not an explicit confirmation. Ask for confirmation again.",
        }

    if pending.get("idempotencyKey"):
        args["idempotencyKey"] = pending["idempotencyKey"]
    session.pending_action = None
    return True, None
