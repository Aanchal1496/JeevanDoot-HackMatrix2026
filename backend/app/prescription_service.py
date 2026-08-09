"""Prescription writer service layer.

Keeps the doctor-facing logic out of the routers so the safety rules and the
status lifecycle live in one place:

    DRAFT -> (issue) -> ISSUED -> (cancel/supersede) -> CANCELLED

The service never invents drug safety information: without a validated
interaction database it reports "Safety check unavailable" rather than
fabricating warnings. Allergy and duplicate checks are flags for professional
review - they never block the doctor.
"""
import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

PRESCRIPTION_STATUSES = ("DRAFT", "ISSUED", "CANCELLED")

# A small, explicitly-labeled family map used ONLY to flag *potential*
# relevance of a recorded allergy (e.g. a penicillin allergy vs amoxicillin).
# It is a prompt for review, never a claim of a reaction.
_ALLERGY_FAMILIES: Dict[str, List[str]] = {
    "penicillin": ["amoxicillin", "ampicillin", "amoxiclav", "augmentin",
                   "piperacillin", "cloxacillin", "amoxil"],
    "sulfa": ["sulfamethoxazole", "sulfasalazine", "co-trimoxazole",
              "septrin"],
    "nsaid": ["ibuprofen", "diclofenac", "naproxen", "aspirin", "celecoxib"],
}

FREQUENCIES = (
    "Once daily", "Twice daily", "Three times daily", "Four times daily",
    "Every 4 hours", "Every 6 hours", "Every 8 hours", "Every 12 hours",
    "As directed",
)

DURATION_UNITS = ("days", "weeks", "months", "until finished", "as directed")

ROUTES = (
    "Oral", "Topical", "Sublingual", "Inhaled", "Ophthalmic", "Otic",
    "Nasal", "Rectal", "Other",
)

TIMINGS = (
    "Before food", "After food", "With food", "Empty stomach", "At bedtime",
    "Morning", "Evening", "Any time", "Custom",
)

DOSAGE_FORMS = ("Tablet", "Capsule", "Syrup", "Drops", "Cream", "Injection",
                "Ointment", "Inhaler", "Solution", "Suspension")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Medicine catalog
# ---------------------------------------------------------------------------


def medicine_dict(row) -> Dict[str, Any]:
    d = dict(row)
    return {
        "id": str(d["id"]),
        "name": d["name"],
        "generic_name": d.get("generic_name") or d["name"],
        "brand_name": d.get("brand_name") or "",
        "strength": d.get("strength") or "",
        "dosage_form": d.get("dosage_form") or "",
        "route": d.get("route") or "",
        "category": d.get("category") or "",
        "active": bool(d.get("active", 1)),
        "quick_select": bool(d.get("quick_select", 0)),
    }


def search_medicines(conn, query: str = "", limit: int = 20) -> List[dict]:
    """Search by generic name, brand name, category or strength."""
    if query.strip():
        q = f"%{query.strip()}%"
        rows = conn.execute(
            """SELECT * FROM medicines
               WHERE active = 1
                 AND (name LIKE ? OR generic_name LIKE ? OR brand_name LIKE ?
                      OR category LIKE ? OR strength LIKE ?)
               ORDER BY quick_select DESC, name ASC
               LIMIT ?""",
            (q, q, q, q, q, limit),
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT * FROM medicines WHERE active = 1 ORDER BY name ASC LIMIT ?",
            (limit,),
        ).fetchall()
    return [medicine_dict(r) for r in rows]


def common_medicines(conn, limit: int = 12) -> List[dict]:
    """Configurable quick-select set (admin flags medicines in the catalog)."""
    rows = conn.execute(
        """SELECT * FROM medicines
           WHERE active = 1 AND quick_select = 1
           ORDER BY name ASC LIMIT ?""",
        (limit,),
    ).fetchall()
    # Fall back to a curated default when nothing is flagged yet.
    if not rows:
        names = ("Paracetamol", "Cetirizine", "ORS", "Ibuprofen",
                 "Amoxicillin", "Azithromycin", "Pantoprazole", "Cough Syrup")
        placeholders = ", ".join("?" for _ in names)
        rows = conn.execute(
            f"SELECT * FROM medicines WHERE active = 1 AND name IN ({placeholders})"
            " ORDER BY name ASC LIMIT ?",
            (*names, limit),
        ).fetchall()
    return [medicine_dict(r) for r in rows]


def get_medicine(conn, medicine_id: str) -> Optional[dict]:
    try:
        row = conn.execute(
            "SELECT * FROM medicines WHERE id = ?", (int(medicine_id),)
        ).fetchone()
    except (TypeError, ValueError):
        return None
    if row is None:
        return None
    med = medicine_dict(row)
    if not med["active"]:
        return None
    return med


