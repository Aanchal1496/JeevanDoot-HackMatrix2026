"""Prescription endpoints: create + read for patients."""
import uuid

from fastapi import APIRouter, HTTPException

from ..db import get_connection
from ..schemas import PrescriptionCreate

router = APIRouter(prefix="/api/prescriptions", tags=["prescriptions"])


def _prescription_dict(conn, row) -> dict:
    d = dict(row)
    items = conn.execute(
        "SELECT * FROM prescription_items WHERE prescription_id = ? ORDER BY id",
        (d["id"],),
    ).fetchall()
    d["medicines"] = [dict(i) for i in items]
    return d


@router.get("")
def list_prescriptions(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM prescriptions WHERE patient_id = ? ORDER BY id DESC",
            (patient_id,),
        ).fetchall()
        return {"prescriptions": [_prescription_dict(conn, r) for r in rows]}
    finally:
        conn.close()


@router.get("/{prescription_id}")
def get_prescription(prescription_id: str):
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT * FROM prescriptions WHERE id = ?", (prescription_id,)
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        return {"prescription": _prescription_dict(conn, row)}
    finally:
        conn.close()


@router.post("")
def create_prescription(payload: PrescriptionCreate):
    conn = get_connection()
    try:
        pid = "RX-" + uuid.uuid4().hex[:8].upper()
        conn.execute(
            """INSERT INTO prescriptions (id, patient_id, doctor_name, date, notes)
               VALUES (?,?,?,?,?)""",
            (pid, payload.patient_id, payload.doctor_name,
             "August 10, 2026", payload.notes),
        )
        for m in payload.medicines:
            conn.execute(
                """INSERT INTO prescription_items
                   (prescription_id, name, category, dosage, unit, morning,
                    afternoon, night, days, instructions)
                   VALUES (?,?,?,?,?,?,?,?,?,?)""",
                (pid, m.name, m.category, m.dosage, m.unit, m.morning,
                 m.afternoon, m.night, m.days, m.instructions),
            )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM prescriptions WHERE id = ?", (pid,)
        ).fetchone()
        return {"prescription": _prescription_dict(conn, row), "message": "Prescription saved."}
    finally:
        conn.close()
