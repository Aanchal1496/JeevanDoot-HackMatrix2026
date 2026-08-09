"""Deterministic, clinically conservative triage engine.

Produces a normalized 0-100 risk score plus a LOW / MEDIUM / HIGH category.

The scoring is fully transparent and explainable:

* every symptom carries a baseline weight,
* severity, worsening, frequency and long duration add modifiers,
* the raw score is clamped to 0-100,
* any red flag (difficulty breathing, severe chest pain, stroke-like
  symptoms, seizures, loss of consciousness, etc.) overrides the computed
  score to a minimum of 80 and forces the level to HIGH.

The AI layer (ai_service) is only allowed to reword the explanation; it
can never change the score or the level computed here.
"""
from typing import Dict, List, Optional

from .symptom_extractor import SymptomAnalysis

LOW = "LOW"
MEDIUM = "MEDIUM"
HIGH = "HIGH"

DISCLAIMER = (
    "This tool provides general health guidance and does not diagnose "
    "medical conditions. Always consult a qualified health professional "
    "for a diagnosis."
)

# Baseline weight per symptom id (0-100 scale, capped before modifiers).
SYMPTOM_WEIGHTS: Dict[str, int] = {
    "fever": 25,
    "headache": 20,
    "cough": 15,
    "breathing": 60,
    "chest": 50,
    "nausea": 15,
    "vomiting": 30,
    "diarrhea": 25,
    "dizziness": 25,
    "fatigue": 10,
    "cold": 10,
    "sore_throat": 10,
    "pain": 20,
    "stomach": 30,
}

# Symptom ids whose mere presence is treated as a red flag.
RED_FLAG_SYMPTOM_IDS = {"breathing"}

# Per-symptom self-care tips used for LOW-risk guidance. No medicines are
# ever recommended; guidance is limited to general supportive care.
SELF_CARE_TIPS: Dict[str, str] = {
    "headache": "Rest in a quiet, dimly lit room and avoid long screen time.",
    "fever": "Rest and monitor your temperature. Dress lightly and drink fluids.",
    "cough": "Stay hydrated and avoid smoke, dust or other irritants.",
    "cold": "Rest, drink warm fluids and monitor your temperature.",
    "sore_throat": "Sip warm fluids and gargle with warm salt water to soothe your throat.",
    "nausea": "Eat small, light meals and sip fluids slowly.",
    "vomiting": "Sip small amounts of water frequently and give your stomach time to settle.",
    "diarrhea": "Drink plenty of fluids to stay hydrated. Consider an oral rehydration solution.",
    "dizziness": "Sit or lie down until the dizziness passes, and avoid sudden movements.",
    "fatigue": "Rest well and keep yourself hydrated.",
    "pain": "Rest the affected area and use gentle heat or cold packs if comfortable.",
    "stomach": "Eat light, bland food and drink fluids in small sips.",
    "breathing": "If breathing ever becomes difficult, seek urgent medical help.",
    "chest": "Chest discomfort should be checked by a doctor.",
}

# Warning signs to watch for, per symptom id (MEDIUM-risk guidance).
WARNING_SIGNS: Dict[str, List[str]] = {
    "headache": ["A sudden, severe headache", "Fainting or confusion"],
    "dizziness": ["Fainting or passing out", "Difficulty speaking or weakness on one side"],
    "fever": ["Fever lasting more than 3 days", "Severe headache or stiff neck"],
    "vomiting": ["Not being able to keep any fluids down", "Vomiting blood"],
    "diarrhea": ["Signs of dehydration (dry mouth, little urine)", "Blood in the stool"],
    "chest": ["Difficulty breathing", "Pain spreading to the arm or jaw"],
    "breathing": ["Worsening breathlessness", "Bluish lips or face"],
    "cough": ["Coughing blood", "Difficulty breathing"],
    "nausea": ["Persistent vomiting", "Severe abdominal pain"],
    "stomach": ["Severe or worsening abdominal pain", "Vomiting blood"],
    "fatigue": ["Sudden severe weakness", "Fainting"],
    "pain": ["Sudden severe pain", "Numbness or weakness"],
    "cold": ["Symptoms getting worse", "Difficulty breathing"],
    "sore_throat": ["Difficulty swallowing or breathing", "High fever"],
}

# ---------------------------------------------------------------------------
# Risk scoring
# ---------------------------------------------------------------------------