# ---------------------------------------------------------------------------
# Prescription safety service (flags for review, never blocks, never invents)
# ---------------------------------------------------------------------------


def _allergy_tokens(allergies: List[str]) -> List[str]:
    tokens: List[str] = []
    for raw in allergies:
        for piece in str(raw).replace(",", "|").split("|"):
            piece = piece.strip().lower().rstrip(".").strip()
            if piece and piece not in tokens:
                tokens.append(piece)
    return tokens


def _matches_penicillin_family(allergy: str, medicine: dict) -> bool:
    """Flag a *potential* relevance between a recorded allergy and a drug."""
    name = f"{medicine.get('generic_name', '')} {medicine.get('name', '')}".lower()
    for family, drugs in _ALLERGY_FAMILIES.items():
        family_member = any(d in name for d in drugs)
        if not family_member:
            continue
        if family in allergy or any(d in allergy for d in drugs):
            return True
    # Direct string overlap (e.g. allergy "Penicillin" vs drug "Penicillin").
    if allergy in name:
        return True
    return False


def check_allergy(conn, patient_id: str, medicine: dict) -> Optional[dict]:
    """Return an allergy warning if a recorded allergy may be relevant.

    The result is a prompt for professional review - the system never claims
    the patient will have a reaction and never blocks the doctor.
    """
    row = conn.execute(
        """SELECT q.history_allergies, p.allergies
             FROM queue_patients q
             LEFT JOIN patients p ON p.id = q.patient_id
            WHERE q.patient_id = ? OR q.id = ?""",
        (patient_id, patient_id),
    ).fetchone()
    if row is None:
        return None
    allergies: List[str] = []
    for col in ("history_allergies", "allergies"):
        value = row[col]
        if value:
            for piece in str(value).replace(",", "|").split("|"):
                piece = piece.strip()
                if piece and piece.lower() not in ("none", "no", "-", "nil"):
                    allergies.append(piece)

    tokens = _allergy_tokens(allergies)
    relevant = [a for a in tokens if _matches_penicillin_family(a, medicine)]
    if not relevant:
        return None
    return {
        "type": "ALLERGY_WARNING",
        "level": "warning",
        "message": (
            "The patient's recorded allergy may be relevant to the selected "
            "medicine. Please verify before prescribing."
        ),
        "allergies": relevant,
        "medicine": medicine.get("generic_name") or medicine.get("name"),
    }


def check_duplicate(existing_items: List[dict], medicine: dict) -> Optional[dict]:
    """Flag when the same generic medicine is already on the prescription."""
    generic = (medicine.get("generic_name") or medicine.get("name") or "").lower()
    if not generic:
        return None
    for item in existing_items:
        item_generic = (
            item.get("generic_name") or item.get("name") or ""
        ).lower()
        if item_generic and generic in item_generic:
            return {
                "type": "DUPLICATE_WARNING",
                "level": "warning",
                "message": (
                    f"{medicine.get('generic_name') or medicine.get('name')} is "
                    "already included in this prescription."
                ),
                "existing_item_id": item.get("id"),
            }
    return None


def evaluate_safety(
    conn, patient_id: str, medicine: dict, existing_items: List[dict]
) -> Dict[str, Any]:
    """Run the available checks. Interaction checks are not fabricated."""
    warnings = []
    allergy = check_allergy(conn, patient_id, medicine)
    if allergy:
        warnings.append(allergy)
    duplicate = check_duplicate(existing_items, medicine)
    if duplicate:
        warnings.append(duplicate)
    return {
        "warnings": warnings,
        # No validated interaction database in this build: never invent.
        "interaction_check": {
            "available": False,
            "message": "Safety check unavailable for drug interactions.",
        },
    }


# ---------------------------------------------------------------------------
# Prescription lifecycle
# ---------------------------------------------------------------------------


def add_audit(conn, prescription_id: str, doctor_id: Optional[str], action: str,
              metadata: Optional[dict] = None) -> None:
    conn.execute(
        """INSERT INTO prescription_audit_log
           (id, prescription_id, doctor_id, action, timestamp, metadata)
           VALUES (?,?,?,?,?,?)""",
        (
            "PA-" + uuid.uuid4().hex[:10].upper(),
            prescription_id,
            doctor_id,
            action,
            now_iso(),
            json.dumps(metadata or {}),
        ),
    )


