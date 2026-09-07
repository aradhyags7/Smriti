# Offline Sync Flow — SMRITI Platform

> **Owner**: Tanishka Sawant (Integration Lead)  
> **Last Updated**: 2026-09-07

---

## Overview

SMRITI uses an **offline-first** architecture. The Flutter mobile app is designed to function fully without network connectivity. All game attempts and daily check-ins are persisted locally in SQLite and synchronised to the backend PostgreSQL database when connectivity is restored.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUTTER MOBILE APP                          │
│                                                                     │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │  Game UI  │───▶│ Game Engine  │───▶│   Local SQLite Database  │  │
│  │ Check-in  │    │  (Dart)      │    │                          │  │
│  │   UI      │    └──────────────┘    │  game_attempts table     │  │
│  └──────────┘                         │    status: PENDING       │  │
│                                       │  daily_checkins table    │  │
│                                       │    status: PENDING       │  │
│                                       └──────────┬───────────────┘  │
│                                                  │                  │
│  ┌──────────────────┐                           │                  │
│  │ Connectivity      │◀──────────────────────────┘                  │
│  │ Monitor (Dart)    │                                              │
│  │                   │──── Network detected ────▶ Sync Service      │
│  └──────────────────┘                           │                  │
│                                                  │                  │
│  ┌──────────────────────────────────────────────▼───────────────┐  │
│  │                     SYNC SERVICE (Dart)                       │  │
│  │  1. Query SQLite for all records with status = PENDING        │  │
│  │  2. Bundle into SyncPayloadRequest                            │  │
│  │  3. POST /api/v1/sync/push                                    │  │
│  │  4. Parse SyncPayloadResponse                                 │  │
│  │  5. Update each record: PENDING → SYNCED | ERROR              │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS (JSON)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       BACKEND (FastAPI)                             │
│                                                                     │
│  POST /api/v1/sync/push                                             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                   SYNC ENDPOINT HANDLER                       │  │
│  │  1. Validate JWT token & extract patient_id                   │  │
│  │  2. Deserialise SyncPayloadRequest (Pydantic v2)              │  │
│  │  3. Begin PostgreSQL transaction                               │  │
│  │  4. For each pending_game:                                     │  │
│  │     a. Check client_attempt_id uniqueness (idempotency)        │  │
│  │     b. If duplicate → return CONFLICT                          │  │
│  │     c. If new → INSERT into game_attempts, return SYNCED       │  │
│  │  5. For each pending_checkin:                                  │  │
│  │     a. Check client_checkin_id uniqueness (idempotency)        │  │
│  │     b. If duplicate → return CONFLICT                          │  │
│  │     c. If new → INSERT into daily_checkins, return SYNCED      │  │
│  │  6. Commit transaction                                         │  │
│  │  7. Return SyncPayloadResponse with per-entity results         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│                              ▼                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     POSTGRESQL DATABASE                       │  │
│  │                                                                │  │
│  │  game_attempts                    daily_checkins               │  │
│  │  ├── id (UUID, PK)               ├── id (UUID, PK)           │  │
│  │  ├── client_attempt_id (UNIQUE)   ├── client_checkin_id (UQ)  │  │
│  │  ├── patient_id (FK)             ├── patient_id (FK)          │  │
│  │  ├── session_id (FK, nullable)   ├── mood_score               │  │
│  │  ├── game_type                    ├── sleep_hours              │  │
│  │  ├── difficulty                   ├── symptoms_noted           │  │
│  │  ├── score                        ├── checkin_time             │  │
│  │  ├── mistakes                     ├── sync_status              │  │
│  │  ├── reaction_time_ms             └── created_at               │  │
│  │  ├── completion_time_seconds                                   │  │
│  │  ├── completed_at                                              │  │
│  │  ├── sync_status                                               │  │
│  │  └── created_at                                                │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Lifecycle

### Phase 1: Local Data Creation (Offline)

| Step | Actor | Action | Detail |
|---|---|---|---|
| 1 | Patient | Plays a cognitive game | Flutter game UI records all metrics |
| 2 | Game Engine | Generates `client_attempt_id` | UUID v4 created locally by `uuid` package |
| 3 | Game Engine | Builds `GameAttemptCreate` payload | All required fields populated: `score`, `mistakes`, `reaction_time_ms`, `completion_time_seconds`, `game_type`, `difficulty` |
| 4 | Game Engine | Inserts into SQLite | `game_attempts` table, `sync_status = 'PENDING'` |
| 5 | Patient | Completes daily check-in | Mood, sleep, symptoms captured |
| 6 | Check-in Service | Generates `client_checkin_id` | UUID v4 created locally |
| 7 | Check-in Service | Inserts into SQLite | `daily_checkins` table, `sync_status = 'PENDING'` |

### Phase 2: Network Detection

| Step | Actor | Action | Detail |
|---|---|---|---|
| 8 | Connectivity Monitor | Detects network availability | Uses `connectivity_plus` Flutter package |
| 9 | Connectivity Monitor | Triggers Sync Service | Only if there are records with `sync_status = 'PENDING'` |

### Phase 3: Batch Sync Push

| Step | Actor | Action | Detail |
|---|---|---|---|
| 10 | Sync Service | Queries SQLite | `SELECT * FROM game_attempts WHERE sync_status = 'PENDING'` |
| 11 | Sync Service | Queries SQLite | `SELECT * FROM daily_checkins WHERE sync_status = 'PENDING'` |
| 12 | Sync Service | Builds `SyncPayloadRequest` | Bundles all pending records with `patient_id` and `client_sync_time` |
| 13 | Sync Service | HTTP POST | `POST /api/v1/sync/push` with Bearer token |
| 14 | Backend | Validates request | Pydantic v2 deserialization, JWT verification |
| 15 | Backend | Processes each entity | Idempotency check on `client_attempt_id` / `client_checkin_id` |
| 16 | Backend | Persists in PostgreSQL | Wrapped in a single database transaction |
| 17 | Backend | Returns `SyncPayloadResponse` | Per-entity `SyncEntityResult` with `server_id` and `status` |

