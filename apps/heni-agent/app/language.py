from __future__ import annotations

import re


def _norm(text: str) -> str:
    return (text or "").strip().lower()


def detect_requested_locale(text: str) -> str | None:
    value = _norm(text)
    if any(term in value for term in (
        "parle en arabe", "parlez en arabe", "parle en arab", "parlez en arab", "parle arabe", "parlez arabe", "en arabe",
        "arabic", "arab", "tunisian", "tunisaian", "tunisia", "tunisien", "tunisienne", "derja", "darija",
        "بالعربي", "بالتونسي", "بالدارجة", "عربي", "تونسي",
    )):
        return "ar"
    if any(term in value for term in ("parle français", "parlez français", "parle francais", "parlez francais", "en français", "en francais", "french", "بالفرنسي")):
        return "fr"
    if any(term in value for term in ("speak english", "in english", "anglais", "english", "بالإنجليزي", "بالانجليزي")):
        return "en"
    return None


def detect_likely_locale(text: str) -> str | None:
    requested = detect_requested_locale(text)
    if requested:
        return requested
    value = _norm(text)
    if re.search(r"[\u0600-\u06ff]", value):
        return "ar"
    if any(term in value for term in (
        "nheb", "naamel", "na3mel", "najjem", "najem", "chnowa", "chnoua", "chneya",
        "sbeh", "l3chiya", "3andi", "aandy", "ghodwa", "tawa", "mouch",
    )):
        return "ar"
    if any(term in value for term in ("bonjour", "je veux", "je voudrais", "avec plaisir", "docteur", "médecin", "medecin")):
        return "fr"
    if any(term in value for term in ("hello", "hi", "i want", "please", "doctor", "appointment")):
        return "en"
    return None


def is_language_switch_only(text: str) -> bool:
    value = _norm(text)
    if not detect_requested_locale(value):
        return False
    task_terms = (
        "rendez", "appointment", "annul", "cancel", "direction", "where", "où", "ou ",
        "document", "prepare", "aide", "human", "humain", "doctor", "docteur", "médecin", "medecin",
    )
    return len(value) <= 70 and not any(term in value for term in task_terms)


def is_human_help_request(text: str) -> bool:
    value = _norm(text)
    return any(term in value for term in (
        "aide humain", "aide humaine", "humain", "humaine", "human help", "talk to a human",
        "parler à quelqu", "parler a quelqu", "agent humain", "staff", "موظف", "إنسان", "انسان",
        "نحكي مع حد", "نحب موظف",
    ))


def is_doctor_name_question(text: str) -> bool:
    value = _norm(text)
    doctor = any(term in value for term in ("doctor", "docteur", "médecin", "medecin", "tabib", "toubib", "طبيب", "دكتور"))
    identity = any(term in value for term in ("nom", "name", "who", "qui", "اسم", "شنو اسمو", "شكون"))
    return doctor and identity


def locale_message(locale: str, *, ar: str, fr: str, en: str) -> str:
    if locale == "ar":
        return ar
    if locale == "en":
        return en
    return fr
