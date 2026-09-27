from __future__ import annotations

import asyncio
import json

from fastapi import WebSocket, WebSocketDisconnect
from google.genai import types
from starlette.websockets import WebSocketState

from .audio_buffer import PatientAudioBuffer, delete_temp_audio
from .config import settings
from .emotion_client import analyze_patient_audio
from .text_emotion import analyze_transcript_emotion
from .distress import detect_semantic_distress
from .google_client import create_google_client
from .language import detect_requested_locale, is_supported_transcript
from .runtime_context import build_runtime_system_prompt, fetch_runtime_context
from .security import origin_allowed, verify_voice_token
from .session_store import get_or_create_session, touch_session
from .tools.declarations import TOOL_DECLARATIONS
from .tools.execute import execute_tool
from .tools.hani_backend import call_hani_tool

_client = create_google_client()


def _live_config(system_prompt: str, locale: str) -> dict:
    language_codes = {
        "tn": ["ar-TN", "fr-FR", "en-US"],
        "ar": ["ar", "ar-TN", "fr-FR", "en-US"],
        "fr": ["fr-FR", "ar-TN", "en-US"],
        "en": ["en-US", "fr-FR", "ar-TN"],
    }.get(locale, ["ar-TN", "ar", "fr-FR", "en-US"])
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
- The only supported transcript languages are Tunisian Arabic/Derja, Arabic, French, and English. Never reinterpret clear speech as another unrelated language.
- If a transcript is incomplete or unclear, ask one short clarification instead of guessing.
- Keep the current patient/person and symptom/activity topic in working context across turns. Pronouns and short follow-ups refer to the most recently discussed person or event unless the caregiver explicitly changes topic.
- Never jump to a generic capabilities message (appointments, directions, facility help, etc.) when the caregiver is discussing a patient symptom, medication, routine, family member, or recent event. Continue the current care conversation.
- Match the caregiver's natural language mix. Tunisian Latin-script Derja such as "mrayedha chwya", "kamet mn noum mawjouaa", "famma", "tawa", "nheb", and "najjem" is valid Tunisian speech, not an unknown language.
""",
        "tools": [{"function_declarations": blocking_tools}],
        "input_audio_transcription": {
            "language_codes": language_codes,
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
                "mrayedha",
                "chwya",
                "kamet",
                "noum",
                "mawjouaa",
                "famma",
                "tawa",
                "nheb",
                "najjem",
                "wja3",
                "mraydha",
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

    audio_buffer = PatientAudioBuffer()

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
            config=_live_config(system_prompt, session.locale),
        ) as live:
            await ws.send_json({"type": "status", "phase": "listening"})
            sender = asyncio.create_task(
                _pump_client_to_live(ws, live, session, audio_buffer)
            )
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
        if not session.voice_finalized and audio_buffer.byte_length > 0:
            try:
                await _finalize_voice_call(
                    ws,
                    session,
                    audio_buffer,
                    send_ack=False,
                )
            except Exception as finalize_error:
                print(
                    "voice disconnect finalization failed",
                    type(finalize_error).__name__,
                )
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
    finally:
        audio_buffer.close()


async def _run_emotion_analysis(
    session,
    wav_path,
    *,
    audio_duration_ms: int,
    transcript_turns: list[str],
) -> None:
    """Run vocal and Gemini text emotion analysis in parallel.

    The vocal model gets a hard 10-second budget. The Gemini transcript
    classifier starts immediately in parallel and becomes the real result if
    the vocal service is slow/unavailable, so Flutter never waits forever.
    """
    loop = asyncio.get_running_loop()
    started_at = loop.time()
    audio_task = asyncio.create_task(
        analyze_patient_audio(
            conversation_id=session.id,
            wav_path=wav_path,
        )
    )
    text_task = asyncio.create_task(
        analyze_transcript_emotion(
            conversation_id=session.id,
            turns=transcript_turns,
            locale=session.locale,
            audio_duration_ms=audio_duration_ms,
        )
    )

    audio_result: dict | None = None
    text_result: dict | None = None
    result: dict | None = None

    try:
        try:
            audio_result = await asyncio.wait_for(
                asyncio.shield(audio_task),
                timeout=10.0,
            )
        except asyncio.TimeoutError:
            audio_task.cancel()
        except Exception:
            audio_result = None

        if (
            isinstance(audio_result, dict)
            and str(audio_result.get("status") or "") == "completed"
        ):
            result = audio_result
            if not text_task.done():
                text_task.cancel()
        else:
            try:
                remaining = max(0.15, 10.0 - (loop.time() - started_at))
                text_result = await asyncio.wait_for(
                    asyncio.shield(text_task),
                    timeout=remaining,
                )
            except Exception:
                text_result = None

            if (
                isinstance(text_result, dict)
                and str(text_result.get("status") or "") == "completed"
            ):
                result = text_result
            elif isinstance(audio_result, dict):
                result = audio_result
            elif isinstance(text_result, dict):
                result = text_result

        result = result or {
            "status": "failed",
            "failure_code": "EMOTION_ANALYSIS_UNAVAILABLE",
            "failure_message": "audio_and_text_emotion_analysis_failed",
            "model": f"gemini_text_emotion_fallback:{settings.text_model}",
            "analysis_version": "v2-parallel-fallback",
            "audio_duration_ms": audio_duration_ms,
            "analyzed_speech_ms": 0,
            "segments": [],
        }

        await call_hani_tool(
            "complete_voice_emotion_analysis",
            {
                "sessionId": session.id,
                "result": result,
            },
            patient_id=session.patient_id,
            caregiver_id=session.caregiver_id,
            locale=session.locale,
            source=session.source,
        )
        print(
            "voice emotion analysis",
            {
                "conversation_id": session.id,
                "status": result.get("status"),
                "audio_duration_ms": result.get("audio_duration_ms"),
                "analyzed_speech_ms": result.get("analyzed_speech_ms"),
                "segments": len(result.get("segments") or []),
                "processing_ms": result.get("processing_ms"),
                "model": result.get("model"),
                "fallback": str(result.get("model") or "").startswith(
                    "gemini_text_emotion_fallback:"
                ),
            },
        )
    except Exception as exc:
        try:
            await call_hani_tool(
                "complete_voice_emotion_analysis",
                {
                    "sessionId": session.id,
                    "result": {
                        "status": "failed",
                        "failure_code": "EMOTION_ANALYSIS_UNAVAILABLE",
                        "failure_message": type(exc).__name__,
                        "model": f"gemini_text_emotion_fallback:{settings.text_model}",
                        "analysis_version": "v2-parallel-fallback",
                    },
                },
                patient_id=session.patient_id,
                caregiver_id=session.caregiver_id,
                locale=session.locale,
                source=session.source,
            )
        except Exception:
            pass
        print("voice emotion analysis failed", type(exc).__name__)
    finally:
        for task in (audio_task, text_task):
            if not task.done():
                task.cancel()
        await asyncio.gather(audio_task, text_task, return_exceptions=True)
        delete_temp_audio(wav_path)


async def _finalize_voice_call(
    ws: WebSocket,
    session,
    audio_buffer: PatientAudioBuffer,
    *,
    send_ack: bool = True,
) -> None:
    if session.voice_finalized:
        if send_ack and ws.client_state == WebSocketState.CONNECTED:
            await ws.send_json(
                {
                    "type": "call_ended",
                    "sessionId": session.id,
                    "analysisStatus": "processing",
                }
            )
        return
    session.voice_finalized = True
    analysis_enabled = settings.emotion_analysis_enabled

    await call_hani_tool(
        "finalize_hani_voice_call",
        {
            "sessionId": session.id,
            "audioDurationMs": round(audio_buffer.duration_seconds() * 1000),
            "emotionEnabled": analysis_enabled,
        },
        patient_id=session.patient_id,
        caregiver_id=session.caregiver_id,
        locale=session.locale,
        source=session.source,
    )

    analysis_status = "not_started"
    if analysis_enabled and audio_buffer.byte_length > 0:
        wav_path = audio_buffer.finalize_wav_file()
        audio_duration_ms = round(audio_buffer.duration_seconds() * 1000)
        transcript_turns = list(session.voice_user_transcripts)
        asyncio.create_task(
            _run_emotion_analysis(
                session,
                wav_path,
                audio_duration_ms=audio_duration_ms,
                transcript_turns=transcript_turns,
            )
        )
        analysis_status = "processing"

    if send_ack and ws.client_state == WebSocketState.CONNECTED:
        await ws.send_json(
            {
                "type": "call_ended",
                "sessionId": session.id,
                "analysisStatus": analysis_status,
            }
        )


async def _pump_client_to_live(
    ws: WebSocket,
    live,
    session,
    audio_buffer: PatientAudioBuffer,
) -> None:
    while True:
        message = await ws.receive()

        if message.get("type") == "websocket.disconnect":
            return

        if message.get("bytes") is not None:
            patient_chunk = message["bytes"]
            audio_buffer.append(patient_chunk)
            await live.send_realtime_input(
                audio=types.Blob(
                    data=patient_chunk,
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

        if control_type == "call_end":
            await live.send_realtime_input(audio_stream_end=True)
            await _finalize_voice_call(ws, session, audio_buffer)
            return

        # audio_stream_end is reserved for the real call_end path above.
        # Ending the realtime input stream between normal user turns can make
        # Gemini stop accepting microphone audio after the first response.
        if control_type == "audio_stream_end":
            continue

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
                forwarded_audio = False
                if model_turn and getattr(model_turn, "parts", None):
                    for part in model_turn.parts:
                        inline_data = getattr(part, "inline_data", None)
                        audio_data = (
                            getattr(inline_data, "data", None)
                            if inline_data is not None
                            else None
                        )
                        if audio_data:
                            forwarded_audio = True
                            await ws.send_bytes(audio_data)

                # Gemini Live SDK versions do not always expose generated audio
                # through model_turn.parts. Some surface the same PCM payload on
                # chunk.data. Use it only as a fallback so we never duplicate
                # audio, but also never leave the Flutter client with transcript
                # only and no audible Hani response.
                if not forwarded_audio:
                    fallback_audio = getattr(chunk, "data", None)
                    if fallback_audio:
                        await ws.send_bytes(fallback_audio)
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
                if interim_text and is_supported_transcript(interim_text):
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
                if input_text and is_supported_transcript(input_text):
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
                if output_text and is_supported_transcript(output_text):
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

                    if user_final:
                        if (
                            not session.voice_user_transcripts
                            or session.voice_user_transcripts[-1] != user_final
                        ):
                            session.voice_user_transcripts.append(user_final)
                            if len(session.voice_user_transcripts) > 24:
                                session.voice_user_transcripts = (
                                    session.voice_user_transcripts[-24:]
                                )

                    asyncio.create_task(
                        _persist_voice_turn(
                            session,
                            user_text=user_final,
                            hani_text=model_final,
                        )
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
