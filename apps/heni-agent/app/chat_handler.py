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


def _content_from_history(
    history: list[dict[str, Any]],
    *,
    newest_message: str,
) -> list[types.Content]:
    """Build compact history while preventing a stale duplicate user turn."""
    contents: list[types.Content] = []
    normalized_newest = _normalized(newest_message)
    compact = history[-8:]

    while compact:
        last = compact[-1]
        last_role = str(last.get("role") or "").lower()
        last_text = str(last.get("content") or last.get("text") or "").strip()
        if last_role in {"user", "caregiver"} and _normalized(last_text) == normalized_newest:
            compact = compact[:-1]
            continue
        break

    for item in compact:
        role = "model" if item.get("role") in {"assistant", "model", "heni"} else "user"
        text = str(item.get("content") or item.get("text") or "").strip()
        if text:
            contents.append(types.Content(role=role, parts=[types.Part(text=text)]))
    return contents


async def _generate(
    *,
    contents: list[types.Content],
    config: types.GenerateContentConfig,
    timeout_seconds: float | None = None,
    model: str | None = None,
):
    return await asyncio.wait_for(
        _client.aio.models.generate_content(
            model=model or settings.text_model,
            contents=contents,
            config=config,
        ),
        timeout=timeout_seconds or settings.model_timeout_seconds,
    )


def _is_retryable_model_error(error: Exception) -> bool:
    status_code = getattr(error, "code", None) or getattr(error, "status_code", None)
    text = str(error).upper()
    return (
        status_code in {408, 429, 500, 502, 503, 504}
        or "RESOURCE_EXHAUSTED" in text
        or "TOO MANY REQUESTS" in text
        or "UNAVAILABLE" in text
        or "DEADLINE_EXCEEDED" in text
        or "TIMEOUT" in text
    )


async def _generate_resilient(
    *,
    contents: list[types.Content],
    config: types.GenerateContentConfig,
    timeout_seconds: float | None = None,
    preferred_model: str | None = None,
):
    models: list[str] = []
    for candidate in (
        preferred_model,
        settings.text_model,
        settings.text_fallback_model,
        "gemini-3.1-flash-lite",
    ):
        if candidate and candidate not in models:
            models.append(candidate)

    last_error: Exception | None = None
    for index, model_name in enumerate(models):
        try:
            response = await _generate(
                contents=contents,
                config=config,
                timeout_seconds=timeout_seconds,
                model=model_name,
            )
            return response, model_name
        except Exception as error:
            last_error = error
            if not _is_retryable_model_error(error) or index == len(models) - 1:
                raise
            print(
                "Hani text model fallback",
                {
                    "from": model_name,
                    "to": models[index + 1],
                    "error": type(error).__name__,
                },
            )

    if last_error is not None:
        raise last_error
    raise RuntimeError("hani_text_generation_failed")


def _normalized(message: str) -> str:
    return " ".join((message or "").strip().lower().split())


def _is_simple_greeting(message: str) -> bool:
    text = _normalized(message)
    greetings = {
        "aaslema",
        "asslema",
        "aslema",
        "aaslema y heni",
        "aaslema ya heni",
        "asslema y heni",
        "asslema ya heni",
        "salam",
        "salem",
        "hello",
        "hi",
        "bonjour",
        "bonsoir",
        "مرحبا",
        "السلام عليكم",
        "عسلامة",
    }
    return text in greetings


def _similar_text(a: str, b: str) -> float:
    a_tokens = set(_normalized(a).split())
    b_tokens = set(_normalized(b).split())
    if not a_tokens or not b_tokens:
        return 0.0
    intersection = len(a_tokens & b_tokens)
    union = len(a_tokens | b_tokens)
    return intersection / union if union else 0.0


def _looks_like_repeated_old_reply(
    reply: str,
    history: list[dict[str, Any]],
    newest_message: str,
) -> bool:
    if not reply:
        return False
    recent_model = [
        str(item.get("content") or item.get("text") or "").strip()
        for item in history[-8:]
        if str(item.get("role") or "").lower() in {"assistant", "model", "heni"}
    ]
    recent_user = [
        str(item.get("content") or item.get("text") or "").strip()
        for item in history[-8:]
        if str(item.get("role") or "").lower() in {"user", "caregiver"}
    ]
    if recent_user and _similar_text(newest_message, recent_user[-1]) > 0.9:
        return False
    return any(
        previous and _similar_text(reply, previous) >= 0.72
        for previous in recent_model[-3:]
    )