def _collect_red_flags(analysis: SymptomAnalysis) -> List[str]:
    """Deterministic red flags from phrase matches + severe symptoms."""
    flags = list(analysis.red_flags)
    ids = set(analysis.symptom_ids)
    if "breathing" in ids and not any(
        "breath" in f.lower() for f in flags
    ):
        flags.append("Difficulty breathing")
    # Chest pain is treated as a red flag when severe OR acute (minutes/hours).
    acute = analysis.duration_days is not None and analysis.duration_days < 1
    if "chest" in ids and (analysis.severity == "severe" or acute):
        flags.append("Chest pain" if acute else "Severe chest pain")
    if "headache" in ids and analysis.severity == "severe":
        flags.append("Sudden severe headache")
    if "stomach" in ids and analysis.severity == "severe":
        flags.append("Severe abdominal pain")
    # De-duplicate while keeping order.
    seen = set()
    unique = []
    for flag in flags:
        if flag not in seen:
            seen.add(flag)
            unique.append(flag)
    return unique


def compute_risk(analysis: SymptomAnalysis) -> dict:
    """Compute risk score (0-100) + level + human-readable factors.

    Returns:
        {"risk_score": int, "risk_level": str,
         "red_flags": [str], "factors": [str]}
    """
    ids = analysis.symptom_ids
    red_flags = _collect_red_flags(analysis)

    # Baseline: sum of symptom weights, capped at 60 so no single symptom
    # can saturate the scale before modifiers are applied.
    base = sum(SYMPTOM_WEIGHTS.get(sid, 0) for sid in ids)
    base = min(base, 60)

    factors: List[str] = []
    score = float(base)

    # Severity modifier.
    if analysis.severity == "severe":
        score += 25
        factors.append("symptoms described as severe")
    elif analysis.severity == "moderate":
        score += 10
        factors.append("symptoms described as moderate")
    elif analysis.severity == "mild":
        score -= 5
        factors.append("symptoms described as mild")

    # Worsening.
    if analysis.worsening:
        score += 10
        factors.append("symptoms getting worse")

    # Repeated / constant vomiting or diarrhea is more concerning.
    if analysis.frequency in ("constant or repeated", "frequent"):
        if "vomiting" in ids or "diarrhea" in ids:
            score += 10
            factors.append("vomiting or diarrhea described as repeated")

    # High fever.
    if "fever" in ids and analysis.severity == "severe":
        score += 10
        factors.append("high fever")

    # Long duration (>= 3 days) for fever / vomiting / diarrhea / cough.
    if analysis.duration_days is not None and analysis.duration_days >= 3:
        if any(s in ids for s in ("fever", "vomiting", "diarrhea", "cough")):
            score += 10
            factors.append("symptoms lasting several days")

    # Multiple simultaneous symptoms.
    if len(ids) >= 3:
        score += 8
        factors.append("multiple symptoms reported together")

    score = max(0, min(100, int(round(score))))

    # Red flags override an otherwise low score.
    if red_flags:
        score = max(score, 80)
        level = HIGH
    elif score >= 75:
        level = HIGH
    elif score >= 40:
        level = MEDIUM
    else:
        level = LOW

    return {
        "risk_score": score,
        "risk_level": level,
        "red_flags": red_flags,
        "factors": factors,
    }

# ---------------------------------------------------------------------------
# Patient guidance + final response
# ---------------------------------------------------------------------------

_GENERIC_SELF_CARE = [
    "Rest and drink enough fluids.",
    "Monitor how you feel and whether symptoms change.",
]

_MEDIUM_PRECAUTIONS = [
    "Rest and stay hydrated.",
    "Avoid driving or operating machinery if you feel dizzy, weak or unwell.",
    "Keep a note of when symptoms started and how they change.",
]


