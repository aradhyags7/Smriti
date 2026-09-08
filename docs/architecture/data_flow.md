# Data Flow — SMRITI Platform

> **Owner**: Tanishka Sawant (Integration Lead)  
> **Last Updated**: 2026-09-07

---

## Overview

This document traces the complete data lifecycle from patient interaction on the mobile app through backend persistence in PostgreSQL to consumption by the AI intelligence engine for cognitive scoring, trend generation, and alert triggering.

---

## End-to-End Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            FLUTTER MOBILE APP                              │
│                                                                             │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────────────────┐  │
│  │  Cognitive  │  │  Check-in  │  │  Session   │  │  Reminiscence        │  │
│  │  Game UIs   │  │  Screen    │  │  Manager   │  │  Memory Browser      │  │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └──────────┬───────────┘  │
│        │               │               │                     │              │
│        ▼               ▼               ▼                     ▼              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        LOCAL SQLITE DATABASE                         │   │
│  │                                                                      │   │
│  │  game_attempts (PENDING)    daily_checkins (PENDING)                 │   │
│  │  sessions                    memory_items                            │   │
│  └──────────────────────────────────┬───────────────────────────────────┘   │
│                                     │                                       │
│  ┌──────────────────────────────────▼───────────────────────────────────┐   │
│  │                          SYNC SERVICE                                │   │
│  │  Batches PENDING records → POST /api/v1/sync/push                   │   │
│  └──────────────────────────────────┬───────────────────────────────────┘   │
└─────────────────────────────────────┼───────────────────────────────────────┘
                                      │
                                      │ HTTPS (JSON, snake_case)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          BACKEND (FastAPI)                                  │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  Sync Router  │  │  Game Router  │  │  Checkin     │  │  Session     │   │
