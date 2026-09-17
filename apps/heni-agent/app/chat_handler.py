from __future__ import annotations

import uuid
from typing import Any

from google.genai import types

from .config import settings
from .google_client import create_google_client
from .heni_prompt import HENI_SYSTEM_PROMPT
from .security import sign_confirmation_token, verify_confirmation_token
from .session_store import get_or_create_session, touch_session
from .tools.declarations import TOOL_DECLARATIONS
from .tools.execute import execute_tool

_client = create_google_client()


def _content_from_history(history: list[dict[str, Any]]) -> list[types.Content]:
    contents: list[types.Content] = []
    for item in history[-12:]:
        role = "model" if item.get("role") in {"assistant", "model", "heni"} else "user"
        text = str(item.get("content") or item.get("text") or "").strip()
        if text:
            contents.append(types.Content(role=role, parts=[types.Part(text=text)]))
    return contents


async def run_chat_turn(
    *,
    message: str,
    patient_id: str,
    locale: str,
    source: str,
    session_id: str | None,
    history: list[dict[str, Any]],
    confirmation_token: str | None = None,
) -> dict[str, Any]:
    session = get_or_create_session(
        session_id or str(uuid.uuid4()),
        patient_id=patient_id,
        locale=locale,
        source=source,
    )
    touch_session(session.id)
    # HTTP requests can land on different Vercel instances. Restore pending write
    # state only from a signed token rather than trusting process memory or the browser.
    session.pending_action = verify_confirmation_token(confirmation_token, patient_id)
    session.last_user_text = message

    contents = _content_from_history(history)
    contents.append(types.Content(role="user", parts=[types.Part(text=message)]))

    config = types.GenerateContentConfig(
        system_instruction=HENI_SYSTEM_PROMPT,
        tools=[types.Tool(function_declarations=TOOL_DECLARATIONS)],
        max_output_tokens=320,
    )

    response = await _client.aio.models.generate_content(
        model=settings.text_model,
        contents=contents,
        config=config,
    )

    tool_events: list[dict[str, Any]] = []
    for _ in range(6):
        calls = response.function_calls or []
        if not calls:
            break

        model_parts = [types.Part(function_call=call) for call in calls]
        contents.append(types.Content(role="model", parts=model_parts))

        response_parts = []
        for call in calls:
            args = dict(call.args or {})
            result = await execute_tool(call.name, args, session)
            tool_events.append({"name": call.name, "args": args, "result": result})
            response_parts.append(
                types.Part(
                    function_response=types.FunctionResponse(
                        id=call.id,
                        name=call.name,
                        response={"result": result},
                    )
                )
            )
        contents.append(types.Content(role="user", parts=response_parts))
        response = await _client.aio.models.generate_content(
            model=settings.text_model,
            contents=contents,
            config=config,
        )

    reply = (response.text or "").strip()
    if not reply:
        reply = "سامحني، ما نجّمتش نكمّل الإجابة توّا. نجم نطلبلك مساعدة من الموظفين."

    pending_token = (
        sign_confirmation_token(session.pending_action, patient_id)
        if session.pending_action
        else None
    )
    return {
        "message": reply,
        "sessionId": session.id,
        "confirmationToken": pending_token,
        "tools": tool_events,
        "tool": tool_events[-1]["name"] if tool_events else None,
        "model": settings.text_model,
    }
