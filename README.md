# JeevanDoot — A Messenger of Life

## Team Name
**Coderss**

## Problem Statement
Rural India cannot reach a doctor. 65% of the rural population lacks healthcare facilities within a 5 km radius, the doctor-to-patient ratio stands at roughly 1:10,926 against the WHO standard of 1:1,000, and 70% of chronic diseases are diagnosed only at advanced stages due to the absence of screening infrastructure. Poor connectivity, low literacy, doctor shortages, and low health awareness compound this structural gap between cities and the villages healthcare should serve.

## Solution Overview
JeevanDoot delivers doorstep care powered by a phone and a neighbour. It decentralizes healthcare using mobile technology, AI-driven triage, and community health workers (ASHA) instead of relying on hospitals and expensive devices.

The platform follows a **2·2·24 service commitment**:
- **2 km** — a healthcare touchpoint within reach, eliminating the travel barrier
- **2 hrs** — AI-driven diagnosis/triage within 2 hours for rapid action
- **24 hrs** — physician consultation within 24 hours, closing the care loop

**How it works:** A patient reports symptoms via voice or icon-based input → an AI triage engine assigns a risk score (Low / Medium / High) → low-risk cases receive self-care advice, high-risk cases are referred to the nearest hospital, and medium-risk cases are routed to a doctor for teleconsultation → the doctor reviews an AI-generated case summary, consults the patient, and issues a prescription or escalates the case → outcomes sync back to the patient's app, with ASHA workers assisting patients who are illiterate or lack smartphone access, and an admin dashboard providing population-level health insights.

This cuts diagnosis delays by an estimated 70%, prevents disease progression, lowers costs in low-resource settings, and contributes toward SDG-3 (Good Health & Well-being).

## Live Demonstration Link
[https://jeevan-doot-web-hack-matrix2026.vercel.app/](https://jeevan-doot-web-hack-matrix2026.vercel.app/)

## PPT View Link
[https://canva.link/htdd08m6nuo54cu](https://canva.link/htdd08m6nuo54cu)

## Gdrive Link
[https://drive.google.com/drive/folders/166uIxlPLm6EJae5JjSQJ_HmSMUDP1GB6?usp=drive_link](https://drive.google.com/drive/folders/166uIxlPLm6EJae5JjSQJ_HmSMUDP1GB6?usp=drive_link)

## Technology Stack
- **Frontend (Patient & Doctor Web Apps):** React
- **Backend / Database / Auth:** Firebase (or Supabase)
- **AI Triage Engine:** Rule-based risk scoring using a symptom-to-disease dataset (Kaggle)
- **Hosting/Deployment:** [Vercel]
- **Design:** UI designed in Google Stitch
- **Version Control:** Git & GitHub

## Team Members
1. Srushti Dedaniya
2. Aanchal Jain
3. Vrunda Shah
4. Harsh Gahankar

## Setup Instructions

### Prerequisites
- Node.js (v18 or higher)
- npm or yarn
- A Firebase (or Supabase) project set up with your own API keys

### Installation
```bash
# Clone the repository
git clone https://github.com/Aanchal1496/JeevanDoot-HackMatrix2026.git
cd jeevandoot

# Install dependencies
npm install
```

### Running Locally
```bash
npm start
```
The app will run locally at `http://localhost:3000`

### Building for Production
```bash
npm run build
```

### Project Structure
```
jeevandoot/
├── render.yaml                        # Render blueprint (deploy config)
├── README.md
├── FEATURE_STATUS.md
├── .gitignore
│
├── backend/                           # FastAPI backend
│   ├── Procfile                       # web: uvicorn app.main:app
│   ├── requirements.txt
│   ├── .env.example
│   ├── .gitignore
│   ├── server.err
│   ├── server.out
│   ├── app/
│   │   ├── main.py                    # FastAPI entry
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models.py
│   │   ├── schemas.py
│   │   ├── migrations.py
│   │   ├── seed.py
│   │   ├── analysis.py
│   │   ├── audit.py
│   │   ├── auth.py
│   │   ├── normalizer.py
│   │   ├── notifications.py
│   │   ├── __init__.py
│   │   └── routers/
│   │       ├── appointments.py
│   │       ├── asha.py
│   │       ├── auth.py
│   │       ├── consultations.py
│   │       ├── demo.py
│   │       ├── doctors.py
│   │       ├── family.py
│   │       ├── followups.py
│   │       ├── notifications.py
│   │       ├── patients.py
│   │       ├── prescriptions.py
│   │       ├── referrals.py
│   │       ├── triage.py
│   │       └── __init__.py
│   └── tests/
│       ├── conftest.py
│       ├── test_analysis.py
│       ├── test_flows.py
│       └── __init__.py
│
└── jeevandoot/                        # Flutter app
    ├── pubspec.yaml
    ├── analysis_options.yaml
    ├── .metadata
    ├── README.md
    ├── lib/
    │   ├── main.dart
    │   ├── constants.dart
    │   ├── api/
    │   │   ├── api_client.dart
    │   │   ├── asha_service.dart
    │   │   ├── auth_service.dart
    │   │   ├── doctor_service.dart
    │   │   ├── patient_service.dart
    │   │   └── symptom_service.dart
    │   ├── l10n/
    │   │   └── app_strings.dart
    │   ├── models/
    │   │   ├── models.dart
    │   │   └── doctor_models.dart
    │   ├── screens/
    │   │   ├── asha/
    │   │   │   ├── asha_assignment_detail_screen.dart
    │   │   │   └── asha_home_screen.dart
    │   │   ├── doctor/
    │   │   │   ├── doctor_ai_suggested_questions_screen.dart
    │   │   │   ├── doctor_appointments_screen.dart
    │   │   │   ├── doctor_availability_screen.dart
    │   │   │   ├── doctor_consultation_info_panel_screen.dart
    │   │   │   ├── doctor_consultation_notes_screen.dart
│   │   │   ├── doctor_consult_tab.dart
│   │   │   ├── doctor_home_screen.dart
│   │   │   ├── doctor_new_prescription_screen.dart
│   │   │   ├── doctor_patient_case_screen.dart
│   │   │   ├── doctor_patient_queue_screen.dart
│   │   │   ├── doctor_prescription_preview_screen.dart
│   │   │   ├── doctor_pre_check_screen.dart
│   │   │   ├── doctor_profile_screen.dart
│   │   │   ├── doctor_referral_screen.dart
│   │   │   ├── doctor_schedule_screen.dart
│   │   │   ├── doctor_symptom_timeline_screen.dart
│   │   │   └── doctor_video_consult_screen.dart
│   │   ├── appointment_confirmation_screen.dart
│   │   ├── book_consultation_screen.dart
│   │   ├── family_members_screen.dart
│   │   ├── home_screen.dart
│   │   ├── language_selection_screen.dart
│   │   ├── listening_screen.dart
│   │   ├── login_screen.dart
│   │   ├── my_appointments_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── offline_screen.dart
│   │   ├── prescription_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── profile_settings.dart
│   │   ├── records_screen.dart
│   │   ├── reminders_screen.dart
│   │   ├── self_care_advice_screen.dart
│   │   ├── splash_screen.dart
│   │   ├── symptom_checker_screen.dart
│   │   ├── triage_result_screen.dart
│   │   └── video_call_screen.dart
│   ├── services/
│   │   └── sync_queue.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       ├── app_top_bar.dart
│       ├── bottom_nav.dart
│       ├── common.dart
│       └── doctor_bottom_nav.dart
    └── test/
```
