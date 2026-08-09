"""Seed data for the JeevanDoot backend. Inserted only when the DB is empty."""
from .db import get_connection

PHOTO_URL = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBITWx9omukcrbVq6oHizm_c_NShTaHdvNkKnJrECbSRpr7IGAjxnk1ZhTpFpKFrISSu8EU6aQMFu8EtAfNk7uT1YxuwD6VvI0s7Iuvude1Sid0pMZud8RMdB32TFe-O7wgyA6so2ZcgfCvTFLv85JQB3USmyXjJZrDj7IEvE3mTQ7_mOzsUrWaRs2ymBwquFS663a1D0wCB5A1mCUgPyZCzDch-rNqxdGpXExzPzNqXNiOKTFq6mFJ"
)

DOCTOR_PHOTO = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuB4o1TFkvIyoFzAWoEO7eNeqCED0RPxkF3vQn-UAcVhDfjtyDZ6Iu7vfKm5WAAXLCaGOWnk6iGiYo7XSMqqFY2uTYpvojScUEFbG5JCF6WvJiAkpeTIomPDJ-DQJd2O5h9OJBpnLMQZNjgywHahoWsdH2L2wN1kDDJkNlhLSRpTx5akNa83Pk0VLLzzhlV_SN7Rm7-e5xdWKKM4cmoKDrQSSeeNEIiwNyngUR665ByPRI_HQgrJJOGx"
)

PATIENT_PHOTO = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBITWx9omukcrbVq6oHizm_c_NShTaHdvNkKnJrECbSRpr7IGAjxnk1ZhTpFpKFrISSu8EU6aQMFu8EtAfNk7uT1YxuwD6VvI0s7Iuvude1Sid0pMZud8RMdB32TFe-O7wgyA6so2ZcgfCvTFLv85JQB3USmyXjJZrDj7IEvE3mTQ7_mOzsUrWaRs2ymBwquFS663a1D0wCB5A1mCUgPyZCzDch-rNqxdGpXExzPzNqXNiOKTFq6mFJ"
)

DOCTOR_AVATAR = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBRpkLjw4XTt-Fx7OI2_by2-JuBIgGXPLNw_WUdhJ8FDLaIl2Z033bZhYKoBRa_lnS9SkYjDRx4wfAshBObaf2yMYEHF24EU-YRphCc7aRvhP6gKXj1jc2Y-mrsbU4C4SFPoG9VyiKwMLMRdWTp705NmqmBpSAiN334oMixaqPDk396MegKMmbRzPJBU0n6lOHjWleVegy5GztvbP1pfpSfRFbhv8eEuBv9F4f4cBJB1A80k0IASN0"
)

CASE_PHOTO = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuB5nJ6HtadHMK8_AadQieVOrJuXZTTLUQrhoc1_IDFLLoWqrrDC1fGp9BAaW2lDpyE7iTMKOfnx6f3Cd4HA7m5y2NGiB4JAgetWtYTm1lIOIGR92bLQ-ZyrMkxgIEvyuMlX2eMHA4ZwXFwE1oXKM5IuCFmyIi4Vuz68kUcit-eDYKUscurmcsfI0XFLBRTAm6Koz5afuy46zR6a9GyRCrfpeaYJ7BbXBMDAVJ9fAybtyQcnD19AehU"
)

# Additional teleconsultation doctors (id, medical_id, password, name,
# specialization, registration_id, clinic, working_hours, working_days,
# rating, experience, is_available, photo_url, qualification, languages, fee)
TELECONSULT_DOCTORS = [
    (
        "DR-PRIYA", "DR-PRIYA", "doctor123", "Dr. Priya Sharma",
        "General Physician", "MCI-78945612", "JeevanDoot Clinic",
        "9:00 AM \u2013 8:30 PM", "Monday to Saturday", "4.9", "8 yrs",
        1, DOCTOR_PHOTO, "MBBS, MD", "Hindi \u2022 Marathi \u2022 English", 399,
    ),
    (
        "DR-ANIL", "DR-ANIL", "doctor123", "Dr. Anil Deshmukh",
        "Pediatrics", "MCI-45871239", "JeevanDoot Clinic",
        "9:00 AM \u2013 8:30 PM", "Monday to Saturday", "4.8", "12 yrs",
        1, DOCTOR_AVATAR, "MBBS, DCH", "Hindi \u2022 English", 349,
    ),
    (
        "DR-MEERA", "DR-MEERA", "doctor123", "Dr. Meera Nair",
        "Gynecology", "MCI-65231478", "JeevanDoot Clinic",
        "9:00 AM \u2013 8:30 PM", "Monday to Saturday", "4.9", "15 yrs",
        1, PATIENT_PHOTO, "MBBS, MS (OBG)", "English \u2022 Hindi \u2022 Malayalam", 449,
    ),
    (
        "DR-KAVITA", "DR-KAVITA", "doctor123", "Dr. Kavita Joshi",
        "Dermatology", "MCI-96325874", "JeevanDoot Clinic",
        "9:00 AM \u2013 8:30 PM", "Monday to Saturday", "4.7", "9 yrs",
        1, CASE_PHOTO, "MBBS, MD (DVL)", "Hindi \u2022 English \u2022 Marathi", 399,
    ),
    (
        "DR-RAJESH", "DR-RAJESH", "doctor123", "Dr. Rajesh Iyer",
        "Cardiology", "MCI-35795146", "JeevanDoot Clinic",
        "9:00 AM \u2013 8:30 PM", "Monday to Saturday", "4.8", "18 yrs",
        1, DOCTOR_PHOTO, "MBBS, DM (Cardiology)", "English \u2022 Hindi \u2022 Tamil", 599,
    ),
    (
        "DR-SANA", "DR-SANA", "doctor123", "Dr. Sana Khan",
        "Mental Health", "MCI-14725836", "JeevanDoot Clinic",
        "9:00 AM \u2013 8:30 PM", "Monday to Saturday", "4.6", "7 yrs",
        1, DOCTOR_AVATAR, "MBBS, MD (Psychiatry)", "Hindi \u2022 English \u2022 Urdu", 449,
    ),
]

