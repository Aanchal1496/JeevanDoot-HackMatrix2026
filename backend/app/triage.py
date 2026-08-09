"""Rule-based triage engine mirrored in Python on the backend.

This module is the single source of truth for the risk-sorted patient queue:

    symptom labels -> risk score (0-100) -> AI triage level -> safety escalation
    -> final triage level -> deterministic queue ordering.

The triage system is a clinical decision-support feature. It never diagnoses
a patient and always leaves room for a doctor to override the classification.
"""
from typing import Any, Dict, Iterable, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Triage levels
# ---------------------------------------------------------------------------

TRIAGE_LEVELS: Tuple[str, ...] = ("RED", "YELLOW", "GREEN")

# Queue ordering: RED is the highest priority, GREEN the lowest.
PRIORITY: Dict[str, int] = {"RED": 0, "YELLOW": 1, "GREEN": 2}

# Score bands used across the whole application.
SCORE_RED = 70
SCORE_YELLOW = 40


def calculate_triage_level(risk_score: int) -> str:
    """Map a normalized 0-100 risk score to a triage level.

    0-39  -> GREEN
    40-69 -> YELLOW
    70-100-> RED
    """
    if risk_score >= SCORE_RED:
        return "RED"
    if risk_score >= SCORE_YELLOW:
        return "YELLOW"
    return "GREEN"


# ---------------------------------------------------------------------------
# Safety layer: critical symptoms never wait silently behind a low score.
# ---------------------------------------------------------------------------

CRITICAL_SYMPTOMS: List[str] = [
    "severe chest pain",
    "chest pain",
    "difficulty breathing",
    "shortness of breath",
    "loss of consciousness",
    "unconscious",
    "severe bleeding",
    "unresponsive",
    "severe allergic reaction",
    "anaphylaxis",
    "severe abdominal pain",
]


def detect_critical_symptoms(symptom_labels: Iterable[str]) -> List[str]:
    """Return the critical phrases found inside the reported symptom labels.

    Matching is case-insensitive and substring based so that free-text
    symptom reports (e.g. \"Shortness of breath since morning\") are caught.
    """
    found: List[str] = []
    for label in symptom_labels:
        text = str(label or "").lower()
        for phrase in CRITICAL_SYMPTOMS:
            if phrase in text and phrase not in found:
                found.append(phrase)
    return found


# ---------------------------------------------------------------------------
# Risk scoring (human-readable weights, no black-box ML required)
# ---------------------------------------------------------------------------

# Substring key -> points. Longer keys are more specific; we always pick the
# highest-weight match for a given reported symptom.
_SYMPTOM_WEIGHTS: Dict[str, int] = {
    "severe chest pain": 30,
    "chest pain": 28,
    "chest discomfort": 24,
    "difficulty breathing": 30,
    "shortness of breath": 30,
    "severe abdominal pain": 50,
    "abdominal pain": 16,
    "breathing": 22,
    "fever": 14,
    "persistent cough": 18,
    "cough": 10,
    "fatigue": 14,
    "headache": 12,
    "body pain": 10,
    "stomach": 12,
    "cold": 8,
    "skin": 6,
    "rash": 8,
}

_MULTI_SYMPTOM_BONUS_PER_EXTRA = 4
_MULTI_SYMPTOM_BONUS_CAP = 16


def _symptom_weight(label: str) -> int:
    text = str(label or "").lower()
    best = 0
    for key, weight in _SYMPTOM_WEIGHTS.items():
        if key in text and weight > best:
            best = weight
    return best


def _to_float(value: Any) -> Optional[float]:
    try:
        if value is None or str(value).strip() == "":
            return None
        return float(str(value).strip())
    except (TypeError, ValueError):
        return None


def _systolic_from_bp(bp: Any) -> Optional[float]:
    text = str(bp or "").replace(" ", "")
    if "/" not in text:
        return None
    return _to_float(text.split("/")[0])


def _vital_points(vitals: Optional[Dict[str, Any]]) -> int:
    """Points contributed by abnormal vital signs (temp/hr/spo2/bp/rr)."""
    v = vitals or {}
    temp = _to_float(v.get("temp"))
    hr = _to_float(v.get("hr"))
    spo2 = _to_float(v.get("spo2"))
    rr = _to_float(v.get("rr"))
    systolic = _systolic_from_bp(v.get("bp"))

    points = 0
    if temp is not None:
        if temp >= 39:
            points += 10
        elif temp >= 38:
            points += 5
        elif temp <= 35:
            points += 12
        elif temp <= 36:
            points += 5
    if hr is not None:
        if hr >= 110:
            points += 10
        elif hr >= 100:
            points += 5
        elif hr <= 55:
            points += 10
    if spo2 is not None:
        if spo2 <= 90:
            points += 20
        elif spo2 <= 94:
            points += 12
        elif spo2 <= 96:
            points += 6
    if rr is not None:
        if rr >= 28:
            points += 15
        elif rr >= 24:
            points += 10
        elif rr <= 9:
            points += 12
    if systolic is not None:
        if systolic >= 180:
            points += 18
        elif systolic >= 160:
            points += 10
    return points


