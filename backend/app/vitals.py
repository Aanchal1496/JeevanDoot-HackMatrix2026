"""Centralized vital-signs interpretation service.

The frontend never hard-codes clinical thresholds. Every vital shown in the
UI is evaluated here and the resulting ``status`` is part of the API payload:

    {"type": "heart_rate", "value": 104, "unit": "bpm", "status": "elevated"}

Thresholds are kept in one configurable table so they can be reviewed and
adjusted without touching UI or business logic.
"""
from typing import Any, Dict, List, Optional

# Canonical vital key -> (unit, human label).
VITAL_META: Dict[str, Dict[str, str]] = {
    "hr": {"unit": "bpm", "label": "Heart Rate"},
    "bp": {"unit": "mmHg", "label": "Blood Pressure"},
    "temp": {"unit": "°C", "label": "Temperature"},
    "spo2": {"unit": "%", "label": "SpO2"},
    "rr": {"unit": "breaths/min", "label": "Respiratory Rate"},
    "glucose": {"unit": "mg/dL", "label": "Blood Glucose"},
}

# Reference ranges. For each vital: (low_critical, low, high, high_critical)
# boundary values:
#   value <= low_critical          -> "low_critical"
#   low_critical < value <= low    -> "low"
#   low < value < high             -> "normal"
#   high <= value < high_critical  -> "elevated"
#   value >= high_critical         -> "high_critical"
# A boundary of None means "no threshold" on that side.
VITAL_RANGES: Dict[str, tuple] = {
    "hr": (55.0, 60.0, 100.0, 110.0),
    "temp": (35.0, 36.0, 38.0, 39.0),
    "spo2": (90.0, 94.0, 100.0, None),
    "rr": (9.0, 12.0, 20.0, 24.0),
    "glucose": (70.0, 70.0, 140.0, 180.0),
}

# Blood pressure is evaluated on both systolic and diastolic numbers.
BP_RANGES = {
    "systolic": (90.0, 100.0, 140.0, 160.0),
    "diastolic": (60.0, 65.0, 90.0, 100.0),
}

STATUS_LABELS: Dict[str, str] = {
    "low_critical": "Critically low",
    "low": "Low",
    "normal": "Normal",
    "elevated": "Elevated",
    "high_critical": "Critically high",
}

_STATUS_ORDER = ("low_critical", "low", "normal", "elevated", "high_critical")


def _status_for_value(value: float, boundaries: tuple) -> str:
    low_critical, low, high, high_critical = boundaries
    if low_critical is not None and value <= low_critical:
        return "low_critical"
    if value <= low:
        return "low"
    if high_critical is not None and value >= high_critical:
        return "high_critical"
    if value >= high:
        return "elevated"
    return "normal"


def _worst_status(statuses: List[str]) -> str:
    """Combine statuses (e.g. systolic + diastolic) taking the worst one."""
    if not statuses:
        return "normal"
    ordered = [s for s in _STATUS_ORDER if s in statuses]
    worst = ordered[-1] if ordered else "normal"
    return "normal" if worst == "normal" else worst


def evaluate_vital(vital_type: str, value: Any) -> Optional[Dict[str, Any]]:
    """Evaluate a single vital and return its UI payload, or None if absent.

    Returns e.g.:
        {"type": "heart_rate", "label": "Heart Rate", "value": "104",
         "unit": "bpm", "status": "elevated", "status_label": "Elevated"}
    """
    meta = VITAL_META.get(vital_type)
    if meta is None:
        return None
    try:
        numeric = float(str(value).strip())
    except (TypeError, ValueError):
        return None

    if vital_type == "bp":
        return None  # blood pressure is evaluated by evaluate_bp

    status = _status_for_value(numeric, VITAL_RANGES[vital_type])
    return {
        "type": vital_type,
        "label": meta["label"],
        "value": f"{numeric:g}",
        "unit": meta["unit"],
        "status": status,
        "status_label": STATUS_LABELS[status],
    }


def evaluate_bp(bp_value: Any) -> Optional[Dict[str, Any]]:
    """Evaluate a '148/92' style blood pressure reading."""
    try:
        parts = str(bp_value or "").replace(" ", "").split("/")
        systolic = float(parts[0])
        diastolic = float(parts[1])
    except (TypeError, ValueError, IndexError):
        return None

    sys_status = _status_for_value(systolic, BP_RANGES["systolic"])
    dia_status = _status_for_value(diastolic, BP_RANGES["diastolic"])
    status = _worst_status([sys_status, dia_status])
    return {
        "type": "bp",
        "label": VITAL_META["bp"]["label"],
        "value": f"{systolic:g}/{diastolic:g}",
        "unit": VITAL_META["bp"]["unit"],
        "status": status,
        "status_label": STATUS_LABELS[status],
    }


def evaluate_all_vitals(vitals: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Evaluate every available vital into a display-ready list.

    Vitals with no value are omitted here; the UI renders "Not available"
    when the whole list is empty.
    """
    items: List[Dict[str, Any]] = []

    for key in ("hr", "temp", "spo2", "rr", "glucose"):
        item = evaluate_vital(key, vitals.get(key))
        if item is not None:
            items.append(item)

    bp = evaluate_bp(vitals.get("bp"))
    if bp is not None:
        items.append(bp)

    return items