# Slot windows used to generate availability: (start, end, period label).
SLOT_WINDOWS = [
    ("09:00", "12:30", "Morning"),
    ("13:30", "17:00", "Afternoon"),
    ("17:30", "20:30", "Evening"),
]


def row_to_dict(conn, table, key_col, key):
    cur = conn.execute(f'SELECT * FROM {table} WHERE {key_col} = ?', (key,))
    row = cur.fetchone()
    return dict(row) if row else None


def count(conn, table):
    return conn.execute(f"SELECT COUNT(*) AS c FROM {table}").fetchone()["c"]


def _insert_teleconsult_doctors(conn) -> None:
    """Insert teleconsultation doctors that are missing, and refresh the
    display metadata (qualification, languages, fee, photo, hours) of any
    doctor already present from an older seed. Idempotent."""
    existing = {r["id"] for r in conn.execute("SELECT id FROM doctors").fetchall()}
    for row in TELECONSULT_DOCTORS:
        if row[0] not in existing:
            conn.execute(
                """INSERT INTO doctors
                   (id, medical_id, password, name, specialization, registration_id,
                    clinic, working_hours, working_days, rating, experience,
                    is_available, photo_url, qualification, languages,
                    consultation_fee)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                row,
            )
            continue
        # Tuple layout: (id, medical_id, password, name, specialization,
        # registration_id, clinic, working_hours, working_days, rating,
        # experience, is_available, photo_url, qualification, languages, fee)
        conn.execute(
            """UPDATE doctors SET
                 name = ?, specialization = ?, working_hours = ?, rating = ?,
                 experience = ?, is_available = ?, photo_url = ?,
                 qualification = ?, languages = ?, consultation_fee = ?
               WHERE id = ?""",
            (
                row[3], row[4], row[7], row[9], row[10], row[11], row[12],
                row[13], row[14], row[15], row[0],
            ),
        )


def _seed_availability(conn, days: int = 14) -> None:
    """Generate 30-minute availability slots for every active doctor."""
    from datetime import date, timedelta

    doctors = conn.execute(
        "SELECT id FROM doctors WHERE is_available = 1"
    ).fetchall()
    today = date.today()
    for d in range(days):
        day = today + timedelta(days=d)
        if day.weekday() == 6:  # Sundays off
            continue
        for start, end, _period in SLOT_WINDOWS:
            cur = _hhmm_to_min(start)
            end_min = _hhmm_to_min(end)
            while cur < end_min:
                s = _min_to_hhmm(cur)
                e = _min_to_hhmm(cur + 30)
                for doc in doctors:
                    conn.execute(
                        """INSERT OR IGNORE INTO doctor_availability
                           (doctor_id, date, start_time, end_time, slot_duration, status)
                           VALUES (?,?,?,?,?, 'available')""",
                        (doc["id"], day.isoformat(), s, e, 30),
                    )
                cur += 30


def _hhmm_to_min(hhmm: str) -> int:
    h, m = (int(x) for x in hhmm.split(":"))
    return h * 60 + m


def _min_to_hhmm(mins: int) -> str:
    return f"{mins // 60:02d}:{mins % 60:02d}"


def seed_teleconsultation() -> None:
    """Idempotently seed doctors + availability. Runs on every startup so
    databases created before this feature also receive the new data."""
    from datetime import date, timedelta

    conn = get_connection()
    try:
        _insert_teleconsult_doctors(conn)
        # Only generate availability when it is missing for the near future.
        tomorrow = (date.today() + timedelta(days=1)).isoformat()
        has = conn.execute(
            "SELECT COUNT(*) AS c FROM doctor_availability WHERE date = ?",
            (tomorrow,),
        ).fetchone()["c"]
        if has == 0:
            _seed_availability(conn)
        _seed_prescription_details(conn)
        conn.commit()
    finally:
        conn.close()


def _seed_prescription_details(conn) -> None:
    """Back-fill richer prescription metadata for the demo prescription
    (ISO date, follow-up, varied food instructions). Idempotent."""
    conn.execute(
        """UPDATE prescriptions SET date_iso = '2026-08-10',
               follow_up_date = '2026-08-12', follow_up_time = '10:00 AM'
           WHERE id = 'RX-1001' AND date_iso IS NULL"""
    )
    conn.execute(
        """UPDATE prescription_items SET instructions = 'Before food'
           WHERE prescription_id = 'RX-1001' AND name = 'Azithromycin'
             AND instructions IN ('After food', '')"""
    )


def seed_if_empty() -> None:
    conn = get_connection()
    try:
        if count(conn, "patients") > 0:
            return

        # ---- Patients -------------------------------------------------------
        patients = [
            (
                "PT-RAMESH", "9876543210", "Ramesh Kumar", "42", "Male", "O+",
                "ramesh.kumar@example.com", "Shop 12, MG Road, Pune, Maharashtra",
                "12 August 1983", "XXXX-XXXX-1234", "hi", PHOTO_URL,
                "Peanuts, Penicillin", "Mild hypertension", "168 cm", "74 kg",
                "Amlodipine 5 mg (daily)",
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
        queue = [
            (
                "PT-9942", "PT-9942", "Rahul Kumar", "54", "Male", "high", "High Risk",
                "Fever|Breathing difficulty|Chest discomfort", 4,
                "Video Consultation", "38.7", "102", "94", "138/90",
                "Hypertension (Diagnosed 2018)|Type 2 Diabetes (Diagnosed 2020)",
                "Penicillin (Mild rash)|Dust mites",
                "Metformin 500mg (Daily)|Lisinopril 10mg (Daily)",
                "Routine Checkup \u2014 Dr. Sharma \u00b7 12 Oct 2023",
                "Patient-reported symptoms indicate that urgent clinical evaluation may be appropriate.",
            ),
            (
                "PT-88231", "PT-88231", "Priya Sharma", "45", "Female", "high", "High Risk",
                "Severe abdominal pain", 12, "Video Consultation",
                "37.9", "98", "97", "128/84",
                "None", "None",
                "None", "None",
                "Patient reports severe abdominal pain that may require clinical evaluation.",
            ),
            (
                "PT-7731", "PT-7731", "Amit Patel", "45", "Male", "medium", "Medium",
                "Persistent cough|Fatigue", 25, "Video Consultation",
                "37.2", "88", "96", "132/88",
                "None", "Dust mites",
                "Cetirizine 10mg (As needed)", "None",
                "Patient-reported symptoms warrant monitoring and clinical review.",
            ),
            (
                "PT-8492", "PT-8492", "Sunita Rao", "28", "Female", "low", "Low",
                "Routine checkup|Mild rash", 45, "Video Consultation",
                "36.8", "76", "98", "120/80",
                "None", "None",
                "None", "Routine Checkup \u2014 Dr. Sharma \u00b7 02 Aug 2026",
                "Low-risk presentation. Routine evaluation recommended.",
            ),
        ]
        conn.executemany(
            """INSERT INTO queue_patients
               (id, patient_id, name, age, gender, risk, risk_label, symptoms,
                wait_minutes, consult_type, vitals_temp, vitals_hr, vitals_spo2,
                vitals_bp, history_conditions, history_allergies,
                history_medications, history_consultations, ai_summary)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            queue,
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

        # ---- Medicines ---------------------------------------------------------
        medicines = [
            "Paracetamol", "Amoxicillin", "Azithromycin", "Cetirizine",
            "Metformin", "Lisinopril", "Ibuprofen", "Cough Syrup",
            "Amlodipine", "Pantoprazole", "Vitamin D3", "ORS Powder",
            "Chlorpheniramine", "Diclofenac", "Ranitidine", "Aspirin",
        ]
        conn.executemany(
            "INSERT INTO medicines (name, category) VALUES (?, 'Tablet')",
            [(m,) for m in medicines],
        )

        # ---- Sample prescription for Ramesh ------------------------------------
        conn.execute(
            """INSERT INTO prescriptions
               (id, patient_id, doctor_name, date, notes)
               VALUES (?,?,?,?,?)""",
            (
                "RX-1001", "PT-RAMESH", "Dr. Priya Sharma", "August 10, 2026",
                "Take after food. Drink plenty of water.",
            ),
        )
        conn.executemany(
            """INSERT INTO prescription_items
               (prescription_id, name, category, dosage, unit, morning,
                afternoon, night, days, instructions)
               VALUES (?,?,?,?,?,?,?,?,?,?)""",
            [
                ("RX-1001", "Paracetamol", "Tablet", "650", "mg", 1, 0, 1, 5, "After food"),
                ("RX-1001", "Azithromycin", "Tablet", "500", "mg", 0, 1, 0, 3, "After food"),
                ("RX-1001", "Cough Syrup", "Syrup", "10", "ml", 1, 1, 1, 5, "After food"),
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
