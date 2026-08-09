"""Rule-based triage engine mirrored in Python on the backend."""
from typing import Dict, List

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
