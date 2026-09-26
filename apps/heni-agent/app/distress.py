from __future__ import annotations

import re
from typing import Any

_PATTERNS: list[tuple[str, str, list[str]]] = [
    (
        "caregiver_overwhelm",
        "elevated",
        [
            r"cannot take this anymore",
            r"can't take this anymore",
            r"i cannot do this anymore",
            r"i can't do this anymore",
            r"je n'en peux plus",
            r"j'en peux plus",
            r"je suis à bout",
            r"ما عادش نجم",
            r"ماعدش نجم",
            r"تعبت برشة",
            r"فوق طاقتي",
            r"manajamch",
            r"ma3adech najm",
        ],
    ),
    (
        "caregiver_exhaustion",
        "moderate",
        [
            r"i am exhausted",
            r"i'm exhausted",
            r"i am overwhelmed",
            r"je suis épuis",
            r"je suis dépass",
            r"مرهق",
            r"تعبان برشة",
            r"ta3bet",
        ],
    ),
]

def detect_semantic_distress(text: str) -> dict[str, Any] | None:
    value = (text or "").strip().lower()
    if not value:
        return None

    for signal_type, severity, patterns in _PATTERNS:
        for pattern in patterns:
            if re.search(pattern, value, flags=re.IGNORECASE):
                return {
                    "signalType": signal_type,
                    "severity": severity,
                    "confidence": 0.9,
                    "evidence": {
                        "source": "explicit_semantic_phrase",
                        "matchedPattern": pattern,
                    },
                    "experimental": False,
                }
    return None