def calculate_risk_score(
    symptom_labels: Iterable[str],
    vitals: Optional[Dict[str, Any]] = None,
    severity: Optional[str] = None,
) -> int:
    """Normalized 0-100 risk score from symptoms, vitals and severity.

    Designed to be explainable: every point maps to a human-readable
    concern (e.g. \"elevated respiratory rate\"), never to a model weight.
    """
    labels = [str(s).strip() for s in symptom_labels if str(s).strip()]

    score = 0
    for label in labels:
        score += _symptom_weight(label)

    if len(labels) > 1:
        score += min(
            _MULTI_SYMPTOM_BONUS_CAP,
            _MULTI_SYMPTOM_BONUS_PER_EXTRA * (len(labels) - 1),
        )

    sev = str(severity or "").lower()
    if "severe" in sev:
        score += 10
    elif "moderate" in sev:
        score += 5

    score += _vital_points(vitals)

    return max(0, min(100, score))


# ---------------------------------------------------------------------------
# Human-readable reasons (never raw model internals)
# ---------------------------------------------------------------------------

def _concerns(symptom_labels: List[str], vitals: Optional[Dict[str, Any]]) -> List[str]:
    """Build a list of plain-language concerns for a patient."""
    v = vitals or {}
    concerns: List[str] = []

    for phrase in detect_critical_symptoms(symptom_labels):
        concerns.append(f"{phrase.capitalize()} reported")

    temp = _to_float(v.get("temp"))
    if temp is not None and temp >= 39:
        concerns.append(f"High fever ({temp:g} C)")
    hr = _to_float(v.get("hr"))
    if hr is not None and hr >= 110:
        concerns.append(f"Elevated heart rate ({hr:g} bpm)")
    spo2 = _to_float(v.get("spo2"))
    if spo2 is not None and spo2 <= 94:
        concerns.append(f"Low blood oxygen (SpO2 {spo2:g}%)")
    rr = _to_float(v.get("rr"))
    if rr is not None and rr >= 24:
        concerns.append(f"Elevated respiratory rate ({rr:g} breaths/min)")
    systolic = _systolic_from_bp(v.get("bp"))
    if systolic is not None and systolic >= 180:
        concerns.append(f"Very high blood pressure ({v.get('bp')})")

    if len(symptom_labels) >= 3:
        concerns.append("Multiple symptoms reported")

    return concerns


def _build_reason(symptom_labels: List[str], vitals: Optional[Dict[str, Any]]) -> str:
    concerns = _concerns(symptom_labels, vitals)
    if concerns:
        return "; ".join(concerns)
    if len(symptom_labels) <= 1:
        return "Mild symptoms reported; routine consultation advised."
    return "Symptoms currently assessed as low risk; routine consultation advised."


# ---------------------------------------------------------------------------
# Full triage computation
# ---------------------------------------------------------------------------

def compute_triage(
    symptom_labels: Iterable[str],
    vitals: Optional[Dict[str, Any]] = None,
    severity: Optional[str] = None,
) -> dict:
    """Run the full pipeline: score -> AI triage -> safety escalation.

    Returns both the original AI assessment (never overwritten) and the
    final triage, which may be escalated by the safety layer.
    """
    labels = [str(s).strip() for s in symptom_labels if str(s).strip()]
    risk_score = calculate_risk_score(labels, vitals=vitals, severity=severity)
    ai_level = calculate_triage_level(risk_score)
    critical = detect_critical_symptoms(labels)
    escalated = bool(critical)
    final_level = "RED" if escalated else ai_level

    ai_reason = _build_reason(labels, vitals)
    if escalated:
        final_reason = "Safety escalation - " + ai_reason
    else:
        final_reason = ai_reason

    return {
        "ai_risk_score": risk_score,
        "ai_triage_level": ai_level,
        "ai_triage_reason": ai_reason,
        "critical_symptoms": critical,
        "safety_escalated": escalated,
        "final_triage_level": final_level,
        "triage_source": "SAFETY_ESCALATION" if escalated else "AI",
        "triage_reason": final_reason,
    }