def prescription_dict(conn, row) -> Dict[str, Any]:
    """Serialize a prescription with its items + safety hints."""
    d = dict(row)
    items = conn.execute(
        """SELECT * FROM prescription_items
           WHERE prescription_id = ? ORDER BY display_order ASC, id ASC""",
        (d["id"],),
    ).fetchall()
    def _item(row):
        i = dict(row)
        return {
            "id": i["id"],
            "medicine_id": i.get("medicine_id"),
            "name": i["name"],
            "generic_name": i.get("generic_name") or i["name"],
            "strength": i.get("strength") or "",
            "dosage_form": i.get("dosage_form") or "",
            "dose": i.get("dose") or "",
            "frequency": i.get("frequency") or "",
            "duration": i.get("duration"),
            "duration_unit": i.get("duration_unit") or "days",
            "route": i.get("route") or "",
            "timing": i.get("timing") or "",
            "instructions": i.get("instructions") or "",
            "display_order": i.get("display_order") or 0,
            # Back-compat fields for the older patient UI.
            "category": i.get("category") or "",
            "dosage": i.get("dosage") or "",
            "unit": i.get("unit") or "",
            "morning": i.get("morning") or 0,
            "afternoon": i.get("afternoon") or 0,
            "night": i.get("night") or 0,
            "days": i.get("days") or 0,
        }

    d["medicines"] = [_item(i) for i in items]
    return d


def get_prescription(conn, prescription_id: str) -> Optional[dict]:
    row = conn.execute(
        "SELECT * FROM prescriptions WHERE id = ?", (prescription_id,)
    ).fetchone()
    return prescription_dict(conn, row) if row else None


def get_open_draft(conn, patient_id: str) -> Optional[dict]:
    """One unfinished draft per patient (no duplicate drafts)."""
    row = conn.execute(
        """SELECT * FROM prescriptions
           WHERE patient_id = ? AND status = 'DRAFT'
           ORDER BY created_at DESC LIMIT 1""",
        (patient_id,),
    ).fetchone()
    return prescription_dict(conn, row) if row else None


def create_draft(conn, patient_id: str, doctor_id: Optional[str],
                 doctor_name: str, consultation_id: Optional[str]) -> dict:
    existing = get_open_draft(conn, patient_id)
    if existing:
        return existing
    rx_id = "RX-" + uuid.uuid4().hex[:8].upper()
    ts = now_iso()
    conn.execute(
        """INSERT INTO prescriptions
           (id, patient_id, doctor_id, doctor_name, consultation_id, status,
            created_at, updated_at, date)
           VALUES (?,?,?,?,?,?,?,?,?)""",
        (rx_id, patient_id, doctor_id, doctor_name, consultation_id, "DRAFT",
         ts, ts, datetime.now().strftime("%d %b %Y")),
    )
    add_audit(conn, rx_id, doctor_id, "DRAFT_CREATED",
              {"patient_id": patient_id})
    row = conn.execute(
        "SELECT * FROM prescriptions WHERE id = ?", (rx_id,)
    ).fetchone()
    return prescription_dict(conn, row)


def _validate_item_fields(payload) -> List[str]:
    """Required fields for a prescription item (backend revalidation).

    Dose and frequency are always required. Custom frequencies are allowed
    (the doctor must not be forced into a preset); only an empty frequency is
    rejected.
    """
    missing = []
    if not (payload.dose or "").strip():
        missing.append("dose")
    if not (payload.frequency or "").strip():
        missing.append("frequency")
    return missing


