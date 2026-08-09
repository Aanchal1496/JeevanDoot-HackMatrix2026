"""Seed data for the JeevanDoot backend. Inserted only when the DB is empty."""
from datetime import datetime, timedelta, timezone

from .casefile import add_audit_log, build_case_file_payload, upsert_case_file
from .db import get_connection
from .triage import compute_triage

PHOTO_URL = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBITWx9omukcrbVq6oHizm_c_NShTaHdvNkKnJrECbSRpr7IGAjxnk1ZhTpFpKFrISSu8EU6aQMFu8EtAfNk7uT1YxuwD6VvI0s7Iuvude1Sid0pMZud8RMdB32TFe-O7wgyA6so2ZcgfCvTFLv85JQB3USmyXjJZrDj7IEvE3mTQ7_mOzsUrWaRs2ymBwquFS663a1D0wCB5A1mCUgPyZCzDch-rNqxdGpXExzPzNqXNiOKTFq6mFJ"
)

DOCTOR_PHOTO = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuB4o1TFkvIyoFzAWoEO7eNeqCED0RPxkF3vQn-UAcVhDfjtyDZ6Iu7vfKm5WAAXLCaGOWnk6iGiYo7XSMqqFY2uTYpvojScUEFbG5JCF6WvJiAkpeTIomPDJ-DQJd2O5h9OJBpnLMQZNjgywHahoWsdH2L2wN1kDDJkNlhLSRpTx5akNa83Pk0VLLzzhlV_SN7Rm7-e5xdWKKM4cmoKDrQSSeeNEIiwNyngUR665ByPRI_HQgrJJOGx"
)


def row_to_dict(conn, table, key_col, key):
    cur = conn.execute(f"SELECT * FROM {table} WHERE {key_col} = ?", (key,))
    row = cur.fetchone()
    return dict(row) if row else None


def count(conn, table):
    return conn.execute(f"SELECT COUNT(*) AS c FROM {table}").fetchone()["c"]


