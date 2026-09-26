from __future__ import annotations

import asyncio
import json

from fastapi import WebSocket, WebSocketDisconnect
from google.genai import types
from starlette.websockets import WebSocketState

from .config import settings
from .distress import detect_semantic_distress
from .google_client import create_google_client
from .language import detect_requested_locale
from .runtime_context import build_runtime_system_prompt, fetch_runtime_context
from .security import origin_allowed, verify_voice_token
from .session_store import get_or_create_session, touch_session
from .tools.declarations import TOOL_DECLARATIONS
from .tools.execute import execute_tool
from .tools.hani_backend import call_hani_tool

_client = create_google_client()


def _live_config(system_prompt: str) -> dict:
    blocking_tools = [{**tool, "behavior": "BLOCKING"} for tool in TOOL_DECLARATIONS]
    return {
        "response_modalities": ["AUDIO"],
        "system_instruction": system_prompt
        + """
        
LIVE CALL RULES
- This is a continuous full-duplex voice call, not push-to-talk.
- React to the latest completed user speech turn. Never replay or restate an older answer unless the user asks.
- If incoming speech appears to be an acoustic echo of your own immediately previous wording, do not answer the echo; wait for real new user speech.
- Keep most spoken answers to 1-2 short sentences, then pause and listen.
- The caregiver may interrupt at any time. Stop immediately and listen.
- If the interruption is only a floor-taking phrase such as "wait", "hold on", "estanna", "stop" or "listen", hand them the floor naturally and briefly in their language (for example: "أكيد، تفضّل، نسمعك") and then wait. If they immediately continue with real content, do not add a filler phrase; just listen and respond to what they said.
- Never resume the sentence that was interrupted unless the caregiver asks you to continue.
- Tunisian Derja may mix naturally with French, Arabic and English. Do not switch the whole conversation language merely because one borrowed word or phrase appears.
- If a transcript is incomplete or unclear, ask one short clarification instead of guessing.
""",
        "tools": [{"function_declarations": blocking_tools}],
        "input_audio_transcription": {
            "language_codes": [],
            "mode": "VERBATIM",
            "custom_vocabulary": [
                "Hani",
                "هاني",
                "Hani Maak",
                "هاني معاك",
                "Fatma",
                "Mariem",
                "Sami",
                "Alzheimer",
                "Alzheimer's",
                "Tunisia",
            ],
        },
        "output_audio_transcription": {},
        "realtime_input_config": {
            "automatic_activity_detection": {
                "disabled": False,
                "start_of_speech_sensitivity": "START_SENSITIVITY_LOW",
                "end_of_speech_sensitivity": "END_SENSITIVITY_LOW",
                "prefix_padding_ms": 220,
                "silence_duration_ms": 850,
            },
            "activity_handling": "START_OF_ACTIVITY_INTERRUPTS",
            "turn_coverage": "TURN_INCLUDES_ONLY_ACTIVITY",
        },
        "speech_config": {
            "voice_config": {
                "prebuilt_voice_config": {"voice_name": settings.voice_name}
            }
        },
        "max_output_tokens": 1024,
    }


def _merge_transcript(previous: str, incoming: str) -> str:
    previous = previous.strip()
    incoming = incoming.strip()
    if not incoming:
        return previous
    if not previous:
        return incoming
    if incoming == previous:
        return previous
    if incoming.startswith(previous):
        return incoming
    if previous.startswith(incoming):
        return previous
    if previous.endswith(incoming):
        return previous
    return f"{previous} {incoming}".strip()


async def _persist_voice_turn(
    session,
    *,
    user_text: str,
    hani_text: str,
) -> None:
    if not session.caregiver_id or (not user_text and not hani_text):
        return
    try:
        await call_hani_tool(
            "record_hani_turn",
            {
                "sessionId": session.id,
                "channel": "voice",
                "locale": session.locale,
                "purpose": "general",
                "userText": user_text,
                "haniText": hani_text,
            },
            patient_id=session.patient_id,
            caregiver_id=session.caregiver_id,
            locale=session.locale,
            source=session.source,
        )
    except Exception as persistence_error:
        print(
            "Hani voice persistence failed",
            type(persistence_error).__name__,
        )


