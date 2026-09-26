from __future__ import annotations

import asyncio
import uuid
from typing import Any

from google.genai import types

from .config import settings
from .distress import detect_semantic_distress
from .google_client import create_google_client
from .language import (
    detect_likely_locale,
    detect_requested_locale,
    is_doctor_name_question,
    is_human_help_request,
    is_language_switch_only,
    locale_message,
)
from .runtime_context import build_runtime_system_prompt, fetch_runtime_context
from .security import sign_confirmation_token, verify_confirmation_token
from .session_store import get_or_create_session, touch_session
from .tools.declarations import TOOL_DECLARATIONS
from .tools.execute import execute_tool
from .tools.hani_backend import call_hani_tool

_client = create_google_client()


def _content_from_history(history: list[dict[str, Any]]) -> list[types.Content]:
    contents: list[types.Content] = []
    for item in history[-16:]:
        role = "model" if item.get("role") in {"assistant", "model", "heni"} else "user"
        text = str(item.get("content") or item.get("text") or "").strip()
        if text:
            contents.append(types.Content(role=role, parts=[types.Part(text=text)]))
    return contents


async def _generate(*, contents: list[types.Content], config: types.GenerateContentConfig):
    return await asyncio.wait_for(
        _client.aio.models.generate_content(
            model=settings.text_model,
            contents=contents,
            config=config,
        ),
        timeout=settings.model_timeout_seconds,
    )


