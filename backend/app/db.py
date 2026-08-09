"""SQLite helpers for the JeevanDoot backend."""
import os
import sqlite3

DB_PATH = os.environ.get("JEEVANDOOT_DB", os.path.join(os.path.dirname(__file__), "jeevandoot.db"))


def get_connection() -> sqlite3.Connection:
    """Return a new connection with row factory + foreign keys enabled."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


SCHEMA = """
CREATE TABLE IF NOT EXISTS patients (
    id TEXT PRIMARY KEY,
    phone TEXT UNIQUE,
    name TEXT NOT NULL,
    age TEXT,
    gender TEXT,
    blood_group TEXT,
    email TEXT,
    address TEXT,
    dob TEXT,
    id_number TEXT,
    language TEXT,
    photo_url TEXT,
    allergies TEXT,
    chronic_conditions TEXT,
    height TEXT,
    weight TEXT,
    medications TEXT,
    sms_alerts INTEGER DEFAULT 1,
    app_alerts INTEGER DEFAULT 1,
    email_updates INTEGER DEFAULT 0,
    reminder_alerts INTEGER DEFAULT 1,
    appointment_alerts INTEGER DEFAULT 1,
    data_sharing INTEGER DEFAULT 0,
    app_lock INTEGER DEFAULT 1,
    biometric_lock INTEGER DEFAULT 0,
    share_health_reports INTEGER DEFAULT 0,
    marketing_updates INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS doctors (
    id TEXT PRIMARY KEY,
    medical_id TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    specialization TEXT,
    registration_id TEXT,
    clinic TEXT,
    working_hours TEXT,
    working_days TEXT,
    rating TEXT,
    experience TEXT,
    is_available INTEGER DEFAULT 1,
    photo_url TEXT
);

CREATE TABLE IF NOT EXISTS queue_patients (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    name TEXT NOT NULL,
    age TEXT,
    gender TEXT,
    risk TEXT NOT NULL,
    risk_label TEXT,
    symptoms TEXT NOT NULL,
    wait_minutes INTEGER,
    consult_type TEXT,
    vitals_temp TEXT,
    vitals_hr TEXT,
    vitals_spo2 TEXT,
    vitals_bp TEXT,
    history_conditions TEXT,
    history_allergies TEXT,
    history_medications TEXT,
    history_consultations TEXT,
    ai_summary TEXT,
    arrival_time TEXT,
    status TEXT DEFAULT 'WAITING',
    ai_risk_score INTEGER,
    ai_triage_level TEXT,
    ai_triage_reason TEXT,
    final_triage_level TEXT,
    triage_source TEXT DEFAULT 'AI',
    triage_reason TEXT,
    doctor_override_reason TEXT,
    safety_escalated INTEGER DEFAULT 0,
    critical_symptoms TEXT,
    symptom_duration TEXT,
    symptom_severity TEXT,
    symptom_onset TEXT,
    vitals_rr TEXT,
    vitals_recorded_at TEXT,
    vitals_glucose TEXT,
    vitals_weight TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS triage_history (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    previous_level TEXT,
    new_level TEXT,
    risk_score INTEGER,
    source TEXT,
    reason TEXT,
    changed_by TEXT,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS appointments (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    name TEXT NOT NULL,
    time TEXT NOT NULL,
    date_label TEXT,
    status TEXT,
    risk TEXT,
    risk_label TEXT,
    consult_type TEXT
);

CREATE TABLE IF NOT EXISTS medicines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    generic_name TEXT,
    brand_name TEXT,
    strength TEXT,
    dosage_form TEXT,
    route TEXT,
    category TEXT,
    active INTEGER DEFAULT 1,
    quick_select INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS prescriptions (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    doctor_id TEXT,
    doctor_name TEXT,
    consultation_id TEXT,
    status TEXT DEFAULT 'DRAFT',
    date TEXT,
    issued_at TEXT,
    created_at TEXT,
    updated_at TEXT,
    notes TEXT,
    additional_instructions TEXT
);

CREATE TABLE IF NOT EXISTS prescription_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prescription_id TEXT,
    medicine_id TEXT,
    name TEXT,
    generic_name TEXT,
    strength TEXT,
    dosage_form TEXT,
    dose TEXT,
    frequency TEXT,
    duration TEXT,
    duration_unit TEXT,
    route TEXT,
    timing TEXT,
    instructions TEXT,
    display_order INTEGER DEFAULT 0,
    category TEXT,
    dosage TEXT,
    unit TEXT,
    morning INTEGER,
    afternoon INTEGER,
    night INTEGER,
    days INTEGER
);

CREATE TABLE IF NOT EXISTS prescription_audit_log (
    id TEXT PRIMARY KEY,
    prescription_id TEXT,
    doctor_id TEXT,
    action TEXT,
    timestamp TEXT,
    metadata TEXT
);

CREATE TABLE IF NOT EXISTS records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id TEXT,
    date TEXT,
    type TEXT,
    title TEXT,
    detail TEXT
);

CREATE TABLE IF NOT EXISTS reminders (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    time TEXT,
    title TEXT,
    subtitle TEXT,
    icon TEXT,
    active INTEGER DEFAULT 0,
    done INTEGER DEFAULT 0
);

-- Medicine reminders created from a prescription (patient-facing).
CREATE TABLE IF NOT EXISTS medicine_reminders (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    prescription_id TEXT,
    medicine_id TEXT,
    medicine_name TEXT NOT NULL,
    category TEXT DEFAULT 'Tablet',
    dosage TEXT DEFAULT '',
    unit TEXT DEFAULT 'mg',
    quantity INTEGER DEFAULT 1,
    period TEXT DEFAULT 'morning',
    meal_instruction TEXT DEFAULT 'After food',
    time TEXT DEFAULT '08:00',
    start_date TEXT,
    end_date TEXT,
    duration_days INTEGER DEFAULT 5,
    reminder_type TEXT DEFAULT 'medicine',
    voice_enabled INTEGER DEFAULT 0,
    language TEXT DEFAULT 'hi',
    status TEXT DEFAULT 'active',
    created_at TEXT,
    updated_at TEXT
);

-- Individual dose tracking for a medicine reminder.
CREATE TABLE IF NOT EXISTS medicine_doses (
    id TEXT PRIMARY KEY,
    reminder_id TEXT NOT NULL,
    scheduled_time TEXT NOT NULL,
    status TEXT DEFAULT 'upcoming',
    taken_at TEXT
);

-- Follow-up visit reminders (one per prescription).
CREATE TABLE IF NOT EXISTS followup_reminders (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    prescription_id TEXT,
    doctor_name TEXT,
    followup_date TEXT,
    followup_time TEXT DEFAULT '10:00',
    reason TEXT DEFAULT 'Follow-up consultation',
    voice_enabled INTEGER DEFAULT 0,
    language TEXT DEFAULT 'hi',
    enabled INTEGER DEFAULT 1,
    created_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS auth_tokens (
    token TEXT PRIMARY KEY,
    role TEXT NOT NULL,
    user_id TEXT NOT NULL,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS doctor_availability (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    doctor_id TEXT NOT NULL,
    date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    slot_duration INTEGER DEFAULT 30,
    status TEXT DEFAULT 'available',
    UNIQUE (doctor_id, date, start_time)
);

CREATE TABLE IF NOT EXISTS asha_requests (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    asha_id TEXT,
    asha_name TEXT,
    patient_name TEXT,
    specialty TEXT,
    preferred_date TEXT,
    preferred_time TEXT,
    preferred_language TEXT,
    reason TEXT,
    notes TEXT,
    status TEXT DEFAULT 'requested',
    appointment_id TEXT,
    created_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT DEFAULT 'system',
    read INTEGER DEFAULT 0,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS appointment_audit (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id TEXT NOT NULL,
    action TEXT NOT NULL,
    from_value TEXT,
    to_value TEXT,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS consultations (
    id TEXT PRIMARY KEY,
    appointment_id TEXT,
    patient_id TEXT NOT NULL,
    doctor_id TEXT NOT NULL,
    scheduled_start TEXT,
    scheduled_end TEXT,
    status TEXT NOT NULL DEFAULT 'SCHEDULED',
    started_at TEXT,
    ended_at TEXT,
    duration_seconds INTEGER,
    connection_quality TEXT
);

CREATE TABLE IF NOT EXISTS case_files (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    queue_id TEXT,
    ai_summary TEXT,
    original_ai_summary TEXT,
    doctor_edited_summary TEXT,
    edited_by TEXT,
    edited_at TEXT,
    primary_complaint TEXT,
    structured_symptoms TEXT,
    symptom_duration TEXT,
    symptom_severity TEXT,
    symptom_progression TEXT,
    medical_history TEXT,
    current_vitals TEXT,
    ai_risk_score INTEGER,
    ai_triage_level TEXT,
    final_triage_level TEXT,
    triage_source TEXT,
    important_flags TEXT,
    ai_insights TEXT,
    generated_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS case_file_audit_log (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    doctor_id TEXT,
    action TEXT,
    timestamp TEXT,
    metadata TEXT
);

CREATE TABLE IF NOT EXISTS consultation_notes (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    doctor_id TEXT,
    doctor_name TEXT,
    consultation_id TEXT,
    diagnosis TEXT,
    notes TEXT,
    vitals TEXT,
    symptoms TEXT,
    ai_summary TEXT,
    created_at TEXT
);
"""

# Columns added to pre-existing tables so the teleconsultation feature works
# with databases created before this feature shipped. `ALTER TABLE ... ADD
# COLUMN` is idempotent because we only add columns that are missing.
_APPOINTMENT_EXTRA_COLUMNS = [
    ("doctor_id", "TEXT"),
    ("date", "TEXT"),
    ("start_time", "TEXT"),
    ("end_time", "TEXT"),
    ("reason", "TEXT"),
    ("booking_source", "TEXT DEFAULT 'SELF'"),
    ("meeting_id", "TEXT"),
    ("attachments", "TEXT"),
    ("created_at", "TEXT"),
    ("updated_at", "TEXT"),
]

_DOCTOR_EXTRA_COLUMNS = [
    ("qualification", "TEXT"),
    ("languages", "TEXT"),
    ("consultation_fee", "REAL DEFAULT 0"),
]

_PRESCRIPTION_EXTRA_COLUMNS = [
    ("date_iso", "TEXT"),
    ("follow_up_date", "TEXT"),
    ("follow_up_time", "TEXT"),
]


def _ensure_columns(conn, table: str, columns: list) -> None:
    existing = {r["name"] for r in conn.execute(f"PRAGMA table_info({table})")}
    for col, ddl in columns:
        if col not in existing:
            conn.execute(f"ALTER TABLE {table} ADD COLUMN {col} {ddl}")


# New columns added by the prescription writer feature. Applied idempotently
# to databases created before the feature existed.
_MEDICINES_NEW_COLUMNS: dict[str, str] = {
    "generic_name": "TEXT",
    "brand_name": "TEXT",
    "strength": "TEXT",
    "dosage_form": "TEXT",
    "route": "TEXT",
    "active": "INTEGER DEFAULT 1",
    "quick_select": "INTEGER DEFAULT 0",
}

_PRESCRIPTIONS_NEW_COLUMNS: dict[str, str] = {
    "doctor_id": "TEXT",
    "consultation_id": "TEXT",
    "status": "TEXT DEFAULT 'DRAFT'",
    "issued_at": "TEXT",
    "created_at": "TEXT",
    "updated_at": "TEXT",
    "additional_instructions": "TEXT",
}

_ITEMS_NEW_COLUMNS: dict[str, str] = {
    "medicine_id": "TEXT",
    "generic_name": "TEXT",
    "strength": "TEXT",
    "dosage_form": "TEXT",
    "dose": "TEXT",
    "frequency": "TEXT",
    "duration": "TEXT",
    "duration_unit": "TEXT",
    "route": "TEXT",
    "timing": "TEXT",
    "display_order": "INTEGER DEFAULT 0",
}


# New columns added to queue_patients by the risk-sorted queue feature. These
# are applied idempotently to databases created before the feature existed.
_QUEUE_NEW_COLUMNS: dict[str, str] = {
    "arrival_time": "TEXT",
    "status": "TEXT DEFAULT 'WAITING'",
    "ai_risk_score": "INTEGER",
    "ai_triage_level": "TEXT",
    "ai_triage_reason": "TEXT",
    "final_triage_level": "TEXT",
    "triage_source": "TEXT DEFAULT 'AI'",
    "triage_reason": "TEXT",
    "doctor_override_reason": "TEXT",
    "safety_escalated": "INTEGER DEFAULT 0",
    "critical_symptoms": "TEXT",
    "symptom_duration": "TEXT",
    "symptom_severity": "TEXT",
    "symptom_onset": "TEXT",
    "vitals_rr": "TEXT",
    "vitals_recorded_at": "TEXT",
    "vitals_glucose": "TEXT",
    "vitals_weight": "TEXT",
    "updated_at": "TEXT",
}


def _table_columns(conn, table: str) -> set[str]:
    return {row["name"] for row in conn.execute(f"PRAGMA table_info({table})")}


def _add_missing_columns(conn) -> None:
    existing = _table_columns(conn, "queue_patients")
    for name, ddl in _QUEUE_NEW_COLUMNS.items():
        if name not in existing:
            conn.execute(f"ALTER TABLE queue_patients ADD COLUMN {name} {ddl}")

    for table, columns in (
        ("medicines", _MEDICINES_NEW_COLUMNS),
        ("prescriptions", _PRESCRIPTIONS_NEW_COLUMNS),
        ("prescription_items", _ITEMS_NEW_COLUMNS),
    ):
        existing = _table_columns(conn, table)
        for name, ddl in columns.items():
            if name not in existing:
                conn.execute(f"ALTER TABLE {table} ADD COLUMN {name} {ddl}")

    # Pre-existing prescriptions were issued by doctors -> back-compat status.
    conn.execute(
        """UPDATE prescriptions SET status = 'ISSUED',
               issued_at = COALESCE(issued_at, created_at, date)
           WHERE status IS NULL OR status = ''"""
    )

    # Old medicines get a stable ID if they only had an integer autoincrement id.
    conn.execute(
        """UPDATE medicines SET generic_name = COALESCE(generic_name, name)
           WHERE generic_name IS NULL OR generic_name = ''"""
    )


# (name, generic, brand, strength, form, route, category, quick_select)
MEDICINE_CATALOG: list[tuple] = [
    ("Paracetamol", "Paracetamol", "Calpol", "500 mg", "Tablet",
     "Oral", "Analgesic", 1),
    ("Paracetamol 650 mg", "Paracetamol", "Dolo 650", "650 mg",
     "Tablet", "Oral", "Analgesic", 1),
    ("Cetirizine", "Cetirizine", "Cetzine", "10 mg", "Tablet",
     "Oral", "Antihistamine", 1),
    ("ORS Powder", "ORS", "Electral", "21.8 g", "Powder",
     "Oral", "Electrolyte", 1),
    ("Ibuprofen", "Ibuprofen", "Brufen", "400 mg", "Tablet",
     "Oral", "NSAID", 1),
    ("Amoxicillin", "Amoxicillin", "Mox", "500 mg", "Capsule",
     "Oral", "Antibiotic", 1),
    ("Azithromycin", "Azithromycin", "Azithral", "500 mg",
     "Tablet", "Oral", "Antibiotic", 1),
    ("Pantoprazole", "Pantoprazole", "Pan", "40 mg", "Tablet",
     "Oral", "Antacid", 1),
    ("Metformin", "Metformin", "Glycomet", "500 mg", "Tablet",
     "Oral", "Antidiabetic", 0),
    ("Lisinopril", "Lisinopril", "Zestril", "10 mg", "Tablet",
     "Oral", "Antihypertensive", 0),
    ("Amlodipine", "Amlodipine", "Amlong", "5 mg", "Tablet",
     "Oral", "Antihypertensive", 0),
    ("Cough Syrup", "Dextromethorphan", "Benadryl", "100 ml",
     "Syrup", "Oral", "Cough suppressant", 1),
    ("Vitamin D3", "Cholecalciferol", "D3-60", "60000 IU",
     "Tablet", "Oral", "Supplement", 0),
    ("Chlorpheniramine", "Chlorpheniramine", "Piriton", "4 mg",
     "Tablet", "Oral", "Antihistamine", 0),
    ("Diclofenac", "Diclofenac", "Voveran", "50 mg", "Tablet",
     "Oral", "NSAID", 0),
    ("Ranitidine", "Ranitidine", "Rantac", "150 mg", "Tablet",
     "Oral", "Antacid", 0),
    ("Aspirin", "Aspirin", "Ecosprin", "75 mg", "Tablet",
     "Oral", "Antiplatelet", 0),
    ("Omeprazole", "Omeprazole", "Ocid", "20 mg", "Capsule",
     "Oral", "Antacid", 0),
    ("Domperidone", "Domperidone", "Domstal", "10 mg", "Tablet",
     "Oral", "Antiemetic", 0),
    ("Ondansetron", "Ondansetron", "Emeset", "4 mg", "Tablet",
     "Oral", "Antiemetic", 0),
    ("Rabeprazole", "Rabeprazole", "Rablet", "20 mg", "Tablet",
     "Oral", "Antacid", 0),
    ("Ciprofloxacin", "Ciprofloxacin", "Cifran", "500 mg", "Tablet",
     "Oral", "Antibiotic", 0),
    ("Metronidazole", "Metronidazole", "Flagyl", "400 mg", "Tablet",
     "Oral", "Antibiotic", 0),
    ("Doxycycline", "Doxycycline", "Doxt", "100 mg", "Capsule",
     "Oral", "Antibiotic", 0),
    ("Cefixime", "Cefixime", "Taxim-O", "200 mg", "Tablet",
     "Oral", "Antibiotic", 0),
    ("Levofloxacin", "Levofloxacin", "Tavanic", "500 mg", "Tablet",
     "Oral", "Antibiotic", 0),
    ("Prednisolone", "Prednisolone", "Wysolone", "10 mg", "Tablet",
     "Oral", "Steroid", 0),
    ("Clotrimazole", "Clotrimazole", "Candid", "1 %", "Cream",
     "Topical", "Antifungal", 0),
    ("Fluconazole", "Fluconazole", "Zocon", "150 mg", "Capsule",
     "Oral", "Antifungal", 0),
    ("Levocetirizine", "Levocetirizine", "Lezov", "5 mg", "Tablet",
     "Oral", "Antihistamine", 0),
    ("Montelukast", "Montelukast", "Montair", "10 mg", "Tablet",
     "Oral", "Antiasthmatic", 0),
    ("Salbutamol", "Salbutamol", "Asthalin", "100 mcg", "Inhaler",
     "Inhaled", "Bronchodilator", 0),
    ("Acetylcysteine", "Acetylcysteine", "Fluimucil", "600 mg", "Tablet",
     "Oral", "Expectorant", 0),
    ("Ambroxol", "Ambroxol", "Ambrolite", "30 mg", "Tablet",
     "Oral", "Expectorant", 0),
    ("Loperamide", "Loperamide", "Lopamide", "2 mg", "Capsule",
     "Oral", "Antidiarrheal", 0),
    ("Losartan", "Losartan", "Losar", "50 mg", "Tablet",
     "Oral", "Antihypertensive", 0),
    ("Telmisartan", "Telmisartan", "Telma", "40 mg", "Tablet",
     "Oral", "Antihypertensive", 0),
    ("Atenolol", "Atenolol", "Tenormin", "50 mg", "Tablet",
     "Oral", "Beta-blocker", 0),
    ("Atorvastatin", "Atorvastatin", "Atorva", "10 mg", "Tablet",
     "Oral", "Lipid-lowering", 0),
    ("Rosuvastatin", "Rosuvastatin", "Crestor", "10 mg", "Tablet",
     "Oral", "Lipid-lowering", 0),
    ("Glimepiride", "Glimepiride", "Amaryl", "1 mg", "Tablet",
     "Oral", "Antidiabetic", 0),
    ("Sitagliptin", "Sitagliptin", "Januvia", "100 mg", "Tablet",
     "Oral", "Antidiabetic", 0),
    ("Levothyroxine", "Levothyroxine", "Thyronorm", "50 mcg", "Tablet",
     "Oral", "Thyroid hormone", 0),
    ("Tramadol", "Tramadol", "Tramazac", "50 mg", "Tablet",
     "Oral", "Analgesic", 0),
    ("Etoricoxib", "Etoricoxib", "Etoshine", "90 mg", "Tablet",
     "Oral", "NSAID", 0),
    ("Naproxen", "Naproxen", "Naprosyn", "250 mg", "Tablet",
     "Oral", "NSAID", 0),
    ("Mefenamic Acid", "Mefenamic acid", "Mefkind", "500 mg", "Tablet",
     "Oral", "NSAID", 0),
    ("Hyoscine", "Hyoscine butylbromide", "Buscopan", "10 mg", "Tablet",
     "Oral", "Antispasmodic", 0),
    ("Dicyclomine", "Dicyclomine", "Cyclopam", "10 mg", "Tablet",
     "Oral", "Antispasmodic", 0),
    ("Lactulose", "Lactulose", "Duphalac", "10 g", "Syrup",
     "Oral", "Laxative", 0),
    ("Bisacodyl", "Bisacodyl", "Dulcolax", "5 mg", "Tablet",
     "Oral", "Laxative", 0),
    ("Sucralfate", "Sucralfate", "Sucrafil", "1 g", "Tablet",
     "Oral", "Antacid", 0),
    ("Gabapentin", "Gabapentin", "Gabapin", "300 mg", "Capsule",
     "Oral", "Neuropathic pain", 0),
    ("Amitriptyline", "Amitriptyline", "Amitone", "10 mg", "Tablet",
     "Oral", "Antidepressant", 0),
    ("Escitalopram", "Escitalopram", "Nexito", "10 mg", "Tablet",
     "Oral", "Antidepressant", 0),
    ("Clonazepam", "Clonazepam", "Clonapax", "0.5 mg", "Tablet",
     "Oral", "Anxiolytic", 0),
    ("Carbamazepine", "Carbamazepine", "Tegretol", "200 mg", "Tablet",
     "Oral", "Anticonvulsant", 0),
    ("Betahistine", "Betahistine", "Vertin", "8 mg", "Tablet",
     "Oral", "Antivertigo", 0),
    ("Ciprofloxacin Eye Drops", "Ciprofloxacin", "Ciloxan", "0.3 %",
     "Drops", "Ophthalmic", "Antibiotic", 0),
    ("Xylometazoline Nasal Drops", "Xylometazoline", "Otrivin", "0.1 %",
     "Drops", "Nasal", "Decongestant", 0),
    ("Povidone Iodine", "Povidone iodine", "Betadine", "10 %", "Solution",
     "Topical", "Antiseptic", 0),
    ("Albendazole", "Albendazole", "Zentel", "400 mg", "Tablet",
     "Oral", "Anthelmintic", 0),
    ("Zinc Sulfate", "Zinc sulfate", "Zinconia", "20 mg", "Tablet",
     "Oral", "Supplement", 0),
    ("Vitamin C", "Ascorbic acid", "Limcee", "500 mg", "Tablet",
     "Oral", "Supplement", 0),
    ("Ferrous Ascorbate", "Ferrous ascorbate", "Feronia-XT", "100 mg",
     "Tablet", "Oral", "Supplement", 0),
    ("Methylcobalamin", "Methylcobalamin", "Nurokind", "1500 mcg", "Tablet",
     "Oral", "Supplement", 0),
]


def _sync_medicine_catalog(conn) -> None:
    """Idempotently merge the medicine catalog so an existing database gains
    newly added medicines (matched by name, preserving existing ids)."""
    for (name, generic, brand, strength, form, route, category, quick) in MEDICINE_CATALOG:
        conn.execute(
            """INSERT INTO medicines
                   (name, generic_name, brand_name, strength, dosage_form,
                    route, category, active, quick_select)
               SELECT ?, ?, ?, ?, ?, ?, ?, 1, ?
               WHERE NOT EXISTS (SELECT 1 FROM medicines WHERE name = ?)""",
            (name, generic, brand, strength, form, route, category, quick, name),
        )
        conn.execute(
            """UPDATE medicines SET quick_select = ? WHERE name = ? AND quick_select != ?""",
            (quick, name, quick),
        )


def _backfill_existing_queue(conn) -> None:
    """Bring rows created before the feature online: compute triage from the
    stored symptoms/vitals and derive arrival_time from the legacy
    wait_minutes column."""
    from datetime import datetime, timedelta, timezone

    from .triage import compute_triage

    rows = conn.execute(
        """SELECT id, wait_minutes, symptoms, vitals_temp, vitals_hr,
                   vitals_spo2, vitals_bp, vitals_rr
            FROM queue_patients
           WHERE arrival_time IS NULL OR ai_risk_score IS NULL"""
    ).fetchall()
    now = datetime.now(timezone.utc)
    for row in rows:
        d = dict(row)
        labels = d["symptoms"].split("|") if d["symptoms"] else []
        vitals = {
            "temp": d.get("vitals_temp"),
            "hr": d.get("vitals_hr"),
            "spo2": d.get("vitals_spo2"),
            "bp": d.get("vitals_bp"),
            "rr": d.get("vitals_rr"),
        }
        triage = compute_triage(labels, vitals=vitals)
        mins = int(d.get("wait_minutes") or 0)
        arrival = (now - timedelta(minutes=mins)).isoformat()
        conn.execute(
            """UPDATE queue_patients
                  SET arrival_time = ?, status = 'WAITING',
                      ai_risk_score = ?, ai_triage_level = ?,
                      ai_triage_reason = ?, final_triage_level = ?,
                      triage_source = ?, safety_escalated = ?,
                      critical_symptoms = ?, vitals_recorded_at = ?,
                      updated_at = ?
                WHERE id = ?""",
            (
                arrival,
                triage["ai_risk_score"],
                triage["ai_triage_level"],
                triage["ai_triage_reason"],
                triage["final_triage_level"],
                triage["triage_source"],
                1 if triage["safety_escalated"] else 0,
                "|".join(triage["critical_symptoms"]),
                arrival,
                now.isoformat(),
                d["id"],
            ),
        )


def init_db() -> None:
    conn = get_connection()
    conn.executescript(SCHEMA)
    _ensure_columns(conn, "appointments", _APPOINTMENT_EXTRA_COLUMNS)
    _ensure_columns(conn, "doctors", _DOCTOR_EXTRA_COLUMNS)
    _ensure_columns(conn, "prescriptions", _PRESCRIPTION_EXTRA_COLUMNS)
    _add_missing_columns(conn)
    _backfill_existing_queue(conn)
    _sync_medicine_catalog(conn)
    # Database-level double-booking protection: at most one *active*
    # appointment may claim a given (doctor, date, start_time). Cancelled,
    # no-show and completed appointments release the slot. SQLite allows
    # multiple NULLs in unique indexes, so legacy rows (no doctor/date) are
    # unaffected. Dropped + recreated so databases created with an older
    # exclusion list get the updated one.
    conn.execute("DROP INDEX IF EXISTS idx_appointments_slot")
    conn.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_appointments_slot "
        "ON appointments(doctor_id, date, start_time) "
        "WHERE status NOT IN ('Cancelled', 'No Show', 'Completed')"
    )
    conn.commit()
    conn.close()
