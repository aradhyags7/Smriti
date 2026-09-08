# SMRITI — AI-Powered Cognitive Care Platform

SMRITI is an offline-first, voice-driven, AI-adaptive cognitive-care application designed for elderly individuals with dementia and mild cognitive impairment (MCI), specifically tailored for the North Eastern Region of India (NER).

---

## 🏛️ Project Architecture & Team Division

```text
SMRITI/
├── README.md
├── .gitignore
├── .env.example
├── docker-compose.yml
├── LICENSE
│
├── docs/                                    # Architecture, User Flow & Research Papers
│   ├── architecture/
│   ├── api/
│   └── research/
│
├── frontend/
│   └── smriti_app/                         # FLUTTER APP
│       ├── pubspec.yaml
│       ├── analysis_options.yaml
│       ├── assets/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app/                        # App config, routes, theme & constants
│       │   ├── core/
│       │   │   ├── database/               # Local SQLite (Aradhya)
│       │   │   ├── network/                # API Client & Connectivity
│       │   │   ├── sync/                   # Offline Outbox Sync Manager (Aradhya)
│       │   │   ├── storage/                # Local & Secure Storage
│       │   │   └── utils/
│       │   └── features/
│       │       ├── auth/                   # Authentication & Role Selection
│       │       ├── onboarding/             # Caregiver & Patient Calibration
│       │       ├── patient/                # Elder-friendly Portal & Check-ins
│       │       ├── cognitive/              # CST Games, Adaptive Engine & Scoring
│       │       ├── voice/                  # Multilingual Voice Assistant (Assamese focus)
│       │       ├── reminiscence/           # Familiar Photo & Audio Vault
│       │       ├── reminders/              # Medication & Daily Routines
│       │       ├── caregiver/              # Family Member Monitor & Settings
│       │       ├── asha/                   # Rural Healthcare Worker Triage (Consent Gated)
│       │       ├── notifications/
│       │       └── settings/
│       └── test/
│
├── backend/                                # FASTAPI BACKEND
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── .env.example
│   ├── app/
│   │   ├── main.py                         # App Entrypoint & Lifespan (Ashish)
│   │   ├── core/                           # Database, Config & Security (Ashish)
│   │   ├── models/                         # Domain Models (Aradhya)
│   │   ├── schemas/                        # Pydantic Schemas (Tanishka + Aradhya)
│   │   ├── api/                            # REST Endpoints (Ashish)
│   │   ├── services/                       # Business Logic (Ashish)
│   │   ├── intelligence/                   # Baseline, Trend, Risk & Alerts (Aradhya)
│   │   ├── sync/                           # Cloud Sync Processor & Conflict Resolver (Aradhya)
│   │   ├── repositories/                   # Data Access Layer (Aradhya)
│   │   └── utils/
│   └── database/                           # Migrations & Seed Scripts (Aradhya + Ashish)
│
└── scripts/                                # Dev Automation & Seed Scripts
```

---

## ⚖️ Clinical Disclaimer
*The prototype cognitive-performance risk score provided by SMRITI is an early-warning decision support indicator and is NOT a medical diagnosis.*
