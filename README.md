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

## Technology Stack
- **Frontend (Patient & Doctor Web Apps):** React
- **Backend / Database / Auth:** Firebase (or Supabase)
- **AI Triage Engine:** Rule-based risk scoring using a symptom-to-disease dataset (Kaggle)
- **Hosting/Deployment:** [Vercel]
- **Design:** UI designed in Google Stitch
- **Version Control:** Git & GitHub

*(Update this section with your team's final choices before submission.)*

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
├── src/
│   ├── patient/        # Patient app screens
│   ├── doctor/         # Doctor portal screens
│   ├── asha/           # ASHA worker app screens
│   ├── admin/          # Admin dashboard screens
│   ├── components/     # Shared UI components
│   ├── services/       # Firebase/API integration, triage logic
│   └── App.js
├── public/
├── .env
├── package.json
└── README.md
```
