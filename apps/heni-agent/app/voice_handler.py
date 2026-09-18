from __future__ import annotations

import asyncio
import json

from fastapi import WebSocket, WebSocketDisconnect
from google.genai import types
from starlette.websockets import WebSocketState

from .config import settings
from .google_client import create_google_client
from .language import detect_likely_locale, detect_requested_locale
from .runtime_context import build_runtime_system_prompt, fetch_runtime_context
from .security import origin_allowed, verify_voice_token
from .session_store import get_or_create_session, touch_session
from .tools.declarations import TOOL_DECLARATIONS
from .tools.execute import execute_tool

_client = create_google_client()


def _live_config(system_prompt: str) -> dict:
    blocking_tools = [{**tool, "behavior": "BLOCKING"} for tool in TOOL_DECLARATIONS]
    return {
        "response_modalities": ["AUDIO"],
        "system_instruction": system_prompt,
        "tools": [{"function_declarations": blocking_tools}],
        "input_audio_transcription": {},
        "output_audio_transcription": {},
        "speech_config": {
            "voice_config": {
                "prebuilt_voice_config": {"voice_name": settings.voice_name}
            }
        },
    }


def _opening_turn(locale: str) -> types.Content:
    if locale == "fr":
        text = (
            "Commence maintenant l'appel. Salue brièvement le patient en français, "
            "présente-toi comme Heni et demande comment tu peux l'aider. "
            "Parle naturellement, sans mentionner ce message."
        )
    elif locale == "en":
        text = (
            "Start the live call now. Briefly greet the patient in English, "
            "introduce yourself as Heni and ask how you can help. "
            "Sound natural and do not mention this instruction."
        )
    else:
        text = (
            "ابدأ المكالمة توّا. سلّم على المريض بتونسي طبيعي، عرّف روحك هاني "
            "واسألو شنوة تنجم تعاونُه فيه. خليك مختصر وما تذكرش التعليمة هاذي."
        )
    return types.Content(role="user", parts=[types.Part(text=text)])


async def handle_voice_connection(ws: WebSocket) -> None:
    origin = ws.headers.get("origin")
    if not origin_allowed(origin):
        await ws.close(code=4403, reason="origin_not_allowed")
        return

    token = ws.query_params.get("token", "")
    claims = verify_voice_token(token)
    if not claims:
        await ws.close(code=4401, reason="invalid_or_expired_token")
        return

    patient_id = str(claims.get("patientId") or "").strip()
    if not patient_id:
        await ws.close(code=4401, reason="patient_missing")
        return

    locale = str(claims.get("locale") or "ar")
    session = get_or_create_session(
        str(claims.get("sid") or "") or None,
        patient_id=patient_id,
        locale=locale,
        source="voice",
    )

    await ws.accept()
    await ws.send_json({"type": "session", "sessionId": session.id})

    try:
        runtime_context = await fetch_runtime_context(session)
        system_prompt = build_runtime_system_prompt(runtime_context)
        async with _client.aio.live.connect(model=settings.live_model, config=_live_config(system_prompt)) as live:
            sender = asyncio.create_task(_pump_client_to_live(ws, live, session))
            receiver = asyncio.create_task(_pump_live_to_client(ws, live, session))

            # Make the experience feel like a real call: Heni greets first.
            await live.send_client_content(turns=_opening_turn(locale), turn_complete=True)

            done, pending = await asyncio.wait(
                {sender, receiver}, return_when=asyncio.FIRST_COMPLETED
            )
            for task in pending:
                task.cancel()
            for task in done:
                exc = task.exception()
                if exc:
                    raise exc
    except WebSocketDisconnect:
        return
    except Exception as exc:
        if ws.client_state == WebSocketState.CONNECTED:
            try:
                await ws.send_json({"type": "error", "message": "voice_session_unavailable"})
            except Exception:
                pass
        print("voice session failed", type(exc).__name__, str(exc)[:240])


async def _pump_client_to_live(ws: WebSocket, live, session) -> None:
    while True:
        message = await ws.receive()
        if message.get("type") == "websocket.disconnect":
            return
        if message.get("bytes") is not None:
            await live.send_realtime_input(
                audio=types.Blob(data=message["bytes"], mime_type="audio/pcm;rate=16000")
            )
            continue
        if message.get("text") is None:
            continue
        touch_session(session.id)
        try:
            control = json.loads(message["text"])
        except ValueError:
            continue
        kind = control.get("type")
        if kind == "audio_stream_end":
            await live.send_realtime_input(audio_stream_end=True)
        elif kind == "debug_text" and settings.debug_enabled:
            text = str(control.get("text") or "").strip()
            if text:
                session.last_user_text = text
                await live.send_realtime_input(text=text)


async def _pump_live_to_client(ws: WebSocket, live, session) -> None:
    while True:
        async for chunk in live.receive():
            touch_session(session.id)

            if chunk.data:
                await ws.send_bytes(chunk.data)

            content = chunk.server_content
            if content:
                if getattr(content, "interrupted", False):
                    await ws.send_json({"type": "interrupted"})
                if content.input_transcription and content.input_transcription.text:
                    text = content.input_transcription.text.strip()
                    if text:
                        # Deliver the transcript first. Language detection must never be
                        # able to tear down an otherwise healthy realtime call.
                        session.last_user_text = text
                        await ws.send_json({"type": "transcript", "role": "user", "text": text})
                        try:
                            detected_locale = detect_requested_locale(text) or detect_likely_locale(text)
                            if detected_locale and detected_locale != session.locale:
                                session.locale = detected_locale
                                await ws.send_json({"type": "locale", "locale": detected_locale})
                        except Exception as locale_error:
                            print("voice locale detection failed", type(locale_error).__name__)
                if content.output_transcription and content.output_transcription.text:
                    await ws.send_json({
                        "type": "transcript",
                        "role": "model",
                        "text": content.output_transcription.text.strip(),
                    })
                if content.turn_complete:
                    await ws.send_json({"type": "turn_complete"})

            if chunk.tool_call and chunk.tool_call.function_calls:
                responses = []
                for call in chunk.tool_call.function_calls:
                    await ws.send_json({"type": "tool_call", "name": call.name, "args": call.args or {}})
                    result = await execute_tool(call.name, call.args or {}, session)
                    responses.append(
                        types.FunctionResponse(
                            id=call.id,
                            name=call.name,
                            response={"result": result},
                        )
                    )
                await live.send_tool_response(function_responses=responses)