### Phase 4: Local Status Update

| Step | Actor | Action | Detail |
|---|---|---|---|
| 18 | Sync Service | Parses response | Iterates over `game_results` and `checkin_results` |
| 19 | Sync Service | Updates SQLite | For each entity: `UPDATE SET sync_status = 'SYNCED', server_id = ?` |
| 20 | Sync Service | Handles errors | `CONFLICT` → mark as SYNCED (already exists). `ERROR` → keep PENDING for retry |

---

## State Machine

```
                ┌───────────────┐
                │               │
    Create ────▶│    PENDING    │
                │               │
                └───────┬───────┘
                        │
                  Network detected
                  + sync push
                        │
                ┌───────▼───────┐
                │               │
     ┌──────── │   SYNCING...   │ ────────┐
     │          │               │          │
     │          └───────────────┘          │
     │                                     │
     ▼                                     ▼
┌─────────┐                          ┌─────────┐
│         │                          │         │
│ SYNCED  │                          │  ERROR  │──── Retry on next
│         │                          │         │     network event
└─────────┘                          └─────────┘
```

---

## Idempotency Guarantees

The sync system is designed to be **idempotent** and **safe to retry**:

1. **Client UUIDs as natural keys**: `client_attempt_id` and `client_checkin_id` are unique constraints in PostgreSQL. Submitting the same record twice results in a `CONFLICT` response (not an error).

2. **Transaction safety**: All entities in a single sync push are wrapped in one PostgreSQL transaction. Either all succeed or all roll back.

3. **At-least-once delivery**: The client retries on `ERROR` status. The server handles duplicates gracefully via the uniqueness constraint.

---

## Conflict Resolution

| Scenario | Server Behaviour | Client Behaviour |
|---|---|---|
| First submission | `SYNCED` — record inserted | Mark local record as `SYNCED` |
| Duplicate `client_id` | `CONFLICT` — no insert | Mark local record as `SYNCED` (already on server) |
| Validation failure | `ERROR` with message | Keep as `PENDING`, log error for debugging |
| Network timeout | No response | Keep as `PENDING`, retry on next connectivity event |
| Server crash mid-transaction | Transaction rolls back | Keep as `PENDING`, retry on next connectivity event |

---

## Retry Policy

| Parameter | Value |
|---|---|
| Trigger | Network connectivity restored |
| Initial delay | 0 seconds (immediate) |
| Backoff | Exponential: 1s → 2s → 4s → 8s → 16s → 30s (cap) |
| Max retries per sync cycle | 5 |
| Retry on | `ERROR` status entities, network failures |
| No retry on | `SYNCED`, `CONFLICT` |

---

## SQLite Schema (Client)

```sql
CREATE TABLE game_attempts (
    id                      INTEGER PRIMARY KEY AUTOINCREMENT,
    client_attempt_id       TEXT NOT NULL UNIQUE,
    server_id               TEXT,
    patient_id              TEXT NOT NULL,
    session_id              TEXT,
    game_type               TEXT NOT NULL,
    difficulty              TEXT NOT NULL,
    score                   INTEGER NOT NULL CHECK(score >= 0 AND score <= 100),
    mistakes                INTEGER NOT NULL CHECK(mistakes >= 0),
    reaction_time_ms        INTEGER NOT NULL CHECK(reaction_time_ms >= 0),
    completion_time_seconds INTEGER NOT NULL CHECK(completion_time_seconds >= 0),
    completed_at            TEXT NOT NULL,
    sync_status             TEXT NOT NULL DEFAULT 'PENDING' CHECK(sync_status IN ('PENDING', 'SYNCED', 'ERROR')),
    created_at              TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_attempt       TEXT
);

CREATE TABLE daily_checkins (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    client_checkin_id   TEXT NOT NULL UNIQUE,
    server_id           TEXT,
    patient_id          TEXT NOT NULL,
    mood_score          INTEGER NOT NULL CHECK(mood_score >= 1 AND mood_score <= 5),
    sleep_hours         REAL NOT NULL CHECK(sleep_hours >= 0.0 AND sleep_hours <= 24.0),
    appetite_rating     INTEGER CHECK(appetite_rating >= 1 AND appetite_rating <= 5),
    energy_level        INTEGER CHECK(energy_level >= 1 AND energy_level <= 5),
    symptoms_noted      TEXT,
    checkin_time        TEXT NOT NULL,
    sync_status         TEXT NOT NULL DEFAULT 'PENDING' CHECK(sync_status IN ('PENDING', 'SYNCED', 'ERROR')),
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_attempt   TEXT
);

CREATE INDEX idx_game_attempts_sync ON game_attempts(sync_status);
CREATE INDEX idx_daily_checkins_sync ON daily_checkins(sync_status);
```

---

## Monitoring & Observability

| Metric | Source | Purpose |
|---|---|---|
| `sync_push_total` | Backend (counter) | Total sync push requests received |
| `sync_entities_synced` | Backend (counter) | Entities successfully synced (by type) |
| `sync_entities_conflict` | Backend (counter) | Duplicate submissions detected |
| `sync_entities_error` | Backend (counter) | Failed entity syncs |
| `sync_latency_ms` | Backend (histogram) | End-to-end sync processing time |
| `pending_records_gauge` | Client (gauge) | Number of PENDING records in SQLite |
| `time_since_last_sync` | Client (gauge) | Seconds since last successful sync |