def seed_if_empty() -> None:
    conn = get_connection()
    try:
        if count(conn, "patients") > 0:
            return

        now = datetime.now(timezone.utc)

        def iso(minutes_ago: int) -> str:
            return (now - timedelta(minutes=minutes_ago)).isoformat()

        # ---- Patients (linked to queue entries for blood group / profile) ----
        patients = [
            (
                "PT-RAMESH", "9876543210", "Ramesh Kumar", "42", "Male", "O+",
                "ramesh.kumar@example.com", "Shop 12, MG Road, Pune, Maharashtra",
                "12 August 1983", "XXXX-XXXX-1234", "hi", PHOTO_URL,
                "Peanuts, Penicillin", "Mild hypertension", "168 cm", "74 kg",
                "Amlodipine 5 mg (daily)",
            ),
            (
                "PT-9942", "9822099421", "Rahul Kumar", "54", "Male", "O+",
                "rahul.kumar@example.com", "Flat 4B, Koregaon Park, Pune",
                "14 March 1972", "XXXX-XXXX-2211", "hi", "",
                "Penicillin (Mild rash)|Dust mites",
                "Hypertension (Diagnosed 2018)|Type 2 Diabetes (Diagnosed 2020)",
                "172 cm", "81 kg", "Metformin 500mg (Daily)|Lisinopril 10mg (Daily)",
            ),
            (
                "PT-88231", "9822088231", "Priya Sharma", "45", "Female", "A+",
                "priya.sharma@example.com", "House 12, Baner, Pune",
                "3 July 1981", "XXXX-XXXX-8831", "hi", "",
                "None", "None", "158 cm", "62 kg", "None",
            ),
            (
                "PT-7731", "9822077310", "Amit Patel", "45", "Male", "B+",
                "amit.patel@example.com", "Sector 9, Kharadi, Pune",
                "22 January 1981", "XXXX-XXXX-7731", "hi", "",
                "Dust mites", "None", "170 cm", "78 kg", "Cetirizine 10mg (As needed)",
            ),
            (
                "PT-8492", "9822084920", "Sunita Rao", "28", "Female", "O+",
                "sunita.rao@example.com", "Room 7, Wakad, Pune",
                "9 September 1998", "XXXX-XXXX-8492", "hi", "",
                "None", "None", "160 cm", "55 kg", "None",
            ),
            (
                "PT-9103", "9822091034", "Kavita Singh", "39", "Female", "AB+",
                "kavita.singh@example.com", "B-502, Magarpatta, Pune",
                "18 November 1986", "XXXX-XXXX-9103", "hi", "",
                "None", "Migraine (Diagnosed 2015)", "163 cm", "58 kg", "None",
            ),
            (
                "PT-9214", "9822092145", "Rajesh Verma", "62", "Male", "B-",
                "rajesh.verma@example.com", "Plot 3, Hadapsar, Pune",
                "2 May 1964", "XXXX-XXXX-9214", "hi", "",
                "None", "Mild arthritis", "169 cm", "70 kg", "None",
            ),
            (
                "PT-8876", "9822088766", "Anil Verma", "51", "Male", "O-",
                "anil.verma@example.com", "C-104, Aundh, Pune",
                "27 August 1975", "XXXX-XXXX-8876", "hi", "",
                "None", "None", "174 cm", "76 kg", "None",
            ),
            (
                "PT-8555", "9822085558", "Sneha Gupta", "33", "Female", "A-",
                "sneha.gupta@example.com", "D-201, Viman Nagar, Pune",
                "5 June 1993", "XXXX-XXXX-8555", "hi", "",
                "None", "None", "157 cm", "54 kg", "None",
            ),
        ]
        conn.executemany(
            """INSERT INTO patients
               (id, phone, name, age, gender, blood_group, email, address,
                dob, id_number, language, photo_url, allergies,
                chronic_conditions, height, weight, medications)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            patients,
        )

        # ---- Doctors ---------------------------------------------------------
        conn.execute(
            """INSERT INTO doctors
               (id, medical_id, password, name, specialization, registration_id,
                clinic, working_hours, working_days, rating, experience,
                is_available, photo_url)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                "DR-PRIYA", "DR-PRIYA", "doctor123", "Dr. Priya Sharma",
                "General Physician", "MCI-78945612", "JeevanDoot Clinic",
                "9:00 AM \u2013 5:00 PM", "Monday to Saturday", "4.9", "8 yrs",
                1, DOCTOR_PHOTO,
            ),
        )

        # ---- Queue patients / cases -----------------------------------------
        # (id, patient_id, name, age, gender, symptoms, duration, severity,
        #  onset, vitals, consult_type, wait_minutes, history, status)
        cases = [
            {
                "id": "PT-9942", "name": "Rahul Kumar", "age": "54",
                "gender": "Male",
                "symptoms": ["Chest pain", "Shortness of breath", "Fever"],
                "duration": "2 hours", "severity": "Severe", "onset": "Sudden",
                "vitals": {"temp": "38.7", "hr": "102", "spo2": "94",
                           "bp": "138/90", "rr": "26", "glucose": "168",
                           "recorded_minutes_ago": 12},
                "consult_type": "Video Consultation", "wait_minutes": 18,
                "history": {
                    "conditions": "Hypertension (Diagnosed 2018)|Type 2 Diabetes (Diagnosed 2020)",
                    "allergies": "Penicillin (Mild rash)|Dust mites",
                    "medications": "Metformin 500mg (Daily)|Lisinopril 10mg (Daily)",
                    "consultations": "Routine Checkup \u2014 Dr. Sharma \u00b7 12 Oct 2023",
                },
                "status": "WAITING",
            },
            {
                "id": "PT-8876", "name": "Anil Verma", "age": "51",
                "gender": "Male",
                "symptoms": ["Difficulty breathing", "Mild cough"],
                "duration": "30 minutes", "severity": "Moderate", "onset": "Sudden",
                "vitals": {"temp": "37.5", "hr": "96", "spo2": "93",
                           "bp": "126/80", "rr": "22", "recorded_minutes_ago": 3},
                "consult_type": "Video Consultation", "wait_minutes": 6,
                "history": {
                    "conditions": "", "allergies": "",
                    "medications": "", "consultations": "",
                },
                "status": "WAITING",
            },
            {
                "id": "PT-88231", "name": "Priya Sharma", "age": "45",
                "gender": "Female",
                "symptoms": ["Severe abdominal pain"],
                "duration": "1 hour", "severity": "Severe", "onset": "Sudden",
                "vitals": {"temp": "37.9", "hr": "98", "spo2": "97",
                           "bp": "128/84", "rr": "18", "recorded_minutes_ago": 30},
                "consult_type": "Video Consultation", "wait_minutes": 42,
                "history": {
                    "conditions": "", "allergies": "",
                    "medications": "", "consultations": "",
                },
                "status": "WAITING",
            },
            {
                "id": "PT-7731", "name": "Amit Patel", "age": "45",
                "gender": "Male",
                "symptoms": ["Persistent cough", "Fatigue"],
                "duration": "1 week", "severity": "Moderate", "onset": "Gradual",
                "vitals": {"temp": "37.2", "hr": "88", "spo2": "96",
                           "bp": "132/88", "rr": "16", "recorded_minutes_ago": 20},
                "consult_type": "Video Consultation", "wait_minutes": 25,
                "history": {
                    "conditions": "", "allergies": "Dust mites",
                    "medications": "Cetirizine 10mg (As needed)",
                    "consultations": "",
                },
                "status": "WAITING",
            },
            {
                "id": "PT-9103", "name": "Kavita Singh", "age": "39",
                "gender": "Female",
                "symptoms": ["Persistent headache", "Body pain", "Fatigue"],
                "duration": "3 days", "severity": "Moderate", "onset": "Gradual",
                "vitals": {"temp": "37.6", "hr": "90", "spo2": "97",
                           "bp": "118/78", "rr": "17", "recorded_minutes_ago": 50},
                "consult_type": "Video Consultation", "wait_minutes": 55,
                "history": {
                    "conditions": "Migraine (Diagnosed 2015)", "allergies": "",
                    "medications": "", "consultations": "",
                },
                "status": "WAITING",
            },
            {
                "id": "PT-8492", "name": "Sunita Rao", "age": "28",
                "gender": "Female",
                "symptoms": ["Routine checkup", "Mild rash"],
                "duration": "3 days", "severity": "Mild", "onset": "Gradual",
                "vitals": {"temp": "36.8", "hr": "76", "spo2": "98",
                           "bp": "120/80", "rr": "14", "recorded_minutes_ago": 40},
                "consult_type": "Video Consultation", "wait_minutes": 45,
                "history": {
                    "conditions": "", "allergies": "",
                    "medications": "",
                    "consultations": "Routine Checkup \u2014 Dr. Sharma \u00b7 02 Aug 2026",
                },
                "status": "WAITING",
            },
            {
                "id": "PT-9214", "name": "Rajesh Verma", "age": "62",
                "gender": "Male",
                "symptoms": ["Mild rash", "Cold"],
                "duration": "2 days", "severity": "Mild", "onset": "Gradual",
                "vitals": {"temp": "36.7", "hr": "78", "spo2": "98",
                           "bp": "116/75", "rr": "15", "recorded_minutes_ago": 85},
                "consult_type": "Video Consultation", "wait_minutes": 90,
                "history": {
                    "conditions": "Mild arthritis", "allergies": "",
                    "medications": "", "consultations": "",
                },
                "status": "WAITING",
            },
            {
                "id": "PT-8555", "name": "Sneha Gupta", "age": "33",
                "gender": "Female",
                "symptoms": ["Fever", "Headache"],
                "duration": "1 day", "severity": "Mild", "onset": "Gradual",
                "vitals": {"temp": "38.2", "hr": "96", "spo2": "97",
                           "bp": "124/82", "rr": "18", "recorded_minutes_ago": 35},
                "consult_type": "Video Consultation", "wait_minutes": 40,
                "history": {
                    "conditions": "", "allergies": "",
                    "medications": "", "consultations": "",
                },
                "status": "IN_CONSULTATION",
            },
        ]

        queue_rows = []
        for case in cases:
            triage = compute_triage(
                case["symptoms"], vitals=case["vitals"], severity=case["severity"]
            )
            wait = case["wait_minutes"]
            recorded_at = iso(case["vitals"].get("recorded_minutes_ago", wait))
            conn.execute(
                """INSERT INTO queue_patients
                   (id, patient_id, name, age, gender, risk, risk_label,
                    symptoms, wait_minutes, consult_type, vitals_temp,
                    vitals_hr, vitals_spo2, vitals_bp, vitals_rr,
                    vitals_recorded_at, vitals_glucose,
                    history_conditions, history_allergies,
                    history_medications, history_consultations, ai_summary,
                    arrival_time, status, ai_risk_score, ai_triage_level,
                    ai_triage_reason, final_triage_level, triage_source,
                    triage_reason, doctor_override_reason, safety_escalated,
                    critical_symptoms, symptom_duration, symptom_severity,
                    symptom_onset, updated_at)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (
                    case["id"], case["id"], case["name"], case["age"],
                    case["gender"], "medium", "Medium Risk",
                    "|".join(case["symptoms"]), wait, case["consult_type"],
                    case["vitals"].get("temp"), case["vitals"].get("hr"),
                    case["vitals"].get("spo2"), case["vitals"].get("bp"),
                    case["vitals"].get("rr"),
                    recorded_at, case["vitals"].get("glucose"),
                    case["history"]["conditions"], case["history"]["allergies"],
                    case["history"]["medications"],
                    case["history"]["consultations"],
                    "AI-generated triage assessment for clinical review.",
                    iso(wait), case["status"],
                    triage["ai_risk_score"], triage["ai_triage_level"],
                    triage["ai_triage_reason"], triage["final_triage_level"],
                    triage["triage_source"], triage["triage_reason"], None,
                    1 if triage["safety_escalated"] else 0,
                    "|".join(triage["critical_symptoms"]),
                    case["duration"], case["severity"], case["onset"],
                    iso(0),
                ),
            )
            queue_rows.append((case["id"], case["id"], case["status"], wait))

        # ---- Pre-consultation case files --------------------------------------
        # Generated for every waiting patient so the doctor sees the full
        # clinical overview before the consultation begins.
        for qid, pid, status, wait in queue_rows:
            row = conn.execute(
                "SELECT * FROM queue_patients WHERE id = ?", (qid,)
            ).fetchone()
            data = dict(row)
            data["wait_minutes"] = wait
            data["wait_time"] = (
                f"{wait} min" if wait < 60
                else f"{wait // 60} hr {wait % 60} min"
            )
            payload = build_case_file_payload(data, None)
            generated = (now - timedelta(minutes=2)).isoformat()
            payload = upsert_case_file(conn, pid, data, payload,
                                       datetime.fromisoformat(generated))
            add_audit_log(conn, pid, "DR-PRIYA", "AI_SUMMARY_GENERATED",
                          {"mode": "auto"},
                          datetime.fromisoformat(generated))
            add_audit_log(conn, pid, "DR-PRIYA", "CASE_FILE_VIEWED", {},
                          datetime.fromisoformat(generated))

        # ---- Triage history (audit trail) ------------------------------------
        history = [
            ("PT-9942", "YELLOW", "RED", 58, "SAFETY_ESCALATION",
             "Difficulty breathing detected", "System", iso(14)),
            ("PT-9942", None, "YELLOW", 58, "AI",
             "Fever with chest discomfort warrants monitoring", "AI", iso(16)),
            ("PT-8876", "YELLOW", "RED", 51, "SAFETY_ESCALATION",
             "Difficulty breathing detected", "System", iso(4)),
            ("PT-8876", None, "YELLOW", 51, "AI",
             "Difficulty breathing reported", "AI", iso(5)),
            ("PT-88231", "YELLOW", "RED", 60, "SAFETY_ESCALATION",
             "Severe abdominal pain is a critical symptom", "System", iso(38)),
            ("PT-88231", None, "YELLOW", 60, "AI",
             "Severe abdominal pain warrants monitoring", "AI", iso(41)),
            ("PT-7731", None, "YELLOW", 41, "AI",
             "Persistent cough with fatigue; moderate severity", "AI", iso(23)),
            ("PT-9103", None, "YELLOW", 49, "AI",
             "Multiple symptoms reported; moderate severity", "AI", iso(52)),
            ("PT-8492", None, "GREEN", 12, "AI",
             "Mild symptoms reported; routine consultation advised", "AI", iso(43)),
            ("PT-9214", None, "GREEN", 20, "AI",
             "Mild symptoms reported; routine consultation advised", "AI", iso(87)),
            ("PT-8555", None, "GREEN", 35, "AI",
             "Mild symptoms reported; routine consultation advised", "AI", iso(38)),
        ]
        counters: dict = {}
        for h in history:
            pid, prev, new, score, source, reason, changed_by, created_at = h
            counters[pid] = counters.get(pid, 0) + 1
            conn.execute(
                """INSERT INTO triage_history
                   (id, patient_id, previous_level, new_level, risk_score,
                    source, reason, changed_by, created_at)
                   VALUES (?,?,?,?,?,?,?,?,?)""",
                (
                    f"TH-{pid.replace('PT-', '')}-{counters[pid]}",
                    pid, prev, new, score, source, reason, changed_by, created_at,
                ),
            )

        # ---- Appointments ------------------------------------------------------
        conn.executemany(
            """INSERT INTO appointments
               (id, patient_id, name, time, date_label, status, risk,
                risk_label, consult_type)
               VALUES (?,?,?,?,?,?,?,?,?)""",
            [
                ("APT-1", "PT-RAMESH", "Sunita Devi", "5:30 PM", "Today",
                 "Upcoming", "medium", "Medium Risk", "Video Consultation"),
                ("APT-2", "PT-RAMESH", "Ramesh Kumar", "4:00 PM", "Today",
                 "Completed", "low", "Low Risk", "In-Person Visit"),
                ("APT-3", "PT-RAMESH", "Rahul Kumar", "6:00 PM", "Tomorrow",
                 "Upcoming", "high", "High Risk", "Video Consultation"),
            ],
        )

        # ---- Sample prescription for Ramesh (issued, patient-visible) ----------
        rx_ts = iso(2)
        conn.execute(
            """INSERT INTO prescriptions
               (id, patient_id, doctor_id, doctor_name, status, date,
                issued_at, created_at, updated_at, notes)
               VALUES (?,?,?,?,?,?,?,?,?,?)""",
            (
                "RX-1001", "PT-RAMESH", "DR-PRIYA", "Dr. Priya Sharma",
                "ISSUED", "August 10, 2026", rx_ts, rx_ts, rx_ts,
                "Take after food. Drink plenty of water.",
            ),
        )
        conn.executemany(
            """INSERT INTO prescription_items
               (prescription_id, medicine_id, name, generic_name, strength,
                dosage_form, dose, frequency, duration, duration_unit, route,
                timing, instructions, display_order, category, dosage, unit,
                morning, afternoon, night, days)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            [
                ("RX-1001", 1, "Paracetamol", "Paracetamol", "650 mg",
                 "Tablet", "1 tablet", "Twice daily", "5", "days", "Oral",
                 "After food", "Take with water.", 1, "Analgesic", "650",
                 "mg", 1, 0, 1, 5),
                ("RX-1001", 7, "Azithromycin", "Azithromycin", "500 mg",
                 "Tablet", "1 tablet", "Once daily", "3", "days", "Oral",
                 "After food", "Take after food.", 2, "Antibiotic", "500",
                 "mg", 0, 1, 0, 3),
                ("RX-1001", 12, "Cough Syrup", "Dextromethorphan",
                 "100 ml", "Syrup", "10 ml", "Three times daily", "5",
                 "days", "Oral", "After food", "Shake well before use.",
                 3, "Cough suppressant", "10", "ml", 1, 1, 1, 5),
            ],
        )

        # ---- Records -------------------------------------------------------------
        conn.executemany(
            """INSERT INTO records (patient_id, date, type, title, detail)
               VALUES (?,?,?,?,?)""",
            [
                ("PT-RAMESH", "August 10, 2026", "Consultation",
                 "Consultation", "Dr. Priya Sharma"),
                ("PT-RAMESH", "August 05, 2026", "Prescription",
                 "Prescription", "Paracetamol 500mg"),
                ("PT-RAMESH", "July 28, 2026", "Consultation",
                 "Consultation", "Dr. Amit"),
            ],
        )

        # ---- Reminders ------------------------------------------------------------
        conn.executemany(
            """INSERT INTO reminders (id, patient_id, time, title, subtitle,
                                     icon, active, done)
               VALUES (?,?,?,?,?,?,?,?)""",
            [
                ("R-1", "PT-RAMESH", "8:00 AM", "Paracetamol",
                 "1 tablet \u2022 After Breakfast", "medication", 0, 1),
                ("R-2", "PT-RAMESH", "10:00 AM", "Doctor Follow-up",
                 "August 13 \u2022 Dr. Sharma Clinic", "event", 1, 0),
                ("R-3", "PT-RAMESH", "2:00 PM", "Hydration Goal",
                 "Drink 2 glasses of water", "water_drop", 0, 0),
            ],
        )

        conn.commit()
    finally:
        conn.close()
