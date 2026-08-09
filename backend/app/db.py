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
    ai_summary TEXT
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
    category TEXT
);

CREATE TABLE IF NOT EXISTS prescriptions (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    doctor_name TEXT,
    date TEXT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS prescription_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prescription_id TEXT,
    name TEXT,
    category TEXT,
    dosage TEXT,
    unit TEXT,
    morning INTEGER,
    afternoon INTEGER,
    night INTEGER,
    days INTEGER,
    instructions TEXT
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


def init_db() -> None:
    conn = get_connection()
    conn.executescript(SCHEMA)
    _ensure_columns(conn, "appointments", _APPOINTMENT_EXTRA_COLUMNS)
    _ensure_columns(conn, "doctors", _DOCTOR_EXTRA_COLUMNS)
    _ensure_columns(conn, "prescriptions", _PRESCRIPTION_EXTRA_COLUMNS)
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