# ---------------------------------------------------------------------------
# Deterministic queue sorting
# ---------------------------------------------------------------------------

def queue_sort_key(patient: dict) -> tuple:
    """Sort key for the risk-sorted queue.

    Primary: triage level priority (RED > YELLOW > GREEN).
    Secondary: highest risk score first.
    Tertiary: earliest arrival first (longest waiting time first).
    """
    level = str(patient.get("final_triage_level") or "GREEN").upper()
    if level not in PRIORITY:
        level = "GREEN"
    try:
        score = int(patient.get("ai_risk_score") or 0)
    except (TypeError, ValueError):
        score = 0
    arrival = str(patient.get("arrival_time") or "")
    return (PRIORITY[level], -score, arrival)


def sort_queue(patients: List[dict]) -> List[dict]:
    """Sort a list of patient dicts in place-deterministic priority order."""
    return sorted(patients, key=queue_sort_key)


def format_wait_time(minutes: int) -> str:
    """'2 min', '18 min', '1 hr 12 min' - waiting time is always derived
    dynamically from arrival_time and never stored as a changing value."""
    minutes = max(0, int(minutes))
    if minutes < 60:
        return f"{minutes} min"
    hours, rem = divmod(minutes, 60)
    return f"{hours} hr {rem} min" if rem else f"{hours} hr"


# ---------------------------------------------------------------------------
# Patient-facing symptom checker (unchanged behaviour, kept for /api/triage)
# ---------------------------------------------------------------------------

# Canonical symptom id -> human label (English).
SYMPTOM_LABELS: Dict[str, str] = {
    "fever": "Fever",
    "cold": "Cold/Cough",
    "headache": "Headache",
    "stomach": "Stomach",
    "breathing": "Breathing difficulty",
    "chest": "Chest discomfort",
    "body": "Body Pain",
    "skin": "Skin",
}

ADVICE: Dict[str, List[Dict[str, str]]] = {
    "low": [
        {"title": "Stay hydrated", "body": "Drink plenty of water and clear fluids."},
        {"title": "Get adequate rest", "body": "Allow your body time to recover and heal."},
        {"title": "Monitor your temperature", "body": "Check your temperature twice a day and watch for changes in your symptoms."},
    ],
    "consult": [
        {"title": "Book a consultation", "body": "Some of your symptoms should be reviewed by a doctor to ensure your well-being."},
        {"title": "Track your symptoms", "body": "Note the start time, severity, and any changes to share with your doctor."},
        {"title": "Avoid self-medication", "body": "Refrain from taking medicines without a prescription."},
    ],
    "urgent": [
        {"title": "Seek urgent care", "body": "Your symptoms may require immediate medical attention."},
        {"title": "Do not travel alone", "body": "Have someone accompany you to the nearest facility."},
        {"title": "Keep emergency numbers handy", "body": "Call emergency services if your condition worsens."},
    ],
}

REASONS: Dict[str, List[Dict[str, str]]] = {
    "consult": [
        {
            "title": "Fever combined with other symptoms",
            "detail": "Fever together with headache or body pain often needs clinical evaluation.",
        },
        {
            "title": "Multiple symptoms reported",
            "detail": "Combinations of symptoms should be monitored by a healthcare professional.",
        },
    ],
    "urgent": [
        {
            "title": "Chest or breathing symptoms",
            "detail": "Chest discomfort and breathing difficulty can indicate a serious condition.",
        },
    ],
}


def run_triage(symptom_ids: List[str]) -> dict:
    """Compute triage level + rich advice from a list of symptom ids."""
    selected = set(symptom_ids)

    if selected.intersection({"chest", "breathing"}):
        level = "urgent"
    elif "fever" in selected and selected.intersection({"headache", "body"}):
        level = "consult"
    elif len(selected) >= 3:
        level = "consult"
    else:
        level = "low"

    labels = [SYMPTOM_LABELS.get(s, s.replace("_", " ").title()) for s in symptom_ids]

    result = {
        "level": level,
        "symptoms": labels,
        "advice": ADVICE[level],
        "reasons": REASONS.get(level, []),
    }

    if level == "low":
        result["title"] = "Low Risk"
        result["summary"] = "Your symptoms don't currently show signs of an emergency."
    elif level == "consult":
        result["title"] = "Consultation Recommended"
        result["summary"] = "Some of your symptoms may need to be checked by a doctor."
    else:
        result["title"] = "Urgent Care Needed"
        result["summary"] = "Some of your symptoms may require immediate medical care."

    return result
