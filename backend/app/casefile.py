"""Pre-consultation case file engine.

Assembles a concise, structured clinical overview from data the application
already stores (queue entry, symptoms, history, vitals, triage assessment).

Everything reuses the existing engines: risk scoring / triage from
``triage.py`` and vital interpretation from ``vitals.py``. No duplicate risk
calculation happens here - the stored ``ai_risk_score`` /
``final_triage_level`` assessment is consumed as-is.

The AI summary is rule-based and deliberately conservative: it never invents
clinical detail. Unknown fields stay "Not reported" / "Not available".
"""
import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .triage import _SYMPTOM_WEIGHTS, detect_critical_symptoms
from .vitals import evaluate_all_vitals

# Canonical queue symptom keys -> normalized display names (reuse, not a new
# extraction pipeline: these map the stored symptom strings).
NORMALIZED_SYMPTOMS: Dict[str, str] = {
    "chest pain": "Chest discomfort",
    "chest discomfort": "Chest discomfort",
    "shortness of breath": "Shortness of breath",
    "difficulty breathing": "Shortness of breath",
    "breathing difficulty": "Shortness of breath",
    "breathing": "Shortness of breath",
    "fever": "Fever",
    "persistent cough": "Persistent cough",
    "cough": "Cough",
    "fatigue": "Fatigue",
    "headache": "Headache",
    "persistent headache": "Headache",
    "body pain": "Body pain",
    "stomach": "Stomach discomfort",
    "cold": "Cold / cough",
    "skin": "Skin symptoms",
    "rash": "Skin rash",
    "mild rash": "Skin rash",
    "severe abdominal pain": "Severe abdominal pain",
    "abdominal pain": "Abdominal pain",
}

_IGNORED_HISTORY = {"", "none", "not reported", "not available", "n/a", "-", "no"}


def _is_present(value: Any) -> bool:
    return str(value or "").strip().lower() not in _IGNORED_HISTORY


def _split_list(value: Any) -> List[str]:
    if not value:
        return []
    # History fields use "|" separators; the patient profile uses commas.
    items = [s.strip() for s in str(value).replace(",", "|").split("|") if s.strip()]
    return [s for s in items if _is_present(s)]


def _normalize_symptom(label: str) -> str:
    text = str(label or "").strip().lower()
    for key, display in NORMALIZED_SYMPTOMS.items():
        if key in text:
            return display
    return str(label or "").strip().title()


def _sentence(items: List[str]) -> str:
    if not items:
        return ""
    if len(items) == 1:
        return items[0]
    return ", ".join(items[:-1]) + " and " + items[-1]


# ---------------------------------------------------------------------------
# Structured symptom extraction (spec section 6)
# ---------------------------------------------------------------------------


def extract_structured_symptoms(
    symptom_labels: List[str],
    duration: str = "",
    severity: str = "",
    onset: str = "",
) -> Dict[str, Any]:
    """Turn raw stored symptom labels into the structured §6 shape.

    The primary complaint is the symptom with the highest risk weight (ties
    broken by report order). Everything else is an associated symptom.
    """
    labels = [str(s).strip() for s in symptom_labels if str(s).strip()]
    normalized = [_normalize_symptom(l) for l in labels]

    if not normalized:
        return {
            "primary_complaint": None,
            "symptoms": [],
            "associated_symptoms": [],
            "duration": duration or "Not reported",
            "severity": severity or "Not reported",
            "onset": onset or "Not reported",
            "progression": "Not reported",
        }

    progression = _progression(severity, labels)

    def weight_of(label: str) -> int:
        text = label.lower()
        best = 0
        for key, weight in _SYMPTOM_WEIGHTS.items():
            if key in text and weight > best:
                best = weight
        return best

    ranked = sorted(
        range(len(normalized)),
        key=lambda i: weight_of(labels[i]),
        reverse=True,
    )
    primary_idx = ranked[0]
    primary = normalized[primary_idx]
    associated = [
        n for i, n in enumerate(normalized) if i != primary_idx
    ]

    structured = []
    for i, name in enumerate(normalized):
        structured.append(
            {
                "name": name,
                "severity": severity or "Not reported",
                "duration": duration or "Not reported",
                "onset": onset or "Not reported",
                "progression": progression,
            }
        )

    return {
        "primary_complaint": primary,
        "symptoms": structured,
        "associated_symptoms": associated,
        "duration": duration or "Not reported",
        "severity": severity or "Not reported",
        "onset": onset or "Not reported",
        "progression": progression,
    }