def _low_guidance(analysis: SymptomAnalysis) -> dict:
    tips: List[str] = []
    for sid in analysis.symptom_ids:
        tip = SELF_CARE_TIPS.get(sid)
        if tip and tip not in tips:
            tips.append(tip)
    for generic in _GENERIC_SELF_CARE:
        if generic not in tips:
            tips.append(generic)
    precautions = list(_GENERIC_SELF_CARE) + [t for t in tips if t not in _GENERIC_SELF_CARE]
    precautions = precautions[:4]
    precautions.append("Seek medical advice if symptoms worsen or new symptoms appear.")
    if analysis.symptom_labels:
        summary = (
            "Your symptoms appear mild and are unlikely to require urgent care "
            "based on the information you provided."
        )
        explanation = (
            "Symptoms like these often improve with rest and self-care. This "
            "tool cannot diagnose the cause, but based on what you described "
            "the situation does not currently look urgent."
        )
    else:
        summary = (
            "We could not clearly identify specific symptoms from your "
            "description, so we cannot assess urgency."
        )
        explanation = (
            "No specific symptoms were recognized in what you described. "
            "Please retry with more detail, or select symptoms from the icons. "
            "This tool cannot diagnose medical conditions."
        )
    return {
        "summary": summary,
        "explanation": explanation,
        "precautions": precautions,
        "warning_signs": ["Symptoms that get worse or become severe", "New or unusual symptoms"],
    }


def _medium_guidance(analysis: SymptomAnalysis) -> dict:
    symptom_text = _join_labels(analysis.symptom_labels)
    details = []
    if analysis.worsening:
        details.append("the symptoms are getting worse")
    if analysis.frequency in ("constant or repeated", "frequent"):
        details.append("they are repeated or persistent")
    if analysis.duration_days is not None and analysis.duration_days >= 3:
        details.append("they have lasted several days")
    reason = " and ".join(details) if details else "they continue or worsen"

    explanation = (
        f"The combination of {symptom_text} can have several possible causes, "
        f"and this tool cannot diagnose the cause. Because {reason}, medical "
        "evaluation may be appropriate."
    )
    summary = "Your symptoms may need medical attention if they continue or worsen."

    # Warning signs specific to the reported symptoms.
    warning_signs: List[str] = []
    for sid in analysis.symptom_ids:
        for sign in WARNING_SIGNS.get(sid, []):
            if sign not in warning_signs:
                warning_signs.append(sign)
    for flag in analysis.red_flags:
        if flag not in warning_signs:
            warning_signs.append(flag)
    if not warning_signs:
        warning_signs = ["Symptoms that suddenly get much worse", "Difficulty breathing or chest pain"]

    return {
        "summary": summary,
        "explanation": explanation,
        "precautions": list(_MEDIUM_PRECAUTIONS) + [
            "Contact a doctor if symptoms persist, worsen, or new warning signs appear."
        ],
        "warning_signs": warning_signs[:6],
    }


def _high_guidance(analysis: SymptomAnalysis) -> dict:
    flags = analysis.red_flags or analysis.symptom_labels
    flag_text = _join_labels(flags)
    if flag_text:
        explanation = (
            f"The symptoms you described ({flag_text}) can be serious. This "
            "tool cannot rule out an emergency, so urgent medical attention "
            "is recommended."
        )
    else:
        explanation = (
            "The symptoms you described can be serious. This tool cannot rule "
            "out an emergency, so urgent medical attention is recommended."
        )
    return {
        "summary": "Some symptoms you reported may require urgent medical attention.",
        "explanation": explanation,
        # No self-care reassurance for HIGH risk; do not bury the warning.
        "precautions": [],
        "warning_signs": [],
    }


def _join_labels(labels: List[str]) -> str:
    labels = [str(l).lower() for l in labels if l]
    if not labels:
        return "your symptoms"
    if len(labels) == 1:
        return labels[0]
    return ", ".join(labels[:-1]) + " and " + labels[-1]


def build_response(analysis: SymptomAnalysis) -> dict:
    """Build the complete /api/symptom-check response payload."""
    risk = compute_risk(analysis)
    level = risk["risk_level"]

    if level == LOW:
        guidance = _low_guidance(analysis)
    elif level == MEDIUM:
        guidance = _medium_guidance(analysis)
    else:
        guidance = _high_guidance(analysis)

    return {
        "success": True,
        "risk_score": risk["risk_score"],
        "risk_level": level,
        "summary": guidance["summary"],
        "symptoms": analysis.symptom_labels,
        "duration": analysis.duration,
        "severity": analysis.severity,
        "explanation": guidance["explanation"],
        "precautions": guidance["precautions"],
        "seek_medical_attention": level in (MEDIUM, HIGH),
        "emergency": level == HIGH,
        "warning_signs": guidance["warning_signs"],
        "red_flags": risk["red_flags"],
        "factors": risk["factors"],
        "disclaimer": DISCLAIMER,
    }