def _looks_like_unrequested_appointment_reply(reply: str, message: str) -> bool:
    if _needs_action_tools(message):
        return False
    text = _normalized(reply)
    appointment_terms = (
        "appointment",
        "rendez-vous",
        "rendez vous",
        "prendre, annuler",
        "annuler ou déplacer",
        "déplacer un rendez",
        "book",
        "booking",
        "reserve",
        "réserver",
        "facility",
        "établissement",
        "الموعد",
        "موعد",
        "الحجز",
    )
    return any(term in text for term in appointment_terms)


def _looks_like_care_activity_followup(message: str) -> bool:
    text = " ".join(message.lower().split())
    care_activity_terms = (
        "doura", "dawra", "tour", "walk", "walking", "promenade",
        "sortir", "sortie", "nokhrej", "nokhrj", "nkhrej", "nheb nokhrej",
        "نخرج", "نتمشى", "نمشيو", "دورة", "نزهة", "خرجة",
        "meal", "eat", "eating", "sleep", "slept", "pain", "wja3",
        "noum", "makla", "كلت", "أكل", "نوم", "وجيعة",
    )
    return any(term in text for term in care_activity_terms)


def _needs_action_tools(message: str) -> bool:
    text = " ".join(message.lower().split())
    if _looks_like_care_activity_followup(message):
        explicit_action = (
            "appointment", "rendez-vous", "rendez vous", "rdv", "موعد",
            "book", "booking", "reserve", "réserver", "احجز",
            "doctor appointment", "موعد طبيب",
        )
        if not any(term in text for term in explicit_action):
            return False
    action_terms = (
        "appointment", "rendez-vous", "rendez vous", "rdv", "موعد",
        "doctor", "docteur", "médecin", "طبيب",
        "whatsapp", "appel", "اتصل", "عيط",
        "book", "booking", "reserve", "réserver", "احجز",
        "share", "partage", "شارك",
        "save", "record", "سجل", "سجّل",
        "task", "tâche", "مهمة",
        "human", "staff", "موظف", "إنسان",
        "contacte", "contact ",
    )
    return any(term in text for term in action_terms)


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
    elif likely_locale:
        # Let the newest message drive conversational language. This is
        # especially important for Latin-script Tunisian greetings such as
        # "aaslema y heni", which should not inherit a stale French session.
        session.locale = likely_locale

    if _is_simple_greeting(message):
        answer = locale_message(
            session.locale,
            tn="عسلامة! هاني معاك. شنوة نجم نعاونك فيه توا؟",
            ar="مرحبًا! هاني معك. كيف يمكنني مساعدتك الآن؟",
            fr="Bonjour ! Hani est avec vous. Comment puis-je vous aider maintenant ?",
            en="Hi! Hani is here with you. How can I help right now?",
        )
        await _persist_chat_turn(
            session,
            user_text=message,
            hani_text=answer,
        )
        return _base_result(answer, session)

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
                tn="أكيد. نجم نوصّلك بمختص مربوط بالحالة — مكالمة، واتساب أو طلب موعد. اختار شنوّة أنسبلك." if has_routes else "أكيد. نعاونك توصل لإنسان. ما لقيتش مسار مهني مربوط بالحالة توّا، لذلك ما باش نبعث حتى شيء من غير موافقتك.",
                ar="بالتأكيد. يمكنني مساعدتك في الوصول إلى مختص مرتبط بخطة الرعاية — عبر مكالمة أو واتساب أو طلب موعد. اختر ما يناسبك." if has_routes else "بالتأكيد. سأساعدك في الوصول إلى شخص. لا يوجد مسار مهني مرتبط بالحالة حاليًا، ولن أرسل أي معلومات دون موافقتك.",
                fr="Bien sûr. Je peux vous orienter vers un professionnel lié au suivi — appel, WhatsApp ou demande de rendez-vous. Choisissez ce qui vous convient." if has_routes else "Bien sûr. Je vais vous aider à joindre une personne. Aucun parcours professionnel n’est configuré pour le moment, et rien ne sera envoyé sans votre accord.",
                en="Of course. I can connect you with a professional linked to the care plan — call, WhatsApp, or appointment request. Choose what works best." if has_routes else "Of course. I’ll help you reach a person. No professional route is configured right now, and nothing will be sent without your approval.",
            )
        else:
            answer = locale_message(
                session.locale,
                tn="حاضر. بعثت طلب للفريق باش موظف يعاونك." if result.get("success") else "ما نجّمتش نبعث الطلب توّا. إذا الأمر مستعجل اتصل مباشرة بالاستقبال أو بموظف في المكان.",
                ar="تم. أرسلت طلبًا إلى الفريق ليقوم أحد الموظفين بمساعدتك." if result.get("success") else "تعذر إرسال الطلب الآن. إذا كان الأمر عاجلًا، تواصل مباشرة مع الاستقبال أو أحد الموظفين في المكان.",
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
                tn="ما عنديش اسم طبيب مؤكّد للمصلحة هاذي في المعطيات المتوفرة، وما نحبّش نعطيك اسم من غير تأكيد. نجم نطلبلك مساعدة من موظف.",
                ar="لا أملك اسم طبيب موثقًا لهذه الخدمة ضمن البيانات المتاحة، ولا أريد أن أذكر اسمًا غير مؤكد. يمكنني طلب مساعدة أحد الموظفين.",
                fr="Je n’ai pas de nom de médecin vérifié pour ce service dans les données disponibles. Je peux demander à un membre du personnel de vous aider.",
                en="I do not have a verified doctor name for this service in the available data. I can ask a staff member to help.",
            ),
            session,
        )

    contents = _content_from_history(history, newest_message=message)
    contents.append(types.Content(role="user", parts=[types.Part(text=message)]))

    runtime_context = await fetch_runtime_context(session)

    caregiver_context = runtime_context.get("caregiver")
    if isinstance(caregiver_context, dict):
        caregiver_context = dict(caregiver_context)
        caregiver_context.pop("recentHaniMessages", None)
        runtime_context = {**runtime_context, "caregiver": caregiver_context}

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

    action_tools_enabled = _needs_action_tools(message)

    config = types.GenerateContentConfig(
        system_instruction=build_runtime_system_prompt(runtime_context)
        + (
            "\n\nCURRENT CONVERSATION LANGUAGE: "
            + session.locale
            + ". Locale tn means Tunisian Derja; locale ar means Modern Standard Arabic; "
              "fr means French; en means English. Reply in this language unless the current user message clearly switches language."
            "\nCONTEXT CONTINUITY: Keep discussing the same patient/person, symptom, medication, routine, or family event across short follow-up turns unless the caregiver explicitly changes topic."
            "\nLATEST-MESSAGE PRIORITY: Answer the literal meaning of the newest user message first. Do not reinterpret an ordinary activity, walk, outing, meal, sleep, pain, or family comment as a booking, appointment, directions, or facility request unless the user explicitly asks for that action."
            "\nACTION SAFETY: Only discuss booking/appointments/facility actions when the newest message explicitly asks to book, reserve, schedule, contact, call, or navigate. A phrase about taking Fatma for a walk/outing is a care activity, never an appointment request."
            "\nExample: 'nheb nokhrej naaml beha doura' means the caregiver wants to take the patient for a walk/outing; respond about doing that safely and naturally. It is NOT an appointment request."
            "\nIf the newest message is ambiguous, ask one short clarification instead of switching topics."
            "\nTunisian Latin-script Derja and code-switching with French/Arabic/English are valid. Never treat them as an unsupported language."
            "\nRESPONSE STYLE: Give a complete answer in 1-4 short sentences. Finish the thought. Avoid long lists unless the user asks."
        ),
        tools=(
            [types.Tool(function_declarations=TOOL_DECLARATIONS)]
            if action_tools_enabled
            else None
        ),
        max_output_tokens=900,
        temperature=0.2,
    )

    response, active_model = await _generate_resilient(
        contents=contents,
        config=config,
        timeout_seconds=(
            settings.model_timeout_seconds
            if action_tools_enabled
            else min(9.0, settings.model_timeout_seconds)
        ),
    )

    tool_events: list[dict[str, Any]] = []
    for _ in range(3):
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
            session.runtime_context_cache = None
            session.runtime_context_cached_at = 0.0
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
        response, active_model = await _generate_resilient(
            contents=contents,
            config=config,
            timeout_seconds=settings.model_timeout_seconds,
            preferred_model=active_model,
        )

    reply = (response.text or "").strip()

    # Guard against stale/off-topic generic facility answers. If the newest
    # user message did not ask for an appointment/action but Gemini produced
    # an appointment/navigation boilerplate response, regenerate once with
    # an even stricter latest-message instruction.
    if reply and (
        _looks_like_unrequested_appointment_reply(reply, message)
        or _looks_like_repeated_old_reply(reply, history, message)
    ):
        repair_config = types.GenerateContentConfig(
            system_instruction=(
                build_runtime_system_prompt(runtime_context)
                + "\n\nREPAIR RULE: The previous draft was off-topic. "
                  "Answer ONLY the newest user message. Do not discuss appointments, "
                  "booking, directions, facilities, or institutional services unless "
                  "the newest message explicitly asks for one of those things. "
                  "Use the user's current language and keep the answer brief."
            ),
            max_output_tokens=260,
            temperature=0.1,
        )
        try:
            repaired, repaired_model = await _generate_resilient(
                contents=contents,
                config=repair_config,
                timeout_seconds=min(5.0, settings.model_timeout_seconds),
                preferred_model=active_model,
            )
            repaired_text = (repaired.text or "").strip()
            if repaired_text:
                reply = repaired_text
        except Exception:
            pass

    # Rarely Gemini can stop at the output-token boundary. Recover only in
    # that case so normal chat remains a single fast model request.
    finish_reason = None
    if response.candidates:
        finish_reason = getattr(response.candidates[0], "finish_reason", None)
    if reply and finish_reason is not None and "MAX_TOKENS" in str(finish_reason):
        try:
            candidate_content = response.candidates[0].content
            continuation_contents = [
                *contents,
                candidate_content,
                types.Content(
                    role="user",
                    parts=[
                        types.Part(
                            text=(
                                "Finish only the incomplete final thought from your previous "
                                "answer. Do not restart, repeat, or change topic. Keep it brief."
                            )
                        )
                    ],
                ),
            ]
            continuation, continuation_model = await _generate_resilient(
                contents=continuation_contents,
                config=types.GenerateContentConfig(
                    system_instruction=(
                        "Continue the same Hani answer in the same language and context. "
                        "Return only the missing ending."
                    ),
                    max_output_tokens=220,
                    temperature=0.1,
                ),
                timeout_seconds=min(5.0, settings.model_timeout_seconds),
                preferred_model=active_model,
            )
            ending = (continuation.text or "").strip()
            if ending:
                reply = f"{reply} {ending}".strip()
        except Exception:
            pass

    if not reply:
        reply = locale_message(
            session.locale,
            tn="سامحني، ما نجّمتش نكمّل الإجابة توّا. تنجم تعاود السؤال أو نطلبلك مساعدة من موظف.",
            ar="عذرًا، لم أتمكن من إكمال الإجابة الآن. يمكنك إعادة صياغة السؤال أو طلب المساعدة من شخص مختص.",
            fr="Désolé, je n’ai pas pu terminer la réponse. Vous pouvez reformuler ou me demander de contacter un membre du personnel.",
            en="Sorry, I could not complete the answer. You can rephrase or ask me to contact a staff member.",
        )

    pending_token = sign_confirmation_token(session.pending_action, patient_id) if session.pending_action else None
    ui_actions = []
    for event in tool_events:
        action = event.get("result", {}).get("uiAction")
        if isinstance(action, dict) and action.get("url"):
            ui_actions.append(action)

    asyncio.create_task(
        _persist_chat_turn(
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
