"""Seed data for the JeevanDoot backend. Inserted only when the DB is empty."""
from .db import get_connection

PHOTO_URL = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBITWx9omukcrbVq6oHizm_c_NShTaHdvNkKnJrECbSRpr7IGAjxnk1ZhTpFpKFrISSu8EU6aQMFu8EtAfNk7uT1YxuwD6VvI0s7Iuvude1Sid0pMZud8RMdB32TFe-O7wgyA6so2ZcgfCvTFLv85JQB3USmyXjJZrDj7IEvE3mTQ7_mOzsUrWaRs2ymBwquFS663a1D0wCB5A1mCUgPyZCzDch-rNqxdGpXExzPzNqXNiOKTFq6mFJ"
)

DOCTOR_PHOTO = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuB4o1TFkvIyoFzAWoEO7eNeqCED0RPxkF3vQn-UAcVhDfjtyDZ6Iu7vfKm5WAAXLCaGOWnk6iGiYo7XSMqqFY2uTYpvojScUEFbG5JCF6WvJiAkpeTIomPDJ-DQJd2O5h9OJBpnLMQZNjgywHahoWsdH2L2wN1kDDJkNlhLSRpTx5akNa83Pk0VLLzzhlV_SN7Rm7-e5xdWKKM4cmoKDrQSSeeNEIiwNyngUR665ByPRI_HQgrJJOGx"
)


def row_to_dict(conn, table, key_col, key):
    cur = conn.execute(f'SELECT * FROM {table} WHERE {key_col} = ?', (key,))
    row = cur.fetchone()
    return dict(row) if row else None


def count(conn, table):
    return conn.execute(f"SELECT COUNT(*) AS c FROM {table}").fetchone()["c"]


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
