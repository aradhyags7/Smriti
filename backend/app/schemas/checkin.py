"""
Daily check-in schemas for the SMRITI platform.

Check-ins capture the patient's self-reported wellbeing data (mood,
sleep, symptoms) outside of game sessions.  Like game attempts, they
are created offline-first with a client UUID and synced later.
"""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------

class DailyCheckinCreate(BaseModel):
    """
    Single daily check-in submitted by the mobile app.

    The client generates `client_checkin_id` locally so it can be stored
    in SQLite with status PENDING and batch-synced via /api/v1/sync/push.
    """
    client_checkin_id: str = Field(
        ...,
        description="Client-generated UUID v4 for idempotent sync.",
    )
    patient_id: str = Field(
        ...,
        description="UUID of the patient checking in.",
    )
    mood_score: int = Field(
        ...,
        ge=1,
        le=5,
        description="Self-reported mood (1 = very low, 5 = very good).",
    )
    sleep_hours: float = Field(
        ...,
        ge=0.0,
        le=24.0,
        description="Hours of sleep in the preceding night.",
    )
    appetite_rating: Optional[int] = Field(
        default=None,
        ge=1,
        le=5,
        description="Optional appetite self-rating (1–5).",
    )
    energy_level: Optional[int] = Field(
        default=None,
        ge=1,
        le=5,
        description="Optional energy/fatigue self-rating (1–5).",
    )
    symptoms_noted: Optional[str] = Field(
        default=None,
        max_length=1000,
        description="Free-text symptoms or observations.",
    )
    checkin_time: datetime = Field(
        ...,
        description="Client-side timestamp of the check-in (ISO 8601).",
    )

    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "client_checkin_id": "c1d2e3f4-a5b6-7890-cdef-1234567890ab",
                "patient_id": "p-uuid-001",
                "mood_score": 4,
                "sleep_hours": 7.5,
                "appetite_rating": 3,
                "energy_level": 4,
                "symptoms_noted": "Mild headache in the morning",
                "checkin_time": "2026-09-07T08:00:00Z",
            }
        },
    )


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

class DailyCheckinResponse(BaseModel):
    """Full check-in record returned by the API."""
    id: str = Field(..., description="Server-assigned check-in UUID.")
    client_checkin_id: str = Field(..., description="Client-generated UUID.")
    patient_id: str = Field(..., description="Patient UUID.")
    mood_score: int = Field(..., ge=1, le=5, description="Mood score (1–5).")
    sleep_hours: float = Field(..., ge=0.0, le=24.0, description="Sleep hours.")
    appetite_rating: Optional[int] = Field(
        default=None, ge=1, le=5, description="Appetite rating."
    )
    energy_level: Optional[int] = Field(
        default=None, ge=1, le=5, description="Energy level."
    )
    symptoms_noted: Optional[str] = Field(
        default=None, description="Symptom notes."
    )
    checkin_time: datetime = Field(..., description="Original check-in timestamp.")
    sync_status: str = Field(
        default="SYNCED",
        description="Sync state: PENDING | SYNCED.",
    )
    created_at: datetime = Field(..., description="Server record creation timestamp.")

    model_config = ConfigDict(from_attributes=True)
