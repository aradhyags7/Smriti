# Authentication Flow — SMRITI Platform

> **Owner**: Tanishka Sawant (Integration Lead)  
> **Last Updated**: 2026-09-07

---

## Overview

SMRITI uses a **PIN-based authentication** system optimised for low-literacy users in rural India. Phone numbers serve as the primary identifier. JSON Web Tokens (JWT) secure all API communication. The system supports three roles with distinct access levels and enforces consent verification for ASHA worker access.

---

## Authentication Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│                         FLUTTER MOBILE APP                           │
│                                                                       │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────────────┐  │
│  │  Login       │───▶│  Auth        │───▶│  Secure Token Storage   │  │
│  │  Screen      │    │  Service     │    │  (flutter_secure_       │  │
│  │  (PIN Pad)   │    │  (Dart)      │    │   storage)              │  │
│  └─────────────┘    └──────────────┘    │                          │  │
│                                          │  access_token            │  │
│                                          │  refresh_token           │  │
│                                          │  user_role               │  │
│                                          └─────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│                        BACKEND (FastAPI)                              │
│                                                                       │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐    │
│  │  Auth Router  │───▶│  Auth        │───▶│  JWT Manager          │    │
│  │  /auth/*      │    │  Service     │    │  (python-jose)        │    │
│  └──────────────┘    └──────┬───────┘    │                        │    │
│                             │            │  sign(payload,secret)   │    │
│                             ▼            │  verify(token,secret)   │    │
│                      ┌──────────────┐    └──────────────────────┘    │
│                      │  User Repo    │                                │
│                      │  (SQLAlchemy) │                                │
│                      └──────┬───────┘                                │
│                             ▼                                        │
│                      ┌──────────────┐                                │
│                      │  PostgreSQL   │                                │
│                      │  users table  │                                │
│                      └──────────────┘                                │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Flow 1: User Registration (Sign Up)

```
Client                          Backend
  │                                │
  │  POST /api/v1/auth/signup      │
  │  {phone, full_name, role, pin} │
  │ ──────────────────────────────▶│
  │                                │
  │                                ├── Validate phone format (E.164)
  │                                ├── Check phone uniqueness in DB
  │                                ├── Hash PIN (bcrypt via passlib)
  │                                ├── Create user record in PostgreSQL
  │                                ├── Assign role (patient|caregiver|asha)
  │                                │
  │  201 { UserResponse }          │
  │ ◀──────────────────────────────│
  │                                │
```

### PIN Security

| Parameter | Value |
|---|---|
| Algorithm | bcrypt (via `passlib[bcrypt]`) |
| Rounds | 12 (default) |
| PIN Length | 4–6 numeric digits |
| Storage | Hashed — plain PIN never stored |

---

## Flow 2: Login (PIN Authentication)

```
Client                          Backend
  │                                │
  │  POST /api/v1/auth/login       │
  │  {phone_number, pin}           │
  │ ──────────────────────────────▶│
  │                                │
  │                                ├── Look up user by phone_number
  │                                ├── Verify PIN hash (bcrypt.verify)
  │                                ├── Check account is_active = true
  │                                ├── Generate access_token (JWT)
  │                                ├── Generate refresh_token (JWT)
  │                                │
  │  200 { TokenResponse }         │
  │  {access_token, refresh_token, │
  │   token_type, expires_in,      │
  │   user_id, role}               │
  │ ◀──────────────────────────────│
  │                                │
  │  Store tokens in secure storage│
  │                                │
```

### JWT Token Structure

**Access Token Payload**:
```json
{
  "sub": "user-uuid",
  "role": "caregiver",
  "phone": "+919876543210",
  "iat": 1725700000,
  "exp": 1725703600,
  "type": "access"
}
```

**Refresh Token Payload**:
```json
{
  "sub": "user-uuid",
  "iat": 1725700000,
  "exp": 1728292000,
  "type": "refresh"
}
```

| Token | Lifetime | Purpose |
|---|---|---|
| Access Token | 1 hour (3600 s) | API request authentication |
| Refresh Token | 30 days | Silent re-authentication without PIN |

### JWT Configuration

| Parameter | Value |
|---|---|
| Algorithm | HS256 |
| Secret | `JWT_SECRET_KEY` from environment |
| Issuer | `smriti-auth-service` |
| Library | `python-jose[cryptography]` |

---

## Flow 3: Token Refresh

```
Client                          Backend
  │                                │
  │  access_token expired          │
  │                                │
  │  POST /api/v1/auth/refresh     │
  │  {refresh_token}               │
  │ ──────────────────────────────▶│
  │                                │
  │                                ├── Verify refresh_token signature
  │                                ├── Check token type = "refresh"
  │                                ├── Check token not expired
  │                                ├── Check user is_active = true
  │                                ├── Generate new access_token
  │                                ├── Generate new refresh_token
  │                                ├── (Optionally) invalidate old refresh
  │                                │
  │  200 { TokenResponse }         │
  │ ◀──────────────────────────────│
  │                                │
```

---

## Flow 4: OTP Verification

Used for phone number verification during signup and PIN recovery.

```
Client                          Backend                     SMS Provider
  │                                │                            │
  │  POST /auth/otp/request        │                            │
  │  {phone_number}                │                            │
  │ ──────────────────────────────▶│                            │
  │                                ├── Generate 6-digit OTP     │
  │                                ├── Store OTP (5 min TTL)    │
  │                                ├── Send SMS ───────────────▶│
  │                                │                            │
  │  200 {message, expires_in}     │                            │
  │ ◀──────────────────────────────│                            │
  │                                │                            │
  │  (User receives SMS)           │                            │
  │                                │                            │
  │  POST /auth/otp/verify         │                            │
  │  {phone_number, otp_code}      │                            │
  │ ──────────────────────────────▶│                            │
  │                                ├── Retrieve stored OTP      │
  │                                ├── Compare codes             │
  │                                ├── Check TTL not expired     │
  │                                ├── Mark phone as verified    │
  │                                │                            │
  │  200 {verified: true}          │                            │
  │ ◀──────────────────────────────│                            │
```

### OTP Security Parameters

| Parameter | Value |
|---|---|
| Code length | 6 digits |
| TTL | 300 seconds (5 minutes) |
| Max attempts | 3 per OTP |
| Rate limit | 1 OTP request per 60 seconds per phone |
| Storage | Server-side cache (Redis or in-memory with TTL) |

---

## Flow 5: PIN Recovery (Forgot PIN)

```
Client                          Backend
  │                                │
  │  POST /auth/otp/request        │  (Step 1: Request OTP)
  │  {phone_number}                │
  │ ──────────────────────────────▶│
  │  200 {message}                 │
  │ ◀──────────────────────────────│
  │                                │
  │  POST /auth/forgot-pin         │  (Step 2: Reset with verified OTP)
  │  {phone_number, otp_code,      │
  │   new_pin}                     │
  │ ──────────────────────────────▶│
  │                                ├── Verify OTP (same as Flow 4)
  │                                ├── Hash new PIN (bcrypt)
  │                                ├── Update user record
  │                                ├── Invalidate all existing tokens
  │                                │
  │  200 {message: "PIN reset"}    │
  │ ◀──────────────────────────────│
```

---

## Flow 6: ASHA Worker Consent Enforcement

ASHA workers can only access patient data if the patient (or their caregiver) has explicitly granted consent. The consent is checked on **every request** to patient-scoped endpoints.

```
ASHA Worker App                 Backend                     PostgreSQL
  │                                │                            │
  │  GET /asha/patients/{id}       │                            │
  │  Authorization: Bearer <token> │                            │
  │ ──────────────────────────────▶│                            │
  │                                │                            │
  │                                ├── Verify JWT                │
  │                                ├── Extract role = "asha"     │
  │                                ├── Extract asha_worker_id    │
  │                                │                            │
  │                                │  SELECT consent_status      │
  │                                │  FROM patient_consents      │
  │                                │  WHERE patient_id = ?       │
  │                                │  AND asha_worker_id = ?     │
  │                                │ ──────────────────────────▶│
  │                                │                            │
  │                                │  consent_status = ?         │
  │                                │ ◀──────────────────────────│
  │                                │                            │
  │                                ├── IF "granted" → proceed    │
  │                                ├── IF "revoked" → 403        │
  │                                ├── IF "expired" → 403        │
  │                                ├── IF not found → 403        │
  │                                │                            │
  │  200 { patient data }          │                            │
  │  OR                            │                            │
  │  403 { "Consent not granted" } │                            │
  │ ◀──────────────────────────────│                            │
```

### Consent Database Schema

```sql
CREATE TABLE patient_consents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    asha_worker_id  UUID NOT NULL REFERENCES users(id),
    consent_status  VARCHAR(10) NOT NULL DEFAULT 'granted'
                    CHECK(consent_status IN ('granted', 'revoked', 'expired')),
    granted_by      UUID NOT NULL REFERENCES users(id),
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at      TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    UNIQUE(patient_id, asha_worker_id)
);

CREATE INDEX idx_consent_lookup ON patient_consents(patient_id, asha_worker_id, consent_status);
```

### Consent Rules

| Rule | Detail |
|---|---|
| Who grants | Patient (self) or their registered Caregiver |
| Who revokes | Patient, Caregiver, or System (on expiry) |
| Default expiry | 90 days from grant date |
| Check frequency | Every API request to patient-scoped ASHA endpoints |
| Scope | Per patient–ASHA worker pair |

---

## RBAC Middleware Pipeline

Every protected API request passes through this middleware chain:

```
Request
  │
  ▼
┌─────────────────────┐
│ 1. Extract Bearer    │──── Missing? → 401 Unauthorized
│    Token from Header │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 2. Verify JWT        │──── Invalid/Expired? → 401 Unauthorized
│    Signature & Expiry│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 3. Extract Claims    │
│    (sub, role)       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 4. Check Role        │──── Insufficient role? → 403 Forbidden
│    Permission        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 5. Consent Check     │──── Only for ASHA role
│    (ASHA only)       │──── No consent? → 403 Forbidden
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 6. Route Handler     │──── Process request
└─────────────────────┘
```

---

## Role Permission Matrix

| Endpoint Pattern | PATIENT | CAREGIVER | ASHA |
|---|---|---|---|
| `GET /users/me` | ✅ | ✅ | ✅ |
| `PATCH /users/me` | ✅ | ✅ | ✅ |
| `POST /patients` | ❌ | ✅ | ✅ |
| `GET /patients/{id}` | ✅ (own) | ✅ (linked) | ✅ (consent) |
| `POST /games/attempts` | ✅ | ❌ | ❌ |
| `GET /patients/{id}/games` | ✅ (own) | ✅ (linked) | ✅ (consent) |
| `POST /checkins` | ✅ | ❌ | ❌ |
| `POST /reminders` | ❌ | ✅ | ✅ |
| `POST /sync/push` | ✅ | ❌ | ❌ |
| `GET /asha/triage` | ❌ | ❌ | ✅ |
| `POST /alerts` | ❌ | ❌ | ❌ (system only) |
| `POST /alerts/{id}/acknowledge` | ❌ | ✅ | ✅ |

---

## Security Considerations

| Concern | Mitigation |
|---|---|
| PIN brute force | Account lockout after 5 failed attempts (15 min cooldown) |
| Token theft | Short-lived access tokens (1 hour), HTTPS only |
| Replay attacks | JWT includes `iat` and `exp` claims |
| Consent bypass | Server-side consent check on every ASHA request |
| Data exfiltration | Role-based data scoping — users can only access their own or linked data |
| Token storage | `flutter_secure_storage` uses Keychain (iOS) / EncryptedSharedPreferences (Android) |