def _progression(severity: str, labels: List[str]) -> str:
    """Progression is only claimed when there is evidence of escalation.

    Severity is *not* progression: "severe" alone never implies the symptoms
    are getting worse over time. A critical symptom (e.g. difficulty
    breathing) legitimately flags escalation; otherwise the honest answer is
    "Not reported" (the spec forbids inventing clinical history).
    """
    if detect_critical_symptoms(labels):
        return "Worsening"
    return "Not reported"


# ---------------------------------------------------------------------------
# AI symptom summary (spec section 5) - rule based, never fabricates
# ---------------------------------------------------------------------------


def build_ai_summary(
    symptom_labels: List[str],
    duration: str = "",
    severity: str = "",
    onset: str = "",
) -> str:
    """Generate a concise, doctor-friendly summary from available data.

    Every sentence is composed only from reported fields. Anything unknown
    is simply not claimed (the UI renders missing fields as "Not reported").
    """
    labels = [str(s).strip() for s in symptom_labels if str(s).strip()]
    if not labels:
        return "Insufficient symptom information available."

    normalized = [_normalize_symptom(l) for l in labels]
    parts = [f"Patient reports {_sentence(normalized)}."]

    if _is_present(duration):
        parts.append(f"Symptoms began approximately {duration} ago.")
    if _is_present(onset):
        parts.append(f"Onset was {onset.lower()}.")
    if _is_present(severity):
        sev = str(severity).lower()
        if "severe" in sev:
            parts.append("Severity is assessed as severe.")
        elif "moderate" in sev:
            parts.append("Severity is assessed as moderate.")
        else:
            parts.append("Severity is reported as mild.")

    progression = _progression(severity, labels)
    if progression == "Worsening":
        parts.append("Symptoms appear to be worsening.")

    return " ".join(parts)


# ---------------------------------------------------------------------------
# Important clinical flags (spec section 12)
# ---------------------------------------------------------------------------


def generate_important_flags(
    symptom_labels: List[str],
    vitals_items: List[Dict[str, Any]],
    history: Dict[str, Any],
) -> List[Dict[str, str]]:
    """Flags are observations (reported symptom / abnormal vital / known
    allergy / relevant history), never diagnoses."""
    flags: List[Dict[str, str]] = []

    for phrase in detect_critical_symptoms(symptom_labels):
        flags.append(
            {
                "text": f"{phrase.capitalize()} reported",
                "category": "Reported symptom",
                "severity": "high",
            }
        )

    for item in vitals_items:
        if item["status"] in ("elevated", "high_critical"):
            flags.append(
                {
                    "text": f"Elevated {item['label'].lower()} ({item['value']} {item['unit']})",
                    "category": "Abnormal vital",
                    "severity": "high" if item["status"] == "high_critical" else "medium",
                }
            )
        elif item["status"] in ("low", "low_critical"):
            flags.append(
                {
                    "text": f"Low {item['label'].lower()} ({item['value']} {item['unit']})",
                    "category": "Abnormal vital",
                    "severity": "high" if item["status"] == "low_critical" else "medium",
                }
            )

    for allergy in history.get("allergies", []):
        flags.append(
            {
                "text": f"Known allergy: {allergy}",
                "category": "Known allergy",
                "severity": "medium",
            }
        )

    for condition in history.get("conditions", []):
        flags.append(
            {
                "text": f"{condition} history",
                "category": "Relevant history",
                "severity": "medium",
            }
        )

    return flags


# ---------------------------------------------------------------------------
# AI pre-consultation insights (spec section 13)
# ---------------------------------------------------------------------------


