"""Caregiver schemas for SMRITI platform."""

from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field


class CaregiverResponse(BaseModel):
    id: str
    user_id: Optional[str] = None
    name: str
    phone: Optional[str] = None
    relationship_to_patient: Optional[str] = "Family Caregiver"
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ConnectPatientRequest(BaseModel):
    patient_id: Optional[str] = None
    patient_email: Optional[str] = None
    relationship: Optional[str] = "Family Caregiver"


class CaregiverPatientItem(BaseModel):
    patient_id: str
    user_id: str
    full_name: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    date_of_birth: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    dementia_type: Optional[str] = None
    relationship: str = "Family Caregiver"
    preferred_language: Optional[str] = "en"
    status: str = "Active"
    status_color: str = "green"
    reminders_count: int = 0
    baseline_memory: float = 70.0
    asha_name: Optional[str] = None
    asha_phone: Optional[str] = None
    medical_notes: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class AvailablePatientItem(BaseModel):
    patient_id: str
    user_id: str
    full_name: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    is_connected: bool = False

    model_config = ConfigDict(from_attributes=True)


# --- Section 2: Cognitive Analytics Schemas ---

class CognitiveTrendPoint(BaseModel):
    date: str
    memory: float
    attention: float
    engagement: float
    composite: float = 75.0

    model_config = ConfigDict(from_attributes=True)


class PatientAnalyticsResponse(BaseModel):
    patient_id: str
    patient_name: Optional[str] = "Loved One"
    risk_level: str = "STABLE"  # STABLE, MONITOR, ATTENTION_REQUIRED
    risk_score: float = 24.0
    current_memory: float = 76.0
    current_attention: float = 80.0
    current_engagement: float = 72.0
    rolling_memory: float = 76.0
    rolling_attention: float = 80.0
    rolling_engagement: float = 72.0
    composite_score: float = 76.0
    delta_memory_pct: float = -2.5
    delta_attention_pct: float = 1.0
    delta_engagement_pct: float = 0.5
    disclaimer: str = (
        "The prototype cognitive-performance risk score is a decision-support indicator "
        "and is not a medical diagnosis."
    )
    trend: List[CognitiveTrendPoint] = []
    history: List[CognitiveTrendPoint] = []

    model_config = ConfigDict(from_attributes=True)


# --- Section 3: Daily Activity Feed Schemas ---

class GameActivityItem(BaseModel):
    id: str
    game_type: str
    game_name: str = "Calibration Game"
    title: str = "Calibration Game"
    score: float
    mistakes: int = 0
    reaction_time_seconds: Optional[float] = 1.2
    reaction_time_ms: float = 1200.0
    completion_time_seconds: int = 45
    played_at: Optional[str] = None
    completed_at: str

    model_config = ConfigDict(from_attributes=True)


class DailyCheckinSummary(BaseModel):
    id: Optional[str] = None
    mood: Optional[str] = "Good"
    mood_score: int = 4  # 1 to 5 scale
    sleep_hours: float = 7.5
    symptoms: List[str] = []
    symptoms_noted: Optional[str] = "Restful sleep, calm morning"
    notes: Optional[str] = None
    recorded_at: Optional[str] = None
    checkin_time: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class DailyActivityFeedResponse(BaseModel):
    patient_id: str
    date: str
    games: List[GameActivityItem] = []
    games_played: List[GameActivityItem] = []
    checkin: Optional[DailyCheckinSummary] = None

    model_config = ConfigDict(from_attributes=True)


# --- Section 4: Alerts Inbox Schemas ---

class AlertItemResponse(BaseModel):
    id: str
    patient_id: str
    alert_type: str = "GENERAL"
    title: str = "Care Alert"
    message: str = ""
    risk_score: float = 0.0
    risk_level: str = "STABLE"
    severity: str = "INFO"  # INFO, WARNING, CRITICAL
    reason: str = ""
    is_acknowledged: bool = False
    created_at: str

    model_config = ConfigDict(from_attributes=True)


# --- Section 5: Reminiscence Vault Schemas ---

class ReminiscenceItemResponse(BaseModel):
    id: str
    patient_id: str
    title: str
    caption: Optional[str] = None
    person_name: Optional[str] = None
    relationship_label: Optional[str] = None
    relationship_tag: str = "Family"
    media_type: str = "PHOTO"
    media_url: Optional[str] = None
    image_path: str = ""
    audio_path: Optional[str] = None
    notes: Optional[str] = None
    created_at: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ReminiscenceCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=120)
    caption: Optional[str] = None
    person_name: Optional[str] = None
    relationship_label: Optional[str] = None
    relationship_tag: Optional[str] = "Family"
    media_type: Optional[str] = "PHOTO"
    media_url: Optional[str] = None
    image_path: Optional[str] = None
    audio_path: Optional[str] = None
    notes: Optional[str] = None
