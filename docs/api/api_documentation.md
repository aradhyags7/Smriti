# SMRITI Platform — Master API Documentation

> **Version**: 1.0.0  
> **Base URL**: `https://api.smriti.health/api/v1`  
> **Owner**: Tanishka Sawant (Integration Lead & API Contracts)  
> **Last Updated**: 2026-09-07

---

## Table of Contents

1. [Global Conventions](#1-global-conventions)
2. [Authentication](#2-authentication)
3. [Users](#3-users)
4. [Patients](#4-patients)
5. [Sessions](#5-sessions)
6. [Games](#6-games)
7. [Daily Check-ins](#7-daily-check-ins)
8. [Reminders](#8-reminders)
9. [Memory / Reminiscence](#9-memory--reminiscence)
10. [Offline Sync](#10-offline-sync)
11. [Alerts](#11-alerts)
12. [ASHA Triage](#12-asha-triage)

---

## 1. Global Conventions

### 1.1 Request / Response Format

| Convention | Detail |
|---|---|
| **Content-Type** | `application/json` for all request and response bodies |
| **Key Naming** | `snake_case` everywhere (Python, JSON, DB columns) |
| **Timestamps** | ISO 8601 with timezone: `2026-09-07T10:30:00Z` |
| **IDs** | UUID v4 strings |
| **Pagination** | `?page=1&page_size=20` (default page_size = 20, max = 100) |
| **Language** | ISO 639-1 codes (`en`, `hi`, `mr`) |

### 1.2 Authentication Header

All protected endpoints require:

```
Authorization: Bearer <access_token>
```

### 1.3 Standard Error Response

```json
{
  "detail": "Human-readable error message.",
  "error_code": "VALIDATION_ERROR",
  "timestamp": "2026-09-07T10:30:00Z"
}
```

### 1.4 Standard HTTP Status Codes

| Code | Meaning |
|---|---|
| `200` | Success |
| `201` | Created |
| `204` | No Content (successful delete) |
| `400` | Bad Request — malformed payload |
| `401` | Unauthorized — missing or expired token |
| `403` | Forbidden — insufficient role or missing consent |
| `404` | Not Found |
| `409` | Conflict — duplicate resource (e.g., duplicate `client_attempt_id`) |
| `422` | Unprocessable Entity — validation failed |
| `429` | Too Many Requests — rate limit exceeded |
| `500` | Internal Server Error |

### 1.5 Role-Based Access Control (RBAC)

| Role | Code | Access Level |
|---|---|---|
| Patient | `patient` | Own data only |
| Caregiver | `caregiver` | Linked patient(s) data |
| ASHA Worker | `asha` | Assigned patient(s) data **only with valid consent** |

---

## 2. Authentication

### 2.1 Sign Up

**`POST /auth/signup`** — Register a new user.

**Request Body** (`UserSignupRequest`):
```json
{
  "full_name": "Tanishka Sawant",
  "phone_number": "+919876543210",
  "role": "caregiver",
  "pin": "1234",
  "email": "tanishka@example.com",
  "preferred_language": "en"
}
```

| Field | Type | Constraints | Required |
|---|---|---|---|
| `full_name` | string | 2–120 chars | Yes |
| `phone_number` | string | E.164 regex `^\+?[1-9]\d{6,14}$` | Yes |
| `role` | enum | `patient`, `caregiver`, `asha` | Yes |
| `pin` | string | 4–6 digit numeric | Yes |
| `email` | string | Valid email | No |
| `preferred_language` | string | ISO 639-1, max 5 chars | No (default: `en`) |

**201 Response** (`UserResponse`):
```json
{
  "id": "uuid-string",
  "full_name": "Tanishka Sawant",
  "phone_number": "+919876543210",
  "role": "caregiver",
  "email": "tanishka@example.com",
  "preferred_language": "en",
  "is_active": true,
  "created_at": "2026-09-07T10:00:00Z",
  "updated_at": "2026-09-07T10:00:00Z"
}
```

**Errors**: `400` (malformed), `409` (phone already registered), `422` (validation).

---

### 2.2 Login

**`POST /auth/login`** — Authenticate with phone + PIN.

**Request Body** (`UserLoginRequest`):
```json
{
  "phone_number": "+919876543210",
  "pin": "1234"
}
```

**200 Response** (`TokenResponse`):
```json
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "dGhpcyBpcy...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user_id": "uuid-string",
  "role": "caregiver"
}
```

**Errors**: `401` (wrong credentials), `403` (account deactivated).

---

### 2.3 Refresh Token

**`POST /auth/refresh`** — Exchange refresh token for new access token.

**Request Body**:
```json
{
  "refresh_token": "dGhpcyBpcy..."
}
```

**200 Response**: Same `TokenResponse` schema with fresh tokens.

**Errors**: `401` (invalid/expired refresh token).

---

### 2.4 Request OTP

**`POST /auth/otp/request`** — Send a 6-digit OTP via SMS.

**Request Body** (`OTPRequest`):
```json
{
  "phone_number": "+919876543210"
}
```

**200 Response**:
```json
{
  "message": "OTP sent successfully.",
  "expires_in_seconds": 300
}
```

**Errors**: `404` (phone not registered), `429` (rate limited).

---

### 2.5 Verify OTP

**`POST /auth/otp/verify`** — Verify a received OTP code.

**Request Body** (`OTPVerifyRequest`):
```json
{
  "phone_number": "+919876543210",
  "otp_code": "123456"
}
```

**200 Response**:
```json
{
  "verified": true,
  "message": "OTP verified successfully."
}
```

**Errors**: `400` (invalid OTP), `401` (expired OTP).

---

### 2.6 Forgot PIN

**`POST /auth/forgot-pin`** — Reset PIN after OTP verification.

**Request Body** (`ForgotPinRequest`):
```json
{
  "phone_number": "+919876543210",
  "otp_code": "123456",
  "new_pin": "5678"
}
```

**200 Response**:
```json
{
  "message": "PIN reset successfully."
}
```

**Errors**: `400` (invalid OTP), `422` (PIN validation failed).

---

## 3. Users

### 3.1 Get Current User

**`GET /users/me`** — Retrieve the authenticated user's profile.

**Headers**: `Authorization: Bearer <token>`

**200 Response**: `UserResponse` (see §2.1 response).

**Errors**: `401`.

---

### 3.2 Update Profile

**`PATCH /users/me`** — Partial update of the authenticated user's profile.

**Request Body** (`UserUpdate`):
```json
{
  "full_name": "Tanishka S.",
  "preferred_language": "hi"
}
```

All fields are optional.

**200 Response**: Updated `UserResponse`.

**Errors**: `401`, `422`.

---

## 4. Patients

### 4.1 Create Patient Profile

**`POST /patients`** — Register a new patient (caregiver or ASHA role required).

**Request Body** (`PatientCreate`):
```json
{
  "user_id": "uuid-string",
  "date_of_birth": "1955-03-15",
  "gender": "female",
  "education_level": "primary",
  "primary_language": "hi",
  "emergency_contact_name": "Suresh Sawant",
  "emergency_contact_phone": "+919876543211",
  "medical_notes": "Mild hypertension, no diabetes."
}
```

| Field | Type | Constraints | Required |
|---|---|---|---|
| `user_id` | string | UUID | Yes |
| `date_of_birth` | date | `YYYY-MM-DD` | Yes |
| `gender` | enum | `male`, `female`, `other` | Yes |
| `education_level` | enum | `none` to `post_graduate` | No (default: `none`) |
| `primary_language` | string | ISO 639-1 | No (default: `hi`) |
| `emergency_contact_name` | string | 2–120 chars | Yes |
| `emergency_contact_phone` | string | E.164 | Yes |
| `medical_notes` | string | max 2000 chars | No |

**201 Response**: `PatientResponse`.

**Errors**: `400`, `403` (wrong role), `409` (patient exists), `422`.

---

### 4.2 Get Patient

**`GET /patients/{patient_id}`** — Retrieve a patient profile.

**Path Params**: `patient_id` (UUID).

**200 Response**: `PatientResponse`.

**Errors**: `401`, `403` (ASHA without consent), `404`.

---

### 4.3 Update Patient

**`PATCH /patients/{patient_id}`** — Partial update.

**Request Body**: `PatientUpdate` (all fields optional).

**200 Response**: Updated `PatientResponse`.

**Errors**: `401`, `403`, `404`, `422`.

---

### 4.4 Record Baseline Assessment

**`POST /patients/{patient_id}/baseline`** — Record initial cognitive assessment.

**Request Body** (`BaselineAssessmentCreate`):
```json
{
  "patient_id": "uuid-string",
  "assessor_id": "uuid-string",
  "mmse_score": 24,
  "moca_score": 22,
  "clock_drawing_score": 7,
  "verbal_fluency_count": 12,
  "assessment_notes": "Patient cooperative. Mild delay in recall.",
  "assessed_at": "2026-09-07T09:00:00Z"
}
```

| Field | Type | Constraints | Required |
|---|---|---|---|
| `mmse_score` | int | 0–30 | No |
| `moca_score` | int | 0–30 | No |
| `clock_drawing_score` | int | 0–10 | No |
| `verbal_fluency_count` | int | ≥ 0 | No |
| `assessed_at` | datetime | ISO 8601 | Yes |

**201 Response**: `BaselineAssessmentResponse`.

**Errors**: `401`, `403`, `404`, `422`.

---

### 4.5 Get Baseline Assessment

**`GET /patients/{patient_id}/baseline`** — Retrieve the latest baseline.

**200 Response**: `BaselineAssessmentResponse`.

**Errors**: `401`, `403`, `404`.

---

## 5. Sessions

### 5.1 Start Session

**`POST /sessions`** — Begin a new daily cognitive session.

**Request Body** (`DailySessionStart`):
```json
{
  "patient_id": "uuid-string",
  "client_session_id": "uuid-string",
  "started_at": "2026-09-07T10:00:00Z",
  "device_info": "Samsung Galaxy A54, Android 14"
}
```

**201 Response**: `DailySessionResponse` (status = `in_progress`).

**Errors**: `401`, `409` (duplicate client_session_id), `422`.

---

### 5.2 Complete Session

**`PATCH /sessions/{session_id}/complete`** — Mark a session as completed.

**Request Body** (`DailySessionComplete`):
```json
{
  "session_id": "uuid-string",
  "status": "completed",
  "total_games_played": 4,
  "total_duration_seconds": 600,
  "average_score": 72.5,
  "completed_at": "2026-09-07T10:10:00Z"
}
```

**200 Response**: Updated `DailySessionResponse`.

**Errors**: `401`, `404`, `422`.

---

### 5.3 Get Session

**`GET /sessions/{session_id}`** — Retrieve session details.

**200 Response**: `DailySessionResponse`.

**Errors**: `401`, `403`, `404`.

---

### 5.4 List Patient Sessions

**`GET /patients/{patient_id}/sessions`** — Paginated session history.

**Query Params**: `page`, `page_size`, `status` (optional filter).

**200 Response**:
```json
{
  "items": [ DailySessionResponse, ... ],
  "total": 42,
  "page": 1,
  "page_size": 20
}
```

**Errors**: `401`, `403`.

---

## 6. Games

### 6.1 Submit Game Attempt

**`POST /games/attempts`** — Record a single cognitive game attempt.

**Request Body** (`GameAttemptCreate`):
```json
{
  "client_attempt_id": "uuid-string",
  "patient_id": "uuid-string",
  "session_id": "uuid-string",
  "game_type": "memory_pairs",
  "difficulty": "medium",
  "score": 78,
  "mistakes": 3,
  "reaction_time_ms": 1250,
  "completion_time_seconds": 45,
  "completed_at": "2026-09-07T10:30:00Z"
}
```

| Field | Type | Constraints | Required |
|---|---|---|---|
| `client_attempt_id` | string | UUID v4 | Yes |
| `patient_id` | string | UUID | Yes |
| `session_id` | string | UUID | No |
| `game_type` | enum | `memory_pairs`, `odd_one_out`, `simon_says`, `object_naming` | Yes |
| `difficulty` | enum | `easy`, `medium`, `hard` | Yes |
| `score` | int | 0–100 | Yes |
| `mistakes` | int | ≥ 0 | Yes |
| `reaction_time_ms` | int | ≥ 0 | Yes |
| `completion_time_seconds` | int | ≥ 0 | Yes |
| `completed_at` | datetime | ISO 8601 | Yes |

**201 Response**: `GameAttemptResponse`.

**Errors**: `401`, `409` (duplicate `client_attempt_id`), `422`.

---

### 6.2 Get Game Attempt

**`GET /games/attempts/{attempt_id}`** — Retrieve a single attempt.

**200 Response**: `GameAttemptResponse`.

**Errors**: `401`, `403`, `404`.

---

### 6.3 List Patient Game Attempts

**`GET /patients/{patient_id}/games`** — Paginated game history.

**Query Params**: `page`, `page_size`, `game_type` (optional), `difficulty` (optional), `date_from`, `date_to`.

**200 Response**:
```json
{
  "items": [ GameAttemptResponse, ... ],
  "total": 156,
  "page": 1,
  "page_size": 20
}
```

**Errors**: `401`, `403`.

---

## 7. Daily Check-ins

### 7.1 Submit Check-in

**`POST /checkins`** — Record a daily wellbeing check-in.

**Request Body** (`DailyCheckinCreate`):
```json
{
  "client_checkin_id": "uuid-string",
  "patient_id": "uuid-string",
  "mood_score": 4,
  "sleep_hours": 7.5,
  "appetite_rating": 3,
  "energy_level": 4,
  "symptoms_noted": "Mild headache in the morning",
  "checkin_time": "2026-09-07T08:00:00Z"
}
```

| Field | Type | Constraints | Required |
|---|---|---|---|
| `client_checkin_id` | string | UUID v4 | Yes |
| `patient_id` | string | UUID | Yes |
| `mood_score` | int | 1–5 | Yes |
| `sleep_hours` | float | 0.0–24.0 | Yes |
| `appetite_rating` | int | 1–5 | No |
| `energy_level` | int | 1–5 | No |
| `symptoms_noted` | string | max 1000 chars | No |
| `checkin_time` | datetime | ISO 8601 | Yes |

**201 Response**: `DailyCheckinResponse`.

**Errors**: `401`, `409` (duplicate `client_checkin_id`), `422`.

---

### 7.2 Get Check-in

**`GET /checkins/{checkin_id}`** — Retrieve a single check-in.

**200 Response**: `DailyCheckinResponse`.

**Errors**: `401`, `403`, `404`.

---

### 7.3 List Patient Check-ins

**`GET /patients/{patient_id}/checkins`** — Paginated check-in history.

**Query Params**: `page`, `page_size`, `date_from`, `date_to`.

**200 Response**:
```json
{
  "items": [ DailyCheckinResponse, ... ],
  "total": 30,
  "page": 1,
  "page_size": 20
}
```

**Errors**: `401`, `403`.

---

## 8. Reminders

### 8.1 Create Reminder

**`POST /reminders`** — Create a new reminder for a patient.

**Request Body** (`ReminderCreate`):
```json
{
  "patient_id": "uuid-string",
  "created_by": "uuid-string",
  "reminder_type": "medication",
  "title": "Take morning medicine",
  "description": "Amlodipine 5mg with water after breakfast",
  "frequency": "daily",
  "scheduled_time": "08:00:00",
  "days_of_week": null,
  "start_date": "2026-09-07T00:00:00Z",
  "end_date": null,
  "voice_prompt_url": null
}
```

| Field | Type | Constraints | Required |
|---|---|---|---|
| `reminder_type` | enum | `medication`, `exercise`, `appointment`, `game_session`, `hydration`, `custom` | Yes |
| `frequency` | enum | `once`, `daily`, `weekly`, `custom` | No (default: `daily`) |
| `scheduled_time` | time | `HH:MM:SS` | Yes |
| `days_of_week` | list[int] | ISO weekday 1–7 | No |

**201 Response**: `ReminderResponse`.

**Errors**: `401`, `403`, `422`.

---

### 8.2 Update Reminder

**`PATCH /reminders/{reminder_id}`** — Partial update.

**Request Body**: `ReminderUpdate` (all fields optional).

**200 Response**: Updated `ReminderResponse`.

**Errors**: `401`, `403`, `404`, `422`.

---

### 8.3 Get Reminder

**`GET /reminders/{reminder_id}`** — Retrieve a single reminder.

**200 Response**: `ReminderResponse`.

**Errors**: `401`, `403`, `404`.

---

### 8.4 List Patient Reminders

**`GET /patients/{patient_id}/reminders`** — List reminders for a patient.

**Query Params**: `page`, `page_size`, `status` (optional), `reminder_type` (optional).

**200 Response**:
```json
{
  "items": [ ReminderResponse, ... ],
  "total": 8,
  "page": 1,
  "page_size": 20
}
```

**Errors**: `401`, `403`.

---

### 8.5 Delete Reminder

**`DELETE /reminders/{reminder_id}`** — Permanently remove a reminder.

**204 Response**: No content.

**Errors**: `401`, `403`, `404`.

---

## 9. Memory / Reminiscence

### 9.1 Upload Memory Item

**`POST /memory/items`** — Upload a reminiscence item (photo, audio, text).

**Request Body** (`ReminiscenceItemCreate`):
```json
{
  "patient_id": "uuid-string",
  "uploaded_by": "uuid-string",
  "item_type": "photo",
  "title": "Wedding Day 1985",
  "description": "Photo from the family wedding ceremony.",
  "media_url": "https://storage.smriti.health/photos/wedding_1985.jpg",
  "text_content": null,
  "tags": ["family", "wedding"],
  "event_date": "1985-05-20T00:00:00Z"
}
```

**201 Response**: `ReminiscenceItemResponse`.

**Errors**: `401`, `403`, `422`.

---

### 9.2 Get Memory Item

**`GET /memory/items/{item_id}`** — Retrieve a single memory item.

**200 Response**: `ReminiscenceItemResponse`.

**Errors**: `401`, `403`, `404`.

---

### 9.3 List Patient Memory Items

**`GET /patients/{patient_id}/memory`** — Paginated memory items.

**Query Params**: `page`, `page_size`, `item_type` (optional), `tag` (optional).

**200 Response**:
```json
{
  "items": [ ReminiscenceItemResponse, ... ],
  "total": 15,
  "page": 1,
  "page_size": 20
}
```

**Errors**: `401`, `403`.

---

### 9.4 Delete Memory Item

**`DELETE /memory/items/{item_id}`** — Remove a memory item.

**204 Response**: No content.

**Errors**: `401`, `403`, `404`.

---

## 10. Offline Sync

### 10.1 Push Sync

**`POST /sync/push`** — Batch upload pending game attempts and check-ins.

This is the primary sync endpoint. The Flutter app collects all records with status `PENDING` from local SQLite and submits them in one request.

**Request Body** (`SyncPayloadRequest`):
```json
{
  "patient_id": "uuid-string",
  "client_sync_time": "2026-09-07T11:00:00Z",
  "pending_games": [
    {
      "client_attempt_id": "uuid-string",
      "patient_id": "uuid-string",
      "session_id": "uuid-string",
      "game_type": "memory_pairs",
      "difficulty": "easy",
      "score": 85,
      "mistakes": 2,
      "reaction_time_ms": 1100,
      "completion_time_seconds": 38,
      "completed_at": "2026-09-07T10:30:00Z"
    }
  ],
  "pending_checkins": [
    {
      "client_checkin_id": "uuid-string",
      "patient_id": "uuid-string",
      "mood_score": 4,
      "sleep_hours": 7.0,
      "symptoms_noted": null,
      "checkin_time": "2026-09-07T08:00:00Z"
    }
  ]
}
```

**200 Response** (`SyncPayloadResponse`):
```json
{
  "patient_id": "uuid-string",
  "server_sync_time": "2026-09-07T11:00:05Z",
  "games_synced": 1,
  "checkins_synced": 1,
  "game_results": [
    {
      "client_id": "uuid-string",
      "server_id": "server-uuid",
      "status": "SYNCED",
      "error_message": null
    }
  ],
  "checkin_results": [
    {
      "client_id": "uuid-string",
      "server_id": "server-uuid",
      "status": "SYNCED",
      "error_message": null
    }
  ],
  "has_errors": false
}
```

**Per-entity status values**: `SYNCED` (success), `CONFLICT` (duplicate client ID — already exists), `ERROR` (validation or server failure).

**Errors**: `401`, `422`.

---

### 10.2 Sync Status

**`GET /sync/status/{patient_id}`** — Check the last sync timestamp.

**200 Response**:
```json
{
  "patient_id": "uuid-string",
  "last_sync_time": "2026-09-07T11:00:05Z",
  "pending_on_server": 0
}
```

**Errors**: `401`, `403`, `404`.

---

## 11. Alerts

### 11.1 List Patient Alerts

**`GET /patients/{patient_id}/alerts`** — Paginated alert list.

**Query Params**: `page`, `page_size`, `severity` (optional), `status` (optional), `alert_type` (optional).

**200 Response**:
```json
{
  "items": [ AlertResponse, ... ],
  "total": 5,
  "page": 1,
  "page_size": 20
}
```

**Errors**: `401`, `403`.

---

### 11.2 Get Alert

**`GET /alerts/{alert_id}`** — Retrieve a single alert.

**200 Response**: `AlertResponse`.

**Errors**: `401`, `403`, `404`.

---

### 11.3 Acknowledge Alert

**`POST /alerts/{alert_id}/acknowledge`** — Acknowledge, resolve, or dismiss an alert.

**Request Body** (`AlertAcknowledge`):
```json
{
  "alert_id": "uuid-string",
  "acknowledged_by": "uuid-string",
  "status": "acknowledged",
  "notes": "Contacted patient's caregiver. Will follow up tomorrow.",
  "acknowledged_at": "2026-09-07T14:00:00Z"
}
```

**200 Response**: Updated `AlertResponse`.

**Errors**: `401`, `403`, `404`, `422`.

---

### 11.4 Create Alert (Internal / AI)

**`POST /alerts`** — Create a new alert (called by the AI engine or internal services).

**Request Body**: `AlertCreate`.

**201 Response**: `AlertResponse`.

**Errors**: `401`, `403`, `422`.

---

## 12. ASHA Triage

### 12.1 Get Triage Dashboard

**`GET /asha/triage`** — Retrieve the prioritised patient list for the authenticated ASHA worker.

**Headers**: `Authorization: Bearer <token>` (must have role `asha`).

**200 Response** (`AshaTriageResponse`):
```json
{
  "asha_worker_id": "uuid-string",
  "total_patients": 25,
  "urgent_count": 2,
  "monitor_count": 8,
  "stable_count": 15,
  "patients": [
    {
      "patient_id": "uuid-string",
      "patient_name": "Patient Name",
      "age": 72,
      "primary_language": "hi",
      "consent_status": "granted",
      "last_session_date": "2026-09-06T10:00:00Z",
      "last_checkin_date": "2026-09-06T08:00:00Z",
      "average_score_7d": 65.5,
      "average_mood_7d": 3.2,
      "score_trend": "declining",
      "active_alerts_count": 2,
      "highest_alert_severity": "high",
      "triage_priority": "urgent",
      "days_since_last_activity": 1
    }
  ],
  "generated_at": "2026-09-07T14:30:00Z"
}
```

**Errors**: `401`, `403` (not ASHA role).

---

### 12.2 Get Patient Detail (ASHA View)

**`GET /asha/patients/{patient_id}`** — Detailed view of a single patient (ASHA perspective).

Requires `consent_status = granted` for the requesting ASHA worker.

**200 Response**: `AshaPatientSummary` with full metric details.

**Errors**: `401`, `403` (no consent), `404`.

---

## Appendix A: Enum Reference

| Enum | Values |
|---|---|
| `UserRole` | `patient`, `caregiver`, `asha` |
| `GameType` | `memory_pairs`, `odd_one_out`, `simon_says`, `object_naming` |
| `GameDifficulty` | `easy`, `medium`, `hard` |
| `SessionStatus` | `in_progress`, `completed`, `abandoned` |
| `ReminderFrequency` | `once`, `daily`, `weekly`, `custom` |
| `ReminderType` | `medication`, `exercise`, `appointment`, `game_session`, `hydration`, `custom` |
| `ReminderStatus` | `active`, `paused`, `completed`, `cancelled` |
| `MemoryItemType` | `photo`, `audio`, `text` |
| `AlertSeverity` | `low`, `medium`, `high`, `critical` |
| `AlertType` | `cognitive_decline`, `missed_session`, `mood_drop`, `medication_missed`, `abnormal_sleep`, `caregiver_burnout`, `system` |
| `AlertStatus` | `active`, `acknowledged`, `resolved`, `dismissed` |
| `SyncEntityStatus` | `SYNCED`, `CONFLICT`, `ERROR` |
| `TriagePriority` | `stable`, `monitor`, `urgent` |
| `ConsentStatus` | `granted`, `revoked`, `expired` |
| `Gender` | `male`, `female`, `other` |
| `EducationLevel` | `none`, `primary`, `secondary`, `higher_secondary`, `graduate`, `post_graduate` |
| `CognitiveDomain` | `memory`, `attention`, `executive_function`, `language`, `visuospatial` |
| `TrendDirection` | `improving`, `stable`, `declining` |

---

## Appendix B: Pagination Response Envelope

All list endpoints return:

```json
{
  "items": [ ... ],
  "total": 42,
  "page": 1,
  "page_size": 20
}
```

| Field | Type | Description |
|---|---|---|
| `items` | array | Response objects for the current page |
| `total` | int | Total matching records |
| `page` | int | Current page number (1-indexed) |
| `page_size` | int | Items per page |
