# SMRITI — AI-Powered Cognitive Care Platform

SMRITI is an offline-first, voice-driven, AI-adaptive cognitive-care application designed for elderly individuals with dementia and mild cognitive impairment (MCI), specifically tailored for the North Eastern Region of India (NER).

---

## 🏛️ Project Directory Structure

```text
SMRITI/
├── README.md
├── .gitignore
├── .env.example
├── docker-compose.yml
├── LICENSE
│
├── docs/                                    # Architecture, API specifications & clinical research
│   ├── architecture/
│   ├── api/
│   └── research/
│
├── frontend/
│   └── smriti_app/                         # Flutter Mobile & Tablet Patient Application
│       ├── pubspec.yaml
│       ├── assets/
│       ├── lib/
│       │   ├── app/
│       │   ├── core/                       # SQLite, outbox sync, network & storage
│       │   └── features/                   # Cognitive games, voice, reminders, ASHA triage
│       └── test/
│
├── backend/                                # FastAPI Cloud & Sync Service
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── app/
│   │   ├── api/
│   │   ├── core/
│   │   ├── database/
│   │   ├── intelligence/                   # Cognitive trend engine & risk calculation
│   │   ├── schemas/
│   │   ├── services/
│   │   └── utils/
│   └── tests/
│
├── dashboard/                              # Web Dashboard for Caregivers & ASHA Workers
├── database/                               # Schema migrations, seed data & SQL scripts
├── scripts/                                # Environment setup and deployment automation
└── deployment/                             # Dockerfiles & production compose manifests
```

---

## 🚀 Quick Setup

### 1. Backend (FastAPI)
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Or on Windows: .\venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### 2. Frontend (Flutter)
```bash
cd frontend/smriti_app
flutter pub get
flutter run
```

### 3. Caregiver Dashboard
Access `http://127.0.0.1:8000/dashboard/` once the backend service is running.

---

## ⚖️ Clinical Disclaimer
*The prototype cognitive-performance risk score provided by SMRITI is an early-warning decision support indicator and is NOT a clinical diagnosis.*