def _base_result(message: str, session, *, tool: str | None = None, tools: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    return {
        "message": message,
        "sessionId": session.id,
        "locale": session.locale,
        "confirmationToken": None,
        "tools": tools or [],
        "tool": tool,
        "model": settings.text_model,
    }


async def _persist_chat_turn(
    session,
    *,
    user_text: str,
    hani_text: str,
    purpose: str = "general",
) -> None:
    if not session.caregiver_id:
        return
    try:
        await call_hani_tool(
            "record_hani_turn",
            {
                "sessionId": session.id,
                "channel": "chat",
                "locale": session.locale,
                "purpose": purpose,
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
            "Hani chat persistence failed",
            type(persistence_error).__name__,
        )


async def run_chat_turn(
    *,
    message: str,
    patient_id: str,
    caregiver_id: str | None,
    locale: str,
    source: str,
    session_id: str | None,
    history: list[dict[str, Any]],
    confirmation_token: str | None = None,
) -> dict[str, Any]:
    session = get_or_create_session(
        session_id or str(uuid.uuid4()),
        patient_id=patient_id,
        caregiver_id=caregiver_id,
        locale=locale,
        source=source,
    )
    touch_session(session.id)

    session.pending_action = verify_confirmation_token(confirmation_token, patient_id)
    session.last_user_text = message

    requested_locale = detect_requested_locale(message)
    likely_locale = detect_likely_locale(message)
    if requested_locale:
        session.locale = requested_locale
    elif not history and likely_locale:
        session.locale = likely_locale

    if requested_locale and is_language_switch_only(message):
        answer = locale_message(
            session.locale,
            tn="أكيد. من توّا نحكي معاك بالتونسي، وتنجم تخلّط فرنسي عادي.",
            ar="بالتأكيد. سأتحدث معك بالعربية من الآن.",
            fr="Bien sûr. Je continue en français.",
            en="Of course. I will continue in English.",
        )
        await _persist_chat_turn(
            session,
            user_text=message,
            hani_text=answer,
        )
        return _base_result(answer, session)

    if is_human_help_request(message):
        result = await execute_tool(
            "request_human_help",
            {"reasonCategory": "human_requested", "summary": message[:220]},
            session,
        )
        if session.caregiver_id:
            routes = result.get("routes") if isinstance(result, dict) else []
            has_routes = isinstance(routes, list) and len(routes) > 0
            answer = locale_message(
                session.locale,
                ar="أكيد. نجم نوصّلك بمختص مربوط بالحالة — مكالمة، واتساب أو طلب موعد. اختار شنوّة أنسبلك." if has_routes else "أكيد. نعاونك توصل لإنسان. ما لقيتش مسار مهني مربوط بالحالة توّا، لذلك ما باش نبعث حتى شيء من غير موافقتك.",
                fr="Bien sûr. Je peux vous orienter vers un professionnel lié au suivi — appel, WhatsApp ou demande de rendez-vous. Choisissez ce qui vous convient." if has_routes else "Bien sûr. Je vais vous aider à joindre une personne. Aucun parcours professionnel n’est configuré pour le moment, et rien ne sera envoyé sans votre accord.",
                en="Of course. I can connect you with a professional linked to the care plan — call, WhatsApp, or appointment request. Choose what works best." if has_routes else "Of course. I’ll help you reach a person. No professional route is configured right now, and nothing will be sent without your approval.",
            )
        else:
            answer = locale_message(
                session.locale,
                ar="حاضر. بعثت طلب للفريق باش موظف يعاونك." if result.get("success") else "ما نجّمتش نبعث الطلب توّا. إذا الأمر مستعجل اتصل مباشرة بالاستقبال أو بموظف في المكان.",
                fr="D’accord. J’ai envoyé une demande à l’équipe pour qu’un membre du personnel vous aide." if result.get("success") else "Je n’ai pas pu envoyer la demande pour le moment. Si c’est urgent, contactez directement l’accueil ou le personnel sur place.",
                en="Done. I sent a request to the team for a staff member to help you." if result.get("success") else "I could not send the request right now. If it is urgent, contact reception or on-site staff directly.",
            )
        await _persist_chat_turn(
            session,
            user_text=message,
            hani_text=answer,
            purpose="handoff",
        )
        return _base_result(
            answer,
            session,
            tool="request_human_help",
            tools=[
                {
                    "name": "request_human_help",
                    "args": {"reasonCategory": "human_requested"},
                    "result": result,
                }
            ],
        )

    if not session.caregiver_id and is_doctor_name_question(message):
        return _base_result(
            locale_message(
                session.locale,
                ar="ما عنديش اسم طبيب مؤكّد للمصلحة هاذي في المعطيات المتوفرة، وما نحبّش نعطيك اسم من غير تأكيد. نجم نطلبلك مساعدة من موظف.",
                fr="Je n’ai pas de nom de médecin vérifié pour ce service dans les données disponibles. Je peux demander à un membre du personnel de vous aider.",
                en="I do not have a verified doctor name for this service in the available data. I can ask a staff member to help.",
            ),
            session,
        )

    contents = _content_from_history(history)
    contents.append(types.Content(role="user", parts=[types.Part(text=message)]))

    runtime_context = await fetch_runtime_context(session)

    semantic_signal = detect_semantic_distress(message) if session.caregiver_id else None
    if semantic_signal and session.caregiver_id:
        try:
            signal_result = await execute_tool(
                "record_support_signal",
                semantic_signal,
                session,
            )
            runtime_context["currentSupportSignal"] = {
                **semantic_signal,
                "stored": bool(signal_result.get("success")) if isinstance(signal_result, dict) else False,
                "instruction": (
                    "Use this only as a private support cue. Ask/check gently, do not diagnose, "
                    "and do not break confidentiality automatically."
                ),
            }
        except Exception as signal_error:
            print("semantic support signal failed", type(signal_error).__name__)

    config = types.GenerateContentConfig(
        system_instruction=build_runtime_system_prompt(runtime_context)
        + (
            "\n\nCURRENT CONVERSATION LANGUAGE: "
            + session.locale
            + ". Locale tn means Tunisian Derja; locale ar means Modern Standard Arabic; "
              "fr means French; en means English. Reply in this language unless the current user message clearly switches language."
        ),
        tools=[types.Tool(function_declarations=TOOL_DECLARATIONS)],
        max_output_tokens=420,
        temperature=0.3,
    )

    response = await _generate(contents=contents, config=config)

    tool_events: list[dict[str, Any]] = []
    for _ in range(5):
        calls = response.function_calls or []
        if not calls:
            break

        # IMPORTANT: keep Gemini's original model Content object intact.
        # Gemini 3.x tool-call parts include an opaque thought_signature that
        # must be sent back on the next generate_content call. Rebuilding the
        # function-call Parts manually drops that signature and causes a
        # 400 INVALID_ARGUMENT on the following tool turn.
        candidate_content = None
        if response.candidates:
            candidate_content = response.candidates[0].content

        if candidate_content is None:
            raise RuntimeError("gemini_tool_call_missing_candidate_content")

        contents.append(candidate_content)

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
        response = await _generate(contents=contents, config=config)

    reply = (response.text or "").strip()
    if not reply:
        reply = locale_message(
            session.locale,
            ar="سامحني، ما نجّمتش نكمّل الإجابة توّا. تنجم تعاود السؤال أو نطلبلك مساعدة من موظف.",
            fr="Désolé, je n’ai pas pu terminer la réponse. Vous pouvez reformuler ou me demander de contacter un membre du personnel.",
            en="Sorry, I could not complete the answer. You can rephrase or ask me to contact a staff member.",
        )

    pending_token = sign_confirmation_token(session.pending_action, patient_id) if session.pending_action else None
    ui_actions = []
    for event in tool_events:
        action = event.get("result", {}).get("uiAction")
        if isinstance(action, dict) and action.get("url"):
            ui_actions.append(action)

    await _persist_chat_turn(
        session,
        user_text=message,
        hani_text=reply,
        purpose=(
            "handoff"
            if any(
                event.get("name") in {
                    "request_human_help",
                    "create_professional_contact_request",
                }
                for event in tool_events
            )
            else "general"
        ),
    )

    return {
        "message": reply,
        "sessionId": session.id,
        "locale": session.locale,
        "confirmationToken": pending_token,
        "tools": tool_events,
        "tool": tool_events[-1]["name"] if tool_events else None,
        "uiActions": ui_actions[:3],
        "model": settings.text_model,
    }
