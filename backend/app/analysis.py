"""Deterministic triage + self-care engine.

This module is the single source of truth for risk scoring. It is fully
deterministic and explainable. An optional LLM (if one is configured) may only
supply a plain-language explanation; it can NEVER override the deterministic
red-flag and scoring rules.
"""
from __future__ import annotations

import logging
from typing import Optional

from app.normalizer import SYMPTOM_DEFS

logger = logging.getLogger("jeevandoot.analysis")

# Score -> level thresholds (0-100).
HIGH_THRESHOLD = 70
MEDIUM_THRESHOLD = 35

SEVERITY_MULTIPLIER = {
    None: 1.0,
    "mild": 0.6,
    "moderate": 1.0,
    "severe": 1.8,
}

# Generic, conservative self-care base pool (safe for any low/medium case).
BASE_SELF_CARE = {
    "rest": "Rest and get adequate sleep.",
    "fluids": "Drink enough fluids to stay hydrated.",
    "monitor": "Monitor your symptoms and temperature.",
    "escalate": "Seek medical attention if symptoms worsen.",
}


def _symptom_items(symptoms: list[str], severity: Optional[str]) -> list[dict]:
    items = []
    for sid in symptoms:
        meta = SYMPTOM_DEFS.get(sid)
        if not meta:
            continue
        item = {"name": meta["label"], "id": sid, "severity": severity}
        if meta["red_flag"]:
            item["red_flag"] = True
        items.append(item)
    return items


def detect_red_flags(symptoms: list[str]) -> list[str]:
    flags = []
    for sid in symptoms:
        meta = SYMPTOM_DEFS.get(sid)
        if meta and meta["red_flag"]:
            flags.append(meta["label"])
    return flags


def compute_score(symptoms: list[str], severity: Optional[str], red_flags: list[str]) -> int:
    if red_flags:
        return 100
    mult = SEVERITY_MULTIPLIER.get(severity, 1.0)
    total = sum(SYMPTOM_DEFS[sid]["severity_weight"] for sid in symptoms if sid in SYMPTOM_DEFS)
    score = total * mult
    return min(100, max(0, round(score)))


def classify(score: int, red_flags: list[str]) -> str:
    if red_flags or score >= HIGH_THRESHOLD:
        return "HIGH"
    if score >= MEDIUM_THRESHOLD:
        return "MEDIUM"
    return "LOW"


def build_explanation(
    level: str,
    symptoms: list[str],
    severity: Optional[str],
    duration: Optional[str],
    red_flags: list[str],
) -> str:
    labels = [SYMPTOM_DEFS[sid]["label"].lower() for sid in symptoms if sid in SYMPTOM_DEFS]
    names = ", ".join(labels) if labels else "the information you provided"
    extra = []
    if severity:
        extra.append(f"reported as {severity.lower()}")
    if duration:
        extra.append(f"lasting {duration}")
    ctx = f" ({', '.join(extra)})" if extra else ""

    if level == "HIGH":
        return (
            f"Your symptoms ({names}{ctx}) may require urgent medical attention. "
            "This is based on the presence of potentially serious warning signs "
            "and is not a diagnosis. Please seek care right away."
        )
    if level == "MEDIUM":
        return (
            f"Your symptoms ({names}{ctx}) indicate that your condition is worth "
            "having a healthcare professional review. It is not an emergency, but "
            "a medical evaluation is advisable."
        )
    return (
        f"Your symptoms ({names}{ctx}) appear to be low risk based on the "
        "information you provided. You can monitor your symptoms and follow the "
        "self-care steps provided. This is not a diagnosis."
    )


def build_self_care(
    level: str,
    symptoms: list[str],
    red_flags: list[str],
) -> list[str]:
    if level == "HIGH" or red_flags:
        return [
            "This may be a medical emergency. Do not rely on home self-care.",
            "Seek urgent medical attention now or call emergency services.",
            "If you are with someone, do not be alone until you reach care.",
        ]
    advice = []
    has_fever = "fever" in symptoms
    has_pain = bool({"headache", "body", "stomach", "chest"} & set(symptoms))

    if has_fever:
        advice.append("Rest and get adequate sleep.")
        advice.append("Drink enough fluids to stay hydrated.")
        advice.append("Monitor your temperature and note any changes.")
    elif has_pain:
        advice.append("Rest and avoid strenuous activity.")
        advice.append("Drink enough fluids to stay hydrated.")
        advice.append("Keep a record of your symptoms and how the pain changes.")
    else:
        advice.append("Rest and get adequate sleep.")
        advice.append("Drink enough fluids to stay hydrated.")
        advice.append("Monitor your symptoms and watch for any changes.")

    if level == "MEDIUM":
        advice = [
            "While your symptoms do not appear to be an emergency, they should be",
            "evaluated by a doctor. Please book a consultation to be assessed.",
        ] + advice
    else:
        advice.append("Seek medical attention if your symptoms worsen.")
    return advice


def analyze(
    symptoms: list[str],
    severity: Optional[str] = None,
    duration: Optional[str] = None,
) -> dict:
    symptoms = list(dict.fromkeys(symptoms))
    red_flags = detect_red_flags(symptoms)
    score = compute_score(symptoms, severity, red_flags)
    level = classify(score, red_flags)
    explanation = build_explanation(level, symptoms, severity, duration, red_flags)
    self_care = build_self_care(level, symptoms, red_flags)
    items = _symptom_items(symptoms, severity)

    result = {
        "symptoms": items,
        "risk_score": score,
        "risk_level": level,
        "explanation": explanation,
        "red_flags": red_flags,
        "self_care": self_care,
    }

    logger.info(
        "analysis complete symptoms=%s severity=%s duration=%s "
        "risk_score=%d risk_level=%s red_flags=%s",
        symptoms,
        severity,
        duration,
        score,
        level,
        red_flags,
    )
    return result
