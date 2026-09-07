"""
Reminder schemas for the SMRITI platform.

Reminders are caregiver- or system-created notifications pushed to
the patient's device (medication, exercises, appointments, custom).
"""

from datetime import datetime, time
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class ReminderFrequency(str, Enum):
    """How often the reminder repeats."""
    ONCE = "once"
    DAILY = "daily"
    WEEKLY = "weekly"
    CUSTOM = "custom"


class ReminderType(str, Enum):
    """Category of the reminder."""
    MEDICATION = "medication"
    EXERCISE = "exercise"
    APPOINTMENT = "appointment"
    GAME_SESSION = "game_session"
    HYDRATION = "hydration"
    CUSTOM = "custom"


class ReminderStatus(str, Enum):
    """Lifecycle status of a reminder."""
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------

class ReminderCreate(BaseModel):
    """Create a new reminder for a patient."""
    patient_id: str = Field(
        ...,
        description="UUID of the patient receiving the reminder.",
    )
    created_by: str = Field(
        ...,
        description="UUID of the caregiver or ASHA worker setting the reminder.",
    )
    reminder_type: ReminderType = Field(
        ...,
        description="Category of the reminder.",
    )
    title: str = Field(
        ...,
        min_length=1,
        max_length=200,
        description="Short title displayed to the patient.",
    )
    description: Optional[str] = Field(
        default=None,
        max_length=1000,
        description="Detailed instructions or notes.",
    )
    frequency: ReminderFrequency = Field(
        default=ReminderFrequency.DAILY,
        description="Repeat frequency.",
    )
    scheduled_time: time = Field(
        ...,
        description="Time of day to fire the reminder (HH:MM:SS).",
    )
    days_of_week: Optional[List[int]] = Field(
        default=None,
        description="ISO weekday numbers (1=Mon … 7=Sun) for WEEKLY/CUSTOM.",
    )
    start_date: datetime = Field(
        ...,
        description="Date from which the reminder becomes active.",
    )
    end_date: Optional[datetime] = Field(
        default=None,
        description="Optional date after which the reminder auto-expires.",
    )
    voice_prompt_url: Optional[str] = Field(
        default=None,
        max_length=500,
        description="URL to a pre-recorded voice prompt (MP3/WAV).",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------

class ReminderUpdate(BaseModel):
    """Partial update of an existing reminder."""
    title: Optional[str] = Field(
        default=None, min_length=1, max_length=200, description="Updated title."
    )
    description: Optional[str] = Field(
        default=None, max_length=1000, description="Updated description."
    )
    frequency: Optional[ReminderFrequency] = Field(
        default=None, description="Updated frequency."
    )
    scheduled_time: Optional[time] = Field(
        default=None, description="Updated scheduled time."
    )
    days_of_week: Optional[List[int]] = Field(
        default=None, description="Updated weekday list."
    )
    end_date: Optional[datetime] = Field(
        default=None, description="Updated end date."
    )
    status: Optional[ReminderStatus] = Field(
        default=None, description="Updated status (pause / cancel)."
    )
    voice_prompt_url: Optional[str] = Field(
        default=None, max_length=500, description="Updated voice prompt URL."
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

class ReminderResponse(BaseModel):
    """Full reminder record returned by the API."""
    id: str = Field(..., description="Server-assigned reminder UUID.")
    patient_id: str = Field(..., description="Patient UUID.")
    created_by: str = Field(..., description="Creator UUID.")
    reminder_type: ReminderType = Field(..., description="Reminder category.")
    title: str = Field(..., description="Display title.")
    description: Optional[str] = Field(default=None, description="Detail text.")
    frequency: ReminderFrequency = Field(..., description="Repeat frequency.")
    scheduled_time: time = Field(..., description="Daily fire time.")
    days_of_week: Optional[List[int]] = Field(
        default=None, description="Active weekdays."
    )
    start_date: datetime = Field(..., description="Activation date.")
    end_date: Optional[datetime] = Field(default=None, description="Expiry date.")
    status: ReminderStatus = Field(..., description="Current lifecycle status.")
    voice_prompt_url: Optional[str] = Field(
        default=None, description="Voice prompt URL."
    )
    created_at: datetime = Field(..., description="Record creation timestamp.")
    updated_at: datetime = Field(..., description="Last update timestamp.")

    model_config = ConfigDict(from_attributes=True)
