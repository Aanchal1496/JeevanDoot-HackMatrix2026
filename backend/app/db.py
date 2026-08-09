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
"""


def init_db() -> None:
    conn = get_connection()
    conn.executescript(SCHEMA)
    conn.commit()
    conn.close()
