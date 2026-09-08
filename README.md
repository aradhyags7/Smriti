# SMRITI (स्मृति / সোঁৱৰণি)
### AI-Powered, Offline-First Cognitive Care Platform for Elderly Dementia & MCI Care
*Tailored for India's North Eastern Region (NER) and Rural Healthcare Networks*

---

[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python&logoColor=white)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Tests: Pytest & Flutter](https://img.shields.io/badge/Tests-87%20Backend%20%7C%20323%20Flutter%20Passing-brightgreen)](tests/)

---

## 📌 Executive Summary

**SMRITI** is an assistive healthcare platform engineered to bridge the critical dementia care gap in rural and semi-urban communities—with dedicated focus on India's North Eastern Region (NER). 

Due to geographic isolation, limited geriatric neurology infrastructure, and intermittent internet connectivity, early signs of Mild Cognitive Impairment (MCI) and Alzheimer's disease frequently go undetected until advanced stages. SMRITI delivers an **offline-first**, **voice-driven**, and **culturally contextualized** ecosystem connecting:
1. **Elderly Patients**: Engaging daily Cognitive Stimulation Therapy (CST), voice-first check-ins, medication reminders, and reminiscence therapy in their native languages.
2. **Family Caregivers**: Remote activity adherence, cognitive progression tracking, mood patterns, and early-warning alerts.
3. **ASHA (Accredited Social Health Activist) Healthcare Workers**: Village-level triaging, risk stratification, and consent-gated clinical intervention support.

---

## 🌟 Key Features

### 🗣️ 1. Multilingual & Regional Language Support
- Fully localized UI and voice support across **6 languages**:
  - **অসমীয়া (Assamese)**
  - **বাংলা (Bengali)**
  - **মৈতৈলোন্ (Manipuri)**
  - **Mizo ṭawng (Mizo)**
  - **Nagamese**
  - **English**
- Elder-accessible typography, high-contrast visual cues, and large touch targets designed for reduced dexterity.

### 🎙️ 2. Multilingual Voice Assistant
- Integrated hands-free speech recognition (STT) and voice feedback (TTS).
- Conversational daily check-ins, medication guidance, and reminiscence prompts tailored for elderly individuals who struggle with text-heavy interfaces.

### 🧩 3. Adaptive Cognitive Stimulation Therapy (CST) Games
- Clinically guided mini-games:
  - **Pattern Matching** (Visual & spatial memory)
  - **Word Recall & Association** (Semantic processing)
  - **Sequence & Number Memory** (Working memory)
  - **Reminiscence Photo Prompts** (Long-term episodic retrieval)
- **Dynamic Difficulty Adaptation**: Tasks adjust in real time based on user response latency, error rates, and historical baseline scores.

### 👤 4. First-Time Patient Health Onboarding
- Guided initial profile calibration capturing:
  - **Age & Gender**
  - **Dementia Subtype Classification**:
    - Alzheimer’s disease
    - Vascular dementia
    - Lewy body dementia
    - Frontotemporal dementia (FTD)
    - Mixed dementia
    - Other / unspecified
- Automatically reflects on connected Caregiver and ASHA Worker triage screens.

### 👥 5. Tripartite Role Ecosystem
- **Patient Mode**: Simple, reassuring interface with daily schedule, voice assistant, games, reminders, and nostalgic reminiscence audio/visual gallery.
- **Caregiver Dashboard**: Longitudinal cognitive score charts, missed medication alerts, activity logs, and ability to schedule reminders and upload family memories.
- **ASHA Worker Portal**: Village registry overview, risk-stratified patient cards, adherence compliance rates, and consent-gated decline alerts for community healthcare visits.

### 🧠 6. AI Early-Warning & Longitudinal Intelligence Engine
- **Baseline Scoring**: Computes moving average cognitive performance baselines across cognitive domains.
- **Decline Detection**: Linear regression and moving window analysis flagging statistically significant drops in accuracy or spikes in reaction time.
- **Consent-Gated Alerts**: Automatic generation of high-priority clinical review alerts for caregivers and ASHA workers when risk thresholds are breached.

### 🔄 7. Robust Offline-First Outbox Synchronization
- Complete local functionality powered by on-device SQLite.
- Queues events (game sessions, medication logs, symptom reports) in a durable local Outbox.
- Bidirectional background sync engine automatically reconciles records upon network restoration with deterministic timestamp conflict resolution.

### 🔐 8. Zero-Firebase Direct Google OAuth & JWT Authentication
- Clean, direct Google Sign-In verification via google-auth library against Google Tokeninfo v3.
- Preserves native FastAPI JWT token lifecycle, SQLite/PostgreSQL user persistence, and avoids heavy Firebase SDK bloat.
- Strict 409 conflict detection preventing accidental account collisions with pre-existing email/password accounts.

---

## 🏛️ System Architecture

`
                    ┌──────────────────────────────────────────────┐
                    │               SMRITI FLUTTER APP             │
                    │   (Mobile Client - Android / iOS / Web)      │
                    └──────────────────────┬───────────────────────┘
                                           │
                ┌──────────────────────────┴──────────────────────────┐
                ▼                                                     ▼
     ┌───────────────────────┐                             ┌──────────────────────┐
     │   Local SQLite DB     │                             │  Network Layer       │
     │  - Session Storage    │                             │  - Dio / Http Client │
     │  - Reminiscence Cache │                             │  - Auth Interceptor  │
     │  - Offline Outbox     │                             │  - Offline Detector  │
     └──────────┬────────────┘                             └──────────┬───────────┘
                │                                                     │
                └──────────────────────────┬──────────────────────────┘
                                           │ HTTPS / REST (or Outbox Sync)
                                           ▼
                    ┌──────────────────────────────────────────────┐
                    │               FASTAPI BACKEND                │
                    │    (Python 3.11+ / Uvicorn / SQLAlchemy)    │
                    └──────────────────────┬───────────────────────┘
                                           │
         ┌─────────────────────────────────┼─────────────────────────────────┐
         ▼                                 ▼                                 ▼
┌──────────────────┐             ┌──────────────────┐             ┌──────────────────┐
│  Auth & Identity │             │ Domain Services  │             │ AI Intelligence  │
│  - JWT Engine    │             │  - Patients      │             │  - Baseline Calc │
│  - Google OAuth  │             │  - Caregivers    │             │  - Trend Engine  │
│  - Role RBAC     │             │  - ASHA Roster   │             │  - Early Warning │
└────────┬─────────┘             └────────┬─────────┘             └────────┬─────────┘
         │                                │                                │
         └────────────────────────────────┼────────────────────────────────┘
                                          │
                                          ▼
                    ┌──────────────────────────────────────────────┐
                    │           POSTGRESQL / SQLITE DB             │
                    │  Users | Patients | Caregivers | Sessions   │
                    │  Reminders | Cognitive Logs | Alerts         │
                    └──────────────────────────────────────────────┘
`

---

## 📁 Repository Structure

`	ext
Smriti/
├── .github/                      # CI/CD Workflows & GitHub Configurations
├── backend/                      # FastAPI Backend Service
│   ├── app/
│   │   ├── api/                  # REST API Route Controllers
│   │   │   ├── auth.py           # Login, Signup, Google OAuth
│   │   │   ├── patients.py       # Patient profile, onboarding & details
│   │   │   ├── caregivers.py     # Caregiver dashboard, analytics & alerts
│   │   │   ├── asha.py           # ASHA worker triage & village roster
│   │   │   ├── cognitive.py      # Games, sessions & cognitive tests
│   │   │   ├── reminders.py      # Medication & routine management
│   │   │   └── sync.py           # Offline batch synchronization endpoint
│   │   ├── core/                 # Core Infrastructure
│   │   │   ├── config.py         # Pydantic Settings & environment variables
│   │   │   ├── database.py       # SQLAlchemy engine, session & auto-migrations
│   │   │   └── security.py       # Password hashing & JWT token management
│   │   ├── intelligence/         # AI & Analytical Engines
│   │   │   ├── baseline_calculator.py  # Historical cognitive baseline
│   │   │   └── early_warning_engine.py # Decline alerts & risk stratification
│   │   ├── models/               # SQLAlchemy ORM Models
│   │   │   ├── user.py           # User accounts & role definitions
│   │   │   ├── patient.py        # Patient clinical & demographic data
│   │   │   ├── caregiver.py      # Caregiver profiles & connections
│   │   │   ├── asha_worker.py    # ASHA worker village assignments
│   │   │   ├── session.py        # Cognitive game sessions & responses
│   │   │   ├── reminder.py       # Medication & check-in schedules
│   │   │   └── alert.py          # Early-warning decline notifications
│   │   ├── repositories/         # Data Access Layer & DB Query Abstractions
│   │   ├── schemas/              # Pydantic v2 Request/Response Schemas
│   │   ├── services/             # Core Business Logic & Orchestration
│   │   └── sync/                 # Outbox Processor & Conflict Resolution
│   ├── tests/                    # Backend Pytest Test Suite (87 tests)
│   ├── Dockerfile                # Production Backend Container Definition
│   ├── requirements.txt          # Python Dependencies
│   └── .env.example              # Environment Configuration Template
│
├── frontend/smriti_app/          # Flutter Mobile Application
│   ├── android/                  # Android Native Config, Manifest & Keystore
│   ├── ios/                      # iOS Native Project Files
│   ├── assets/                   # Audio, Images, Reminiscence Media & Icons
│   ├── lib/
│   │   ├── app/                  # Theme, Routes & Global Configurations
│   │   ├── core/                 # Core Utilities
│   │   │   ├── database/         # Local SQLite Helper & Schema
│   │   │   ├── network/          # API Client with local/cloud fallback
│   │   │   ├── sync/             # Offline Outbox Sync Manager
│   │   │   └── theme/            # Elderly-accessible Material 3 design system
│   │   └── features/             # Feature Modules
│   │       ├── auth/             # Login, Signup, Google Sign-In & Role Selection
│   │       ├── patient/          # Health Profile Onboarding & Elder Portal
│   │       ├── cognitive/        # CST Games (Pattern, Word Recall, Memory)
│   │       ├── voice/            # Multilingual Voice Assistant & TTS/STT
│   │       ├── reminiscence/     # Familiar Audio & Family Photo Albums
│   │       ├── reminders/        # Medication Alerts & Audio-Visual Prompts
│   │       ├── caregiver/        # Family Caregiver Monitoring Dashboard
│   │       └── asha/             # Community Healthcare Worker Triage Screen
│   ├── test/                     # Flutter Unit, Widget & Integration Tests (323 tests)
│   └── pubspec.yaml              # Flutter Dependencies & Asset Manifest
│
├── docker-compose.yml            # Docker Compose multi-container setup (API + DB)
├── LICENSE                       # MIT Open-Source License
└── README.md                     # Project Documentation
`

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Mobile Client** | **Flutter 3.19+**, **Dart 3.3+**, Material Design 3, sqflite, google_sign_in, speech_to_text, lutter_tts, dio |
| **Backend API** | **FastAPI**, **Uvicorn**, **Python 3.11+ / 3.14**, Pydantic v2 |
| **Database & ORM** | **PostgreSQL 15+** (Production) / **SQLite** (Local & Embedded), **SQLAlchemy 2.0** |
| **Authentication** | Direct **Google OAuth2 v3** (google-auth), **JWT** (HMAC-SHA256), **Passlib/Bcrypt** |
| **DevOps & Deploy** | **Docker**, **Docker Compose**, Cloud Hosting on **Render** |
| **Testing** | **Pytest** (Backend - 87 tests), **Flutter Test** (Mobile - 323 tests) |

---

## 🚀 Getting Started

### Prerequisites
- **Git** installed on your system
- **Python 3.11+**
- **Flutter SDK (3.19+)** & **Dart (3.3+)**
- **Android Studio** / VS Code with Flutter & Dart extensions
- *(Optional)* **Docker & Docker Compose** for containerized execution

---

### 1. Backend Setup

1. **Navigate to the backend directory**:
   `ash
   cd backend
   `

2. **Create and activate a virtual environment**:
   `ash
   # Windows (PowerShell)
   python -m venv venv
   .\venv\Scripts\Activate.ps1

   # Linux / macOS
   python3 -m venv venv
   source venv/bin/activate
   `

3. **Install dependencies**:
   `ash
   pip install -r requirements.txt
   `

4. **Configure environment variables**:
   Create a .env file in the ackend/ directory by copying .env.example:
   `ash
   cp .env.example .env
   `
   *Required variables*:
   `env
   ENVIRONMENT=development
   DEBUG=True
   APP_PORT=8000
   DATABASE_URL=sqlite:///./smriti.db   # Or postgresql://user:pass@localhost:5432/smriti
   SECRET_KEY=your_super_secret_jwt_key_at_least_32_characters
   GOOGLE_SERVER_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
   `

5. **Start the development server**:
   `ash
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   `
   The interactive Swagger documentation will be available at:
   - **Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
   - **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

### 2. Frontend Setup (Flutter)

1. **Navigate to the Flutter project**:
   `ash
   cd frontend/smriti_app
   `

2. **Install Flutter packages**:
   `ash
   flutter pub get
   `

3. **Run code analysis**:
   `ash
   flutter analyze
   `

4. **Launch on an emulator or physical device**:
   `ash
   flutter run
   `
   *(Ensure an Android emulator or device is connected via ADB).*

---

### 3. Docker Deployment (Single Command)

To run the complete production stack (FastAPI Backend + PostgreSQL database) using Docker:

`ash
docker compose up -d --build
`
- FastAPI API will be available at [http://localhost:8000](http://localhost:8000)
- PostgreSQL database will run on port 5432

---

## 🧪 Testing & Verification

SMRITI maintains strict automated test coverage across both backend and frontend codebases:

### Run Backend Pytest Suite
`ash
cd backend
pytest -v
`
*(87 tests covering authentication, Google OAuth, patient onboarding, caregiver dashboard, ASHA triage, intelligence engines, and offline sync).*

### Run Frontend Flutter Tests
`ash
cd frontend/smriti_app
flutter test
`
*(323 unit, widget, and integration tests verifying UI rendering, local database caching, outbox sync, and state transitions).*

---

## 🌐 API Overview

| Method | Endpoint | Description | Access |
|---|---|---|---|
| POST | /api/v1/auth/signup | Register new user (Patient, Caregiver, ASHA) | Public |
| POST | /api/v1/auth/login | Email/Password login, returns JWT token | Public |
| POST | /api/v1/auth/google | Google OAuth token exchange & user provisioning | Public |
| GET | /api/v1/patients/me | Fetch active authenticated patient profile | Patient |
| POST | /api/v1/patients/onboarding | First-time onboarding (Age, Gender, Dementia Type) | Patient |
| GET | /api/v1/caregivers/dashboard | Caregiver analytics, patient status & cognitive trends | Caregiver |
| GET | /api/v1/asha/patients | Community triage roster & risk-stratified patients | ASHA Worker |
| POST | /api/v1/cognitive/sessions | Record completed CST game session & score | Authenticated |
| POST | /api/v1/sync/batch | Bulk synchronize offline outbox records | Authenticated |

---

## ⚖️ Clinical & Ethical Disclaimer

> [!IMPORTANT]
> **SMRITI is an assistive digital health and cognitive-care companion.**
> All cognitive stimulation metrics, memory indices, and early-warning alerts generated by SMRITI's AI intelligence engine are intended strictly for **longitudinal progress tracking and decision-support triage**. SMRITI does **not** provide clinical psychiatric or neurological diagnoses. Users, caregivers, and community healthcare workers should always consult qualified medical professionals for formal diagnostic evaluations.

---

## 📄 License

This project is licensed under the terms of the [MIT License](LICENSE).
