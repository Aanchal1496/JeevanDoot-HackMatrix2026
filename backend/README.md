# JeevanDoot Backend

Python (FastAPI) backend for the JeevanDoot Flutter app. Data is stored in a
local SQLite database (`app/jeevandoot.db`) that is auto-created and seeded on
first startup.

## Quick start (Windows)

```bat
run.bat
```

Or manually:

```powershell
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API docs: http://localhost:8000/docs

The Flutter app targets `http://localhost:8000` by default. If you run the
backend on a different host/port, override the base URL when launching the app:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8020
```

## Demo credentials

| Role | Identifier | Password |
| ---- | ---------- | -------- |
| Patient | Any 10-digit mobile (e.g. `9876543210`) | OTP `123456` |
| Doctor | `DR-PRIYA` | `doctor123` |

## Endpoints

| Method | Path | Description |
| ------ | ---- | ----------- |
| POST | `/api/auth/request-otp` | Sends demo OTP for a phone number |
| POST | `/api/auth/verify-otp` | Verifies OTP, returns token + patient profile |
| POST | `/api/auth/doctor-login` | Doctor login, returns token + doctor profile |
| POST | `/api/auth/logout?token=...` | Invalidates a token |
| POST | `/api/triage` | Rule-based triage from symptom ids |
| GET | `/api/self-care` | Self-care advice list |
| GET | `/api/appointments/slots` | Available dates + time slots |
| POST | `/api/appointments` | Book an appointment |
| GET | `/api/appointments/mine?patient_id=...` | Patient's appointments |
| GET | `/api/doctor/queue` | Risk-sorted queue (RED→YELLOW→GREEN) + summary counts |
| GET | `/api/doctor/patients` | Flat risk-sorted list of active patients |
| GET | `/api/doctor/patients/{id}` | Full patient case (triage, vitals, history, triage history) |
| GET | `/api/doctor/patients/{id}/case-file` | **Pre-consultation case file** (aggregated: summary, history, vitals, risk, flags, insights) — requires doctor Bearer token |
| POST | `/api/doctor/patients/{id}/case-file/generate` | Regenerate the case file from latest data (preserves doctor edits) |
| PATCH | `/api/doctor/patients/{id}/case-file/summary` | Save doctor-edited summary (original AI content preserved, audit logged) |
| POST | `/api/doctor/patients/{id}/triage/override` | Doctor triage override (records audit entry) |
| POST | `/api/doctor/patients/{id}/consultation/start` | WAITING → IN_CONSULTATION |
| POST | `/api/doctor/patients/{id}/consultation/complete` | IN_CONSULTATION → COMPLETED |
| GET | `/api/doctor/appointments` | Doctor's schedule |
| GET | `/api/doctor/stats` | Dashboard stats / urgent case / next consultation |
| GET | `/api/doctor/medicines?q=...` | Structured medicine catalog search (generic/brand/category/strength) |
| GET | `/api/doctor/medicines/common` | Configurable common-medicine quick-select set |
| POST | `/api/doctor/prescriptions` | Create (or reopen) a prescription draft for a patient |
| GET | `/api/doctor/prescriptions/{id}` | Fetch a prescription (review) |
| GET | `/api/doctor/prescriptions/drafts?patient_id=...` | Recover the patient's unfinished draft (404 if none) |
| GET | `/api/doctor/prescriptions/history?patient_id=...` | Issued prescription history (doctor view) |
| POST | `/api/doctor/prescriptions/{id}/items` | Add a medicine with dose/frequency/duration/route/timing/instructions; returns safety warnings (allergy / duplicate) |
| PATCH | `/api/doctor/prescriptions/{id}/items/{item_id}` | Update an item on a draft |
| DELETE | `/api/doctor/prescriptions/{id}/items/{item_id}` | Remove an item from a draft |
| PATCH | `/api/doctor/prescriptions/{id}/notes` | Autosave additional instructions (never issues) |
| POST | `/api/doctor/prescriptions/{id}/issue` | Issue the prescription (server revalidates everything; DRAFT → ISSUED) |
| GET | `/api/doctor/prescriptions/{id}/pdf` | Authenticated prescription PDF (reportlab) |
| GET | `/api/prescriptions?patient_id=...` | Patient's prescriptions (**ISSUED only**, never drafts) |
| POST | `/api/prescriptions` | Create a prescription (legacy patient-facing) |
| GET/PUT | `/api/profile?patient_id=...` | Read / update patient profile |
| GET | `/api/records?patient_id=...` | Patient records |
| GET | `/api/reminders?patient_id=...` | Patient reminders |
| POST | `/api/reminders/{id}/done` | Mark reminder done |

## Tests

```
python -m pytest tests/ -v
```

Covers triage level boundaries (85→RED, 55→YELLOW, 25→GREEN), safety
escalation, queue ordering (level → risk score → wait time), determinism, the
doctor-override contract, the pre-consultation case file (vital
interpretation, symptom extraction, no-fabrication rules, empty states,
doctor-edit preservation, risk propagation and auth 401/403), and the
prescription writer (add medicine, quick-select semantics, medicine search,
allergy flag, duplicate detection, draft recovery, review, issue, edit-after-
issue blocked, patient sees only ISSUED, PDF bytes, audit events).

## Notes

- The queue sorts on the backend: `RED > YELLOW > GREEN`, then highest risk
  score, then longest wait. Waiting time is derived from `arrival_time` and
  never stored.
- Triage is an assistive clinical decision-support feature; the UI always
  shows the AI's original assessment and every change is written to the
  `triage_history` audit table.
- The pre-consultation case file is an aggregated single-request endpoint
  (no N+1 page loads). Vital thresholds live only in `app/vitals.py`;
  symptom extraction, AI summary and flags are in `app/casefile.py` and never
  fabricate unreported clinical detail. Case-file actions are recorded in the
  `case_file_audit_log` table (`CASE_FILE_VIEWED`, `AI_SUMMARY_GENERATED`,
  `SUMMARY_EDITED`, `VITALS_UPDATED`, `RISK_UPDATED`).
- The prescription writer is a documentation/workflow tool, **not** an
  autonomous prescriber: quick-select only pre-fills the medicine form, every
  item must be explicitly configured and confirmed, only the issuing endpoint
  moves DRAFT → ISSUED, and issued prescriptions are immutable (edit blocked,
  never deleted). Safety checks are conservative: allergy conflicts are
  flagged for professional review (never blocking), duplicates are warned
  (never merged), and no drug-interaction claims are invented — interactions
  surface as "safety check unavailable". The medicine catalog, quick-select
  set and all thresholds are backend-configurable. Medicine snapshots are
  stored per item so history stays accurate. Prescription actions are audited
  in `prescription_audit_log` (`DRAFT_CREATED`, `MEDICINE_ADDED`,
  `MEDICINE_UPDATED`, `MEDICINE_REMOVED`, `PRESCRIPTION_REVIEWED`,
  `PRESCRIPTION_ISSUED`, `PRESCRIPTION_CANCELLED`,
  `PRESCRIPTION_SUPERSEDED`). PDFs require the doctor Bearer token.
- CORS is wide open for development; tighten before production.
- Auth tokens are stored in SQLite for demo purposes. OTP is a static
  `123456` — replace with a real SMS provider before production.