async def handle_voice_connection(ws: WebSocket) -> None:
    origin = ws.headers.get("origin")
    if origin and not origin_allowed(origin):
        await ws.close(code=4403, reason="origin_not_allowed")
        return

    claims = verify_voice_token(ws.query_params.get("token", ""))
    if not claims:
        await ws.close(code=4401, reason="invalid_or_expired_token")
        return

    patient_id = str(claims.get("patientId") or "").strip()
    if not patient_id:
        await ws.close(code=4401, reason="patient_missing")
        return

    locale = str(claims.get("locale") or "ar")
    caregiver_id = str(claims.get("caregiverId") or "").strip() or None
    session = get_or_create_session(
        str(claims.get("sid") or "") or None,
        patient_id=patient_id,
        caregiver_id=caregiver_id,
        locale=locale,
        source="voice",
    )

    await ws.accept()
    await ws.send_json(
        {
            "type": "session",
            "sessionId": session.id,
            "locale": session.locale,
            "continuous": True,
        }
    )

    try:
        runtime_context = await fetch_runtime_context(session)
        system_prompt = build_runtime_system_prompt(runtime_context)

        async with _client.aio.live.connect(
            model=settings.live_model,
            config=_live_config(system_prompt),
        ) as live:
            await ws.send_json({"type": "status", "phase": "listening"})
            sender = asyncio.create_task(_pump_client_to_live(ws, live, session))
            receiver = asyncio.create_task(_pump_live_to_client(ws, live, session))

            done, pending = await asyncio.wait(
                {sender, receiver},
                return_when=asyncio.FIRST_COMPLETED,
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
                await ws.send_json(
                    {
                        "type": "error",
                        "message": "voice_session_unavailable",
                        "detail": str(exc)[:180] if settings.debug_enabled else None,
                    }
                )
            except Exception:
                pass
        print("voice session failed", type(exc).__name__, str(exc)[:300])


async def _pump_client_to_live(ws: WebSocket, live, session) -> None:
    while True:
        message = await ws.receive()

        if message.get("type") == "websocket.disconnect":
            return

        if message.get("bytes") is not None:
            await live.send_realtime_input(
                audio=types.Blob(
                    data=message["bytes"],
                    mime_type="audio/pcm;rate=16000",
                )
            )
            continue

        if message.get("text") is None:
            continue

        touch_session(session.id)

        try:
            control = json.loads(message["text"])
        except ValueError:
            continue

        control_type = control.get("type")

        if control_type == "audio_stream_end":
            await live.send_realtime_input(audio_stream_end=True)

        elif control_type == "debug_text" and settings.debug_enabled:
            text = str(control.get("text") or "").strip()
            if text:
                session.last_user_text = text
                await live.send_realtime_input(text=text)


async def _pump_live_to_client(ws: WebSocket, live, session) -> None:
    user_turn_id = 1
    model_turn_id = 1
    user_final = ""
    model_final = ""
    interruption_count = 0
    interaction_signal_recorded = False

    while True:
        async for chunk in live.receive():
            touch_session(session.id)

            content = chunk.server_content
            if content:
                # Forward every audio part in the model turn. A Live API event
                # may contain multiple parts; relying only on chunk.data can
                # drop audio and make speech sound abruptly truncated.
                model_turn = getattr(content, "model_turn", None)
                if model_turn and getattr(model_turn, "parts", None):
                    for part in model_turn.parts:
                        inline_data = getattr(part, "inline_data", None)
                        audio_data = (
                            getattr(inline_data, "data", None)
                            if inline_data is not None
                            else None
                        )
                        if audio_data:
                            await ws.send_bytes(audio_data)
                if getattr(content, "interrupted", False):
                    model_final = ""
                    interruption_count += 1
                    if (
                        interruption_count >= 3
                        and not interaction_signal_recorded
                        and session.caregiver_id
                    ):
                        interaction_signal_recorded = True
                        try:
                            await execute_tool(
                                "record_support_signal",
                                {
                                    "signalType": "voice_interaction_load",
                                    "severity": "low",
                                    "confidence": 0.35,
                                    "evidence": {
                                        "source": "repeated_voice_interruptions",
                                        "count": interruption_count,
                                    },
                                    "experimental": True,
                                },
                                session,
                            )
                        except Exception as interaction_error:
                            print(
                                "voice interaction signal failed",
                                type(interaction_error).__name__,
                            )
                    await ws.send_json(
                        {
                            "type": "interrupted",
                            "turnId": model_turn_id,
                        }
                    )

                interim = getattr(content, "interim_input_transcription", None)
                interim_text = (
                    str(getattr(interim, "text", "") or "").strip()
                    if interim
                    else ""
                )
                if interim_text:
                    await ws.send_json(
                        {
                            "type": "transcript_partial",
                            "role": "user",
                            "turnId": user_turn_id,
                            "text": interim_text,
                        }
                    )
                    await ws.send_json({"type": "status", "phase": "listening"})

                input_transcription = getattr(content, "input_transcription", None)
                input_text = (
                    str(getattr(input_transcription, "text", "") or "").strip()
                    if input_transcription
                    else ""
                )
                if input_text:
                    user_final = _merge_transcript(user_final, input_text)
                    session.last_user_text = user_final

                    await ws.send_json(
                        {
                            "type": "transcript_final",
                            "role": "user",
                            "turnId": user_turn_id,
                            "text": user_final,
                        }
                    )
                    await ws.send_json({"type": "status", "phase": "thinking"})

                    if session.caregiver_id:
                        semantic_signal = detect_semantic_distress(user_final)
                        if semantic_signal:
                            try:
                                await execute_tool(
                                    "record_support_signal",
                                    semantic_signal,
                                    session,
                                )
                            except Exception as signal_error:
                                print(
                                    "voice semantic support signal failed",
                                    type(signal_error).__name__,
                                )

                    try:
                        requested_locale = detect_requested_locale(user_final)
                        if requested_locale and requested_locale != session.locale:
                            session.locale = requested_locale
                            await ws.send_json(
                                {
                                    "type": "locale",
                                    "locale": requested_locale,
                                }
                            )
                    except Exception as locale_error:
                        print(
                            "voice locale request detection failed",
                            type(locale_error).__name__,
                        )

                output_transcription = getattr(content, "output_transcription", None)
                output_text = (
                    str(getattr(output_transcription, "text", "") or "").strip()
                    if output_transcription
                    else ""
                )
                if output_text:
                    model_final = _merge_transcript(model_final, output_text)
                    await ws.send_json(
                        {
                            "type": "transcript_partial",
                            "role": "model",
                            "turnId": model_turn_id,
                            "text": model_final,
                        }
                    )

                if getattr(content, "waiting_for_input", False):
                    await ws.send_json({"type": "status", "phase": "listening"})

                generation_complete = bool(
                    getattr(content, "generation_complete", False)
                )
                if generation_complete:
                    await ws.send_json(
                        {
                            "type": "generation_complete",
                            "modelTurnId": model_turn_id,
                        }
                    )

                if getattr(content, "turn_complete", False):
                    if model_final:
                        await ws.send_json(
                            {
                                "type": "transcript_final",
                                "role": "model",
                                "turnId": model_turn_id,
                                "text": model_final,
                            }
                        )

                    turn_reason = getattr(content, "turn_complete_reason", None)
                    interaction_status = getattr(content, "interaction_status", None)

                    await ws.send_json(
                        {
                            "type": "turn_complete",
                            "userTurnId": user_turn_id,
                            "modelTurnId": model_turn_id,
                            "generationComplete": generation_complete,
                            "reason": (
                                str(turn_reason)
                                if turn_reason is not None
                                else None
                            ),
                            "interactionStatus": (
                                str(interaction_status)
                                if interaction_status is not None
                                else None
                            ),
                        }
                    )

                    if settings.debug_enabled:
                        print(
                            "voice turn complete",
                            {
                                "turn": model_turn_id,
                                "generation_complete": generation_complete,
                                "reason": (
                                    str(turn_reason)
                                    if turn_reason is not None
                                    else None
                                ),
                                "interaction_status": (
                                    str(interaction_status)
                                    if interaction_status is not None
                                    else None
                                ),
                            },
                        )

                    await _persist_voice_turn(
                        session,
                        user_text=user_final,
                        hani_text=model_final,
                    )

                    user_turn_id += 1
                    model_turn_id += 1
                    user_final = ""
                    model_final = ""
                    await ws.send_json({"type": "status", "phase": "listening"})

            if chunk.tool_call and chunk.tool_call.function_calls:
                await ws.send_json({"type": "status", "phase": "thinking"})
                responses = []

                for call in chunk.tool_call.function_calls:
                    await ws.send_json(
                        {
                            "type": "tool_call",
                            "name": call.name,
                            "args": call.args or {},
                        }
                    )

                    result = await execute_tool(
                        call.name,
                        call.args or {},
                        session,
                    )

                    action = (
                        result.get("uiAction")
                        if isinstance(result, dict)
                        else None
                    )

                    if isinstance(action, dict):
                        await ws.send_json(
                            {
                                "type": "ui_action",
                                "action": action,
                            }
                        )

                    responses.append(
                        types.FunctionResponse(
                            id=call.id,
                            name=call.name,
                            response={"result": result},
                        )
                    )

                await live.send_tool_response(function_responses=responses)