def add_item(conn, rx: dict, payload, medicine: dict,
             doctor_id: Optional[str]) -> dict:
    missing = _validate_item_fields(payload)
    if missing:
        raise ValueError(
            "Missing required fields: " + ", ".join(missing) + "."
        )
    # Snapshot the catalog entry so history stays accurate even if the
    # catalog changes later (spec: store the medicine snapshot).
    display_order = conn.execute(
        "SELECT COALESCE(MAX(display_order), -1) + 1 AS n"
        " FROM prescription_items WHERE prescription_id = ?",
        (rx["id"],),
    ).fetchone()["n"]
    generic = payload.generic_name or medicine["generic_name"]
    conn.execute(
        """INSERT INTO prescription_items
           (prescription_id, medicine_id, name, generic_name, strength,
            dosage_form, dose, frequency, duration, duration_unit, route,
            timing, instructions, display_order, category)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
        (
            rx["id"],
            medicine["id"],
            medicine["name"],
            generic,
            payload.strength or medicine.get("strength") or "",
            payload.dosage_form or medicine.get("dosage_form") or "",
            (payload.dose or "").strip(),
            (payload.frequency or "").strip(),
            str(payload.duration) if payload.duration is not None else None,
            payload.duration_unit or "days",
            payload.route or medicine.get("route") or "",
            payload.timing or "",
            payload.instructions or "",
            display_order,
            medicine.get("category") or "",
        ),
    )
    conn.execute(
        "UPDATE prescriptions SET updated_at = ? WHERE id = ?",
        (now_iso(), rx["id"]),
    )
    add_audit(conn, rx["id"], doctor_id, "MEDICINE_ADDED",
              {"medicine": generic})
    row = conn.execute(
        "SELECT * FROM prescriptions WHERE id = ?", (rx["id"],)
    ).fetchone()
    return prescription_dict(conn, row)


def update_item(conn, rx: dict, item_id: int, payload,
                doctor_id: Optional[str]) -> dict:
    fields = {
        "strength": payload.strength,
        "dosage_form": payload.dosage_form,
        "dose": payload.dose,
        "frequency": payload.frequency,
        "duration": payload.duration,
        "duration_unit": payload.duration_unit,
        "route": payload.route,
        "timing": payload.timing,
        "instructions": payload.instructions,
    }
    sets = []
    values = []
    for col, value in fields.items():
        if value is not None:
            sets.append(f"{col} = ?")
            values.append(str(value).strip() if isinstance(value, str) else value)
    if sets:
        values.append(item_id)
        values.append(rx["id"])
        conn.execute(
            f"UPDATE prescription_items SET {', '.join(sets)}"
            " WHERE id = ? AND prescription_id = ?",
            values,
        )
        conn.execute(
            "UPDATE prescriptions SET updated_at = ? WHERE id = ?",
            (now_iso(), rx["id"]),
        )
        add_audit(conn, rx["id"], doctor_id, "MEDICINE_UPDATED",
                  {"item_id": item_id})
    row = conn.execute(
        "SELECT * FROM prescriptions WHERE id = ?", (rx["id"],)
    ).fetchone()
    return prescription_dict(conn, row)


def remove_item(conn, rx: dict, item_id: int, doctor_id: Optional[str]) -> dict:
    conn.execute(
        "DELETE FROM prescription_items WHERE id = ? AND prescription_id = ?",
        (item_id, rx["id"]),
    )
    conn.execute(
        "UPDATE prescriptions SET updated_at = ? WHERE id = ?",
        (now_iso(), rx["id"]),
    )
    add_audit(conn, rx["id"], doctor_id, "MEDICINE_REMOVED",
              {"item_id": item_id})
    row = conn.execute(
        "SELECT * FROM prescriptions WHERE id = ?", (rx["id"],)
    ).fetchone()
    return prescription_dict(conn, row)


def update_notes(conn, rx: dict, notes: str, doctor_id: Optional[str]) -> dict:
    conn.execute(
        """UPDATE prescriptions
           SET additional_instructions = ?, updated_at = ?
           WHERE id = ?""",
        (notes.strip(), now_iso(), rx["id"]),
    )
    row = conn.execute(
        "SELECT * FROM prescriptions WHERE id = ?", (rx["id"],)
    ).fetchone()
    return prescription_dict(conn, row)


def issue_prescription(conn, rx: dict, doctor_id: Optional[str],
                       doctor_name: str) -> dict:
    """Final backend revalidation + issue. Server is the source of truth."""
    if rx["status"] == "ISSUED":
        raise ValueError("This prescription has already been issued.")
    if rx["status"] == "CANCELLED":
        raise ValueError("A cancelled prescription cannot be issued.")
    if not rx["medicines"]:
        raise ValueError("Add at least one medicine before issuing.")
    for item in rx["medicines"]:
        missing = []
        if not item["dose"].strip():
            missing.append("dose")
        if not item["frequency"].strip():
            missing.append("frequency")
        if not item["route"].strip():
            missing.append("route")
        if missing:
            raise ValueError(
                f"{item['name']}: missing {', '.join(missing)}."
            )
    ts = now_iso()
    conn.execute(
        """UPDATE prescriptions
           SET status = 'ISSUED', issued_at = ?, updated_at = ?,
               doctor_name = ?
           WHERE id = ?""",
        (ts, ts, doctor_name, rx["id"]),
    )
    add_audit(conn, rx["id"], doctor_id, "PRESCRIPTION_ISSUED", {})
    row = conn.execute(
        "SELECT * FROM prescriptions WHERE id = ?", (rx["id"],)
    ).fetchone()
    return prescription_dict(conn, row)


def cancel_prescription(conn, rx: dict, reason: str,
                        doctor_id: Optional[str]) -> dict:
    if rx["status"] == "CANCELLED":
        raise ValueError("This prescription is already cancelled.")
    ts = now_iso()
    conn.execute(
        """UPDATE prescriptions
           SET status = 'CANCELLED', updated_at = ?, notes = ?
           WHERE id = ?""",
        (ts, reason, rx["id"]),
    )
    add_audit(conn, rx["id"], doctor_id, "PRESCRIPTION_CANCELLED",
              {"reason": reason})
    row = conn.execute(
        "SELECT * FROM prescriptions WHERE id = ?", (rx["id"],)
    ).fetchone()
    return prescription_dict(conn, row)