def generate_ai_insights(
    symptom_labels: List[str],
    structured: Dict[str, Any],
    vitals_items: List[Dict[str, Any]],
    history: Dict[str, Any],
) -> Dict[str, List[str]]:
    """Suggestions for clinical review - explicitly not a diagnosis."""
    labels = [str(s).strip() for s in symptom_labels if str(s).strip()]
    key_concerns: List[str] = []
    clarify: List[str] = []
    review: List[str] = []

    critical = detect_critical_symptoms(labels)
    if critical:
        key_concerns.append(
            f"Critical symptom reported: {_sentence([c.capitalize() for c in critical])}"
        )
    if len(labels) >= 3:
        key_concerns.append("Multiple symptoms reported")
    if structured.get("progression") == "Worsening":
        key_concerns.append("Symptoms appear to be worsening")
    abnormal = [i for i in vitals_items if i["status"] != "normal"]
    if abnormal:
        key_concerns.append(
            f"{len(abnormal)} current vital{'s' if len(abnormal) > 1 else ''} "
            "outside the configured reference range"
        )
    if history.get("allergies"):
        key_concerns.append("Known allergy reported - verify before prescribing")

    text = " ".join(labels).lower()
    if "chest" in text or "breath" in text:
        clarify.append("Presence of dizziness or fainting")
        clarify.append("Exact onset of chest discomfort")
    if not _is_present(structured.get("duration")) or structured.get("duration") == "Not reported":
        clarify.append("Exact onset and duration of symptoms")
    if structured.get("progression") == "Worsening":
        clarify.append("Any previous similar episodes")
    if "fever" in text:
        clarify.append("Temperature trend and any chills")

    conditions = [c.lower() for c in history.get("conditions", [])]
    if conditions and ("chest" in text or "breath" in text):
        review.append("Cardiovascular evaluation given cardiovascular symptoms and history")
    elif conditions:
        review.append("Review of reported symptoms against known chronic conditions")
    if "diabet" in " ".join(conditions):
        review.append("Glycemic status review")
    if not review:
        review.append("Clinical review of reported symptoms")

    return {
        "key_concerns": key_concerns or ["No specific concerns identified"],
        "information_to_clarify": clarify or ["No missing information identified"],
        "suggested_review": review,
    }


# ---------------------------------------------------------------------------
# Case file assembly + persistence
# ---------------------------------------------------------------------------

_CASE_FILE_COLUMNS = (
    "id", "patient_id", "queue_id", "ai_summary", "original_ai_summary",
    "doctor_edited_summary", "edited_by", "edited_at", "primary_complaint",
    "structured_symptoms", "symptom_duration", "symptom_severity",
    "symptom_progression", "medical_history", "current_vitals",
    "ai_risk_score", "ai_triage_level", "final_triage_level",
    "triage_source", "important_flags", "ai_insights",
    "generated_at", "updated_at",
)


def _history_dict(row) -> Dict[str, List[str]]:
    """History from the queue entry, falling back to the patient profile
    (joined into the row) when the queue row has no history recorded."""
    conditions = _split_list(row.get("history_conditions"))
    allergies = _split_list(row.get("history_allergies"))
    medications = _split_list(row.get("history_medications"))
    consultations = _split_list(row.get("history_consultations"))
    if not conditions:
        conditions = _split_list(row.get("chronic_conditions"))
    if not allergies:
        allergies = _split_list(row.get("allergies"))
    if not medications:
        medications = _split_list(row.get("medications"))
    return {
        "conditions": conditions,
        "allergies": allergies,
        "medications": medications,
        "consultations": consultations,
    }


def _timestamp_label(iso_value: Optional[str]) -> str:
    if not iso_value:
        return ""
    try:
        dt = datetime.fromisoformat(str(iso_value))
        if dt.tzinfo:
            dt = dt.astimezone()
    except ValueError:
        return str(iso_value)
    return dt.strftime("%d %b %Y • %I:%M %p")