│  │  /sync/push   │  │  /games/*     │  │  Router      │  │  Router      │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                 │                  │                  │           │
│         ▼                 ▼                  ▼                  ▼           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        SERVICE LAYER                                 │   │
│  │                                                                      │   │
│  │  SyncService    GameService    CheckinService    SessionService      │   │
│  │  ├─ validate    ├─ validate    ├─ validate        ├─ validate        │   │
│  │  ├─ persist     ├─ persist     ├─ persist         ├─ persist         │   │
│  │  └─ notify AI   └─ notify AI   └─ notify AI       └─ notify AI      │   │
│  └──────────────────────────────────┬───────────────────────────────────┘   │
│                                     │                                       │
│                                     ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      REPOSITORY LAYER (SQLAlchemy 2.0)              │   │
│  │                                                                      │   │
│  │  GameAttemptRepo    CheckinRepo    SessionRepo    AlertRepo          │   │
│  │  ├─ create()        ├─ create()    ├─ create()    ├─ create()        │   │
│  │  ├─ get_by_id()     ├─ get_by_id() ├─ update()    ├─ get_active()    │   │
│  │  ├─ list_by_patient()├─ list()     ├─ complete()  └─ acknowledge()   │   │
│  │  └─ get_by_client_id()             └─ get_stats()                    │   │
│  └──────────────────────────────────┬───────────────────────────────────┘   │
│                                     │                                       │
│                                     ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        POSTGRESQL DATABASE                          │   │
│  │                                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │ game_attempts │  │daily_checkins│  │  sessions     │              │   │
│  │  │              │  │              │  │              │              │   │
│  │  │ id           │  │ id           │  │ id           │              │   │
│  │  │ client_id ◄──┤  │ client_id ◄──┤  │ client_id    │              │   │
│  │  │ patient_id   │  │ patient_id   │  │ patient_id   │              │   │
│  │  │ session_id──▶│  │ mood_score   │  │ status       │              │   │
│  │  │ game_type    │  │ sleep_hours  │  │ started_at   │              │   │
│  │  │ difficulty   │  │ symptoms     │  │ completed_at │              │   │
│  │  │ score        │  │ checkin_time │  │ avg_score    │              │   │
│  │  │ mistakes     │  │ sync_status  │  └──────────────┘              │   │
│  │  │ reaction_ms  │  └──────────────┘                                │   │
│  │  │ completion_s │                                                   │   │
│  │  │ sync_status  │  ┌──────────────┐  ┌──────────────┐              │   │
│  │  └──────────────┘  │   alerts      │  │   patients   │              │   │
│  │                     │              │  │              │              │   │
│  │                     │ patient_id   │  │ id           │              │   │
│  │                     │ alert_type   │  │ user_id      │              │   │
│  │                     │ severity     │  │ dob          │              │   │
│  │                     │ status       │  │ baseline     │              │   │
│  │                     └──────────────┘  └──────────────┘              │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                     │                                       │
│                                     │ Event / Notification                  │
│                                     ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    AI INTELLIGENCE ENGINE                            │   │
│  │                    (backend/app/intelligence/)                       │   │
│  │                                                                      │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────────┐  │   │
│  │  │  Cognitive       │  │  Trend           │  │  Alert             │  │   │
│  │  │  Scorer          │  │  Analyzer        │  │  Generator         │  │   │
│  │  │                  │  │                  │  │                    │  │   │
│  │  │  Input:          │  │  Input:          │  │  Input:            │  │   │
│  │  │  - game_attempts │  │  - scored data   │  │  - trends          │  │   │
│  │  │  - checkins      │  │  - 7/14/30d      │  │  - thresholds      │  │   │
│  │  │  - baseline      │  │    windows       │  │  - patient profile │  │   │
│  │  │                  │  │                  │  │                    │  │   │
│  │  │  Output:         │  │  Output:         │  │  Output:           │  │   │
│  │  │  - domain scores │  │  - TrendSeries   │  │  - AlertCreate     │  │   │
│  │  │  - CognitiveRpt  │  │  - direction     │  │  - severity        │  │   │
│  │  │  - risk_flags    │  │  - data_points   │  │  - message         │  │   │
│  │  └─────────────────┘  └─────────────────┘  └────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                     │                                       │
│                                     │ Writes back to DB                     │
│                                     ▼                                       │
│                     ┌───────────────────────────────┐                       │
│                     │  cognitive_reports table       │                       │
│                     │  patient_trends table          │                       │
│                     │  alerts table (new alerts)     │                       │
│                     └───────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                              Consumed by
                                      ▼
                    ┌───────────────────────────────────┐
                    │         DASHBOARD VIEWS            │
                    │                                    │
                    │  • Caregiver Dashboard             │
                    │    - Cognitive scores & trends     │
                    │    - Active alerts                  │
                    │    - Session history                │
                    │                                    │
                    │  • ASHA Triage Dashboard            │
                    │    - Prioritised patient list       │
                    │    - Risk-sorted summaries          │
                    │    - Alert acknowledgement          │
                    └───────────────────────────────────┘
```

---

## Data Flow Stages

### Stage 1: Data Capture (Mobile)

The Flutter app captures raw data at the point of patient interaction:

| Data Source | Schema | Key Fields | Storage |
|---|---|---|---|
| Cognitive games | `GameAttemptCreate` | `client_attempt_id`, `score`, `mistakes`, `reaction_time_ms`, `completion_time_seconds`, `game_type`, `difficulty` | SQLite (PENDING) |
| Daily check-in | `DailyCheckinCreate` | `client_checkin_id`, `mood_score`, `sleep_hours`, `symptoms_noted` | SQLite (PENDING) |
| Session lifecycle | `DailySessionStart/Complete` | `client_session_id`, `total_games_played`, `average_score` | SQLite |

**Critical**: The client generates UUID v4 identifiers locally. These serve as idempotency keys during sync.

---

### Stage 2: Sync Transport

Data moves from client to server via the batch sync protocol:

```
SQLite (PENDING) → Sync Service → POST /api/v1/sync/push → Backend
```

The `SyncPayloadRequest` bundles all pending records:
- `pending_games: List[GameAttemptCreate]`
- `pending_checkins: List[DailyCheckinCreate]`

See [offline_sync_flow.md](./offline_sync_flow.md) for the complete sync lifecycle.

---

### Stage 3: Backend Persistence

The backend processes incoming data through a layered architecture:

```
Router (validation) → Service (business logic) → Repository (DB operations) → PostgreSQL
```

**Key operations**:
1. Pydantic v2 validation of the incoming payload
2. Idempotency check via `client_attempt_id` / `client_checkin_id` unique constraints
3. Database INSERT within a transaction
4. Sync status update (`SYNCED` on response)
5. Event notification to the AI engine

---

### Stage 4: AI Processing

The AI intelligence engine processes raw data into actionable insights:

#### 4a. Cognitive Scoring

**Input**: Raw `game_attempts` records for a patient within a time window.

**Processing**:
1. Fetch all game attempts for the patient in the analysis window (7/14/30 days)
2. Fetch the patient's `BaselineAssessmentResponse` for calibration
3. Compute per-domain scores:
   - **Memory** ← `memory_pairs` performance
   - **Attention** ← `simon_says` reaction times and accuracy
   - **Executive Function** ← `odd_one_out` reasoning accuracy
   - **Language** ← `object_naming` scores
   - **Visuospatial** ← cross-game spatial metrics
4. Weight and normalise into an `overall_score` (0–100)
5. Compare against baseline to detect drift

**Output**: `CognitiveReport` with `domain_scores`, `risk_flags`, `recommendations`.

#### 4b. Trend Analysis

**Input**: Time-series of scored data (game scores, mood scores, sleep hours).

**Processing**:
1. Aggregate daily data points into `TrendDataPoint` objects
2. Apply rolling average smoothing (7-day window)
3. Compute trend direction via linear regression slope:
   - Slope > +0.5 → `improving`
   - -0.5 ≤ Slope ≤ +0.5 → `stable`
   - Slope < -0.5 → `declining`
4. Package into `TrendSeries` for each metric

**Output**: `PatientTrendResponse` with multiple `TrendSeries` objects.

#### 4c. Alert Generation

**Input**: Trends, thresholds, patient profile.

**Processing**:
1. Evaluate alert rules against current data:

| Alert Rule | Condition | Severity |
|---|---|---|
| Cognitive decline | Overall score dropped >15 points in 7 days | `high` |
| Rapid decline | Overall score dropped >25 points in 7 days | `critical` |
| Missed sessions | No session in 3+ consecutive days | `medium` |
| Extended absence | No session in 7+ days | `high` |
| Mood drop | Average mood ≤ 2.0 over 3 days | `medium` |
| Severe mood | Single mood_score = 1 | `high` |
| Sleep disruption | Average sleep < 4 hours over 3 days | `medium` |
| Medication missed | Reminder not acknowledged for 2+ days | `low` |

2. Create `AlertCreate` payloads for triggered rules
3. Check for alert deduplication (don't re-alert for the same condition within 24 hours)

**Output**: `AlertCreate` objects persisted to the `alerts` table.

---

### Stage 5: Dashboard Consumption

Processed data is consumed by two dashboard views:

#### Caregiver Dashboard

```
GET /patients/{id}/games      → Game history
GET /patients/{id}/checkins   → Check-in history
GET /patients/{id}/sessions   → Session history
GET /patients/{id}/trends     → Trend visualisation data (PatientTrendResponse)
GET /patients/{id}/alerts     → Active alerts
GET /patients/{id}/baseline   → Baseline assessment
```

#### ASHA Triage Dashboard

```
GET /asha/triage              → Prioritised patient list (AshaTriageResponse)
GET /asha/patients/{id}       → Individual patient detail
POST /alerts/{id}/acknowledge → Alert acknowledgement
```

---

## Game-to-Domain Mapping

The AI engine maps game types to cognitive domains:

| Game Type | Primary Domain | Secondary Domain | Key Metrics Used |
|---|---|---|---|
| `memory_pairs` | Memory | Attention | `score`, `mistakes`, `reaction_time_ms` |
| `odd_one_out` | Executive Function | Visuospatial | `score`, `completion_time_seconds` |
| `simon_says` | Attention | Memory | `reaction_time_ms`, `mistakes`, `score` |
| `object_naming` | Language | Memory | `score`, `completion_time_seconds` |

---

## Data Retention & Privacy

| Data Type | Retention Period | Justification |
|---|---|---|
| Game attempts | Indefinite | Longitudinal cognitive tracking |
| Daily check-ins | Indefinite | Wellbeing trend analysis |
| Sessions | Indefinite | Engagement tracking |
| Alerts | 1 year after resolution | Audit trail |
| Cognitive reports | Indefinite | Comparison against baseline |
| Patient consent records | Indefinite | Legal compliance |
| OTP codes | 5 minutes | Security (auto-expire) |
| JWT refresh tokens | 30 days | Security (auto-expire) |

---

## Data Integrity Constraints

| Constraint | Implementation | Purpose |
|---|---|---|
| `client_attempt_id` UNIQUE | PostgreSQL unique index | Idempotent sync |
| `client_checkin_id` UNIQUE | PostgreSQL unique index | Idempotent sync |
| `score` CHECK (0–100) | DB + Pydantic | Data quality |
| `mood_score` CHECK (1–5) | DB + Pydantic | Valid range |
| `sleep_hours` CHECK (0–24) | DB + Pydantic | Valid range |
| `patient_id` FK | Foreign key to patients | Referential integrity |
| `session_id` FK (nullable) | Foreign key to sessions | Optional session linkage |
| Transaction wrapping | SQLAlchemy session | Atomicity of sync batches |