def build_case_file_payload(row, stored: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Build the aggregated case-file payload from a queue_patients row.

    ``stored`` is the persisted case_files row (if any); when absent the
    payload is built fresh and ``generated_at``/``updated_at`` are set to
    now by the caller.
    """
    symptoms = _split_list(row.get("symptoms"))
    duration = str(row.get("symptom_duration") or "")
    severity = str(row.get("symptom_severity") or "")
    onset = str(row.get("symptom_onset") or "")

    structured = extract_structured_symptoms(symptoms, duration, severity, onset)
    vitals_items = evaluate_all_vitals(
        {
            "temp": row.get("vitals_temp"),
            "hr": row.get("vitals_hr"),
            "spo2": row.get("vitals_spo2"),
            "bp": row.get("vitals_bp"),
            "rr": row.get("vitals_rr"),
            "glucose": row.get("vitals_glucose"),
        }
    )
    history = _history_dict(row)
    flags = generate_important_flags(symptoms, vitals_items, history)
    insights = generate_ai_insights(symptoms, structured, vitals_items, history)

    ai_summary = build_ai_summary(symptoms, duration, severity, onset)
    original_ai_summary = ai_summary
    doctor_edited_summary = None
    edited_by = None
    edited_at = None
    if stored:
        if stored.get("doctor_edited_summary"):
            ai_summary = stored["doctor_edited_summary"]
            doctor_edited_summary = stored["doctor_edited_summary"]
            edited_by = stored.get("edited_by")
            edited_at = stored.get("edited_at")
            original_ai_summary = stored.get("original_ai_summary") or ai_summary

    final_level = str(row.get("final_triage_level") or "GREEN").upper()

    return {
        "id": stored["id"] if stored else None,
        "patient": {
            "id": row.get("id"),
            "patient_id": row.get("patient_id") or row.get("id"),
            "name": row.get("name"),
            "age": row.get("age"),
            "gender": row.get("gender"),
            "blood_group": row.get("blood_group") or "",
            "queue_status": row.get("status") or "WAITING",
            "wait_minutes": row.get("wait_minutes") or 0,
            "wait_time": row.get("wait_time") or "",
        },
        "symptom_summary": {
            "ai_summary": ai_summary,
            "original_ai_summary": original_ai_summary,
            "doctor_edited_summary": doctor_edited_summary,
            "edited_by": edited_by,
            "edited_at": edited_at,
            "primary_complaint": structured["primary_complaint"],
            "structured_symptoms": structured["symptoms"],
            "associated_symptoms": structured["associated_symptoms"],
            "duration": structured["duration"],
            "severity": structured["severity"],
            "onset": structured["onset"],
            "progression": structured["progression"],
            "triggers": "Not reported",
            "aggravating_factors": "Not reported",
            "relieving_factors": "Not reported",
        },
        "history": {
            "conditions": history["conditions"],
            "medications": history["medications"],
            "allergies": history["allergies"],
            "family_history": [],
            "previous_consultations": history["consultations"],
            "previous_hospitalizations": [],
            "previous_surgeries": [],
        },
        "vitals": {
            "items": vitals_items,
            "recorded_at": row.get("vitals_recorded_at"),
            "recorded_label": _timestamp_label(str(row.get("vitals_recorded_at") or "")),
        },
        "risk_assessment": {
            "ai_risk_score": row.get("ai_risk_score"),
            "ai_triage_level": str(row.get("ai_triage_level") or final_level).upper(),
            "final_triage_level": final_level,
            "triage_source": row.get("triage_source") or "AI",
            "triage_reason": row.get("triage_reason") or row.get("ai_triage_reason"),
            "safety_escalated": bool(row.get("safety_escalated")),
        },
        "flags": flags,
        "ai_insights": insights,
        "timestamps": {
            "generated_at": (stored or {}).get("generated_at"),
            "generated_label": _timestamp_label((stored or {}).get("generated_at")),
            "updated_at": (stored or {}).get("updated_at"),
            "updated_label": _timestamp_label((stored or {}).get("updated_at")),
        },
    }


def upsert_case_file(conn, patient_id: str, row, payload: Dict[str, Any], now: datetime) -> Dict[str, Any]:
    """Persist (or refresh) the case file and return the stored payload."""
    import uuid

    existing = conn.execute(
        "SELECT * FROM case_files WHERE patient_id = ?",
        (patient_id,),
    ).fetchone()
    stored = dict(existing) if existing else None

    sym = payload["symptom_summary"]
    summary = sym["doctor_edited_summary"] or sym["ai_summary"]
    if not stored:
        file_id = "CF-" + uuid.uuid4().hex[:10].upper()
        generated = now.isoformat()
        conn.execute(
            f"""INSERT INTO case_files
                ({", ".join(_CASE_FILE_COLUMNS)})
                VALUES ({", ".join("?" * len(_CASE_FILE_COLUMNS))})""",
            (
                file_id, patient_id, row.get("id") or patient_id,
                summary, sym["original_ai_summary"],
                sym["doctor_edited_summary"], sym["edited_by"], sym["edited_at"],
                sym["primary_complaint"],
                json.dumps(sym["structured_symptoms"]),
                sym["duration"], sym["severity"], sym["progression"],
                json.dumps(payload["history"]),
                json.dumps(payload["vitals"]["items"]),
                row.get("ai_risk_score"),
                payload["risk_assessment"]["ai_triage_level"],
                payload["risk_assessment"]["final_triage_level"],
                payload["risk_assessment"]["triage_source"],
                json.dumps(payload["flags"]),
                json.dumps(payload["ai_insights"]),
                generated, generated,
            ),
        )
        stored = {
            "id": file_id,
            "generated_at": generated,
            "updated_at": generated,
            "original_ai_summary": sym["original_ai_summary"],
            "doctor_edited_summary": sym["doctor_edited_summary"],
            "edited_by": sym["edited_by"],
            "edited_at": sym["edited_at"],
        }
    else:
        # Only write when something actually changed: the GET endpoint is
        # polled by the UI, so unchanged refreshes must stay read-only.
        new_vitals = json.dumps(payload["vitals"]["items"])
        new_flags = json.dumps(payload["flags"])
        new_insights = json.dumps(payload["ai_insights"])
        new_history = json.dumps(payload["history"])
        unchanged = (
            stored.get("ai_summary") == summary
            and stored.get("current_vitals") == new_vitals
            and stored.get("ai_risk_score") == row.get("ai_risk_score")
            and stored.get("ai_triage_level") == payload["risk_assessment"]["ai_triage_level"]
            and stored.get("final_triage_level") == payload["risk_assessment"]["final_triage_level"]
            and stored.get("triage_source") == payload["risk_assessment"]["triage_source"]
            and stored.get("important_flags") == new_flags
            and stored.get("ai_insights") == new_insights
            and stored.get("medical_history") == new_history
        )
        if not unchanged:
            updated = now.isoformat()
            conn.execute(
                """UPDATE case_files
                      SET ai_summary = ?, current_vitals = ?, ai_risk_score = ?,
                          ai_triage_level = ?, final_triage_level = ?,
                          triage_source = ?, important_flags = ?, ai_insights = ?,
                          medical_history = ?, updated_at = ?
                    WHERE id = ?""",
                (
                    summary,
                    new_vitals,
                    row.get("ai_risk_score"),
                    payload["risk_assessment"]["ai_triage_level"],
                    payload["risk_assessment"]["final_triage_level"],
                    payload["risk_assessment"]["triage_source"],
                    new_flags,
                    new_insights,
                    new_history,
                    updated,
                    stored["id"],
                ),
            )
            stored["updated_at"] = updated

    payload["id"] = stored["id"]
    payload["timestamps"]["generated_at"] = stored.get("generated_at")
    payload["timestamps"]["generated_label"] = _timestamp_label(stored.get("generated_at"))
    payload["timestamps"]["updated_at"] = stored.get("updated_at")
    payload["timestamps"]["updated_label"] = _timestamp_label(stored.get("updated_at"))
    return payload


def add_audit_log(conn, patient_id: str, doctor_id: Optional[str], action: str,
                  metadata: Optional[Dict[str, Any]], now: datetime) -> None:
    import uuid

    conn.execute(
        """INSERT INTO case_file_audit_log
           (id, patient_id, doctor_id, action, timestamp, metadata)
           VALUES (?,?,?,?,?,?)""",
        (
            "AL-" + uuid.uuid4().hex[:10].upper(),
            patient_id,
            doctor_id,
            action,
            now.isoformat(),
            json.dumps(metadata or {}),
        ),
    )
