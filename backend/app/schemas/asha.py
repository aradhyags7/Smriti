"""ASHA Worker schemas for SMRITI platform."""

from datetime import datetime
from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field

from .alert import AlertSeverity


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class TriagePriority(str, Enum):
    """AI-computed triage tier for ASHA visit prioritisation."""
    STABLE = "stable"
    MONITOR = "monitor"
    URGENT = "urgent"


class ConsentStatus(str, Enum):
    """Patient consent state for ASHA data access."""
    GRANTED = "granted"
    REVOKED = "revoked"
    EXPIRED = "expired"


# ---------------------------------------------------------------------------
# Patient Summary (read-only view for ASHA)
# ---------------------------------------------------------------------------

class AshaPatientSummary(BaseModel):
    """
    Condensed patient card shown on the ASHA triage dashboard.
    Contains latest cognitive scores, mood trends, and alert counts.
    """
    patient_id: str = Field(..., description="Patient UUID.")
    patient_name: str = Field(..., description="Patient's full name.")
    age: int = Field(..., ge=0, description="Patient's age in years.")
    primary_language: str = Field(..., description="Patient's primary language code.")
    consent_status: ConsentStatus = Field(
        ...,
        description="Current consent state (must be 'granted' for access).",
    )
    last_session_date: Optional[datetime] = Field(
        default=None,
        description="Date of the patient's most recent game session.",
    )
    last_checkin_date: Optional[datetime] = Field(
        default=None,
        description="Date of the patient's most recent daily check-in.",
    )
    average_score_7d: Optional[float] = Field(
        default=None,
        ge=0.0,
        le=100.0,
        description="Mean game score over the last 7 days.",
    )
    average_mood_7d: Optional[float] = Field(
        default=None,
        ge=1.0,
        le=5.0,
        description="Mean mood score over the last 7 days.",
    )
    score_trend: Optional[str] = Field(
        default=None,
        description="Trend direction: 'improving', 'stable', or 'declining'.",
    )
    active_alerts_count: int = Field(
        default=0,
        ge=0,
        description="Number of unresolved alerts for this patient.",
    )
    highest_alert_severity: Optional[AlertSeverity] = Field(
        default=None,
        description="Severity of the most critical active alert.",
    )
    triage_priority: TriagePriority = Field(
        ...,
        description="AI-computed triage priority.",
    )
    days_since_last_activity: Optional[int] = Field(
        default=None,
        ge=0,
        description="Days since the patient last interacted with the app.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Triage Response
# ---------------------------------------------------------------------------

class AshaTriageResponse(BaseModel):
    """
    Full triage dashboard response for an ASHA worker.
    Returns a list of patient summaries sorted by priority.
    """
    asha_worker_id: str = Field(
        ...,
        description="UUID of the requesting ASHA worker.",
    )
    total_patients: int = Field(
        ...,
        ge=0,
        description="Total patients assigned to this ASHA worker.",
    )
    urgent_count: int = Field(
        default=0,
        ge=0,
        description="Number of patients in URGENT priority.",
    )
    monitor_count: int = Field(
        default=0,
        ge=0,
        description="Number of patients in MONITOR priority.",
    )
    stable_count: int = Field(
        default=0,
        ge=0,
        description="Number of patients in STABLE priority.",
    )
    patients: List[AshaPatientSummary] = Field(
        default_factory=list,
        description="Patient summaries sorted by triage priority (urgent first).",
    )
    generated_at: datetime = Field(
        ...,
        description="Server timestamp when the triage was computed.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Dynamic Assignment & Portal Schemas
# ---------------------------------------------------------------------------

class AshaWorkerResponse(BaseModel):
    id: str
    user_id: Optional[str] = None
    name: str
    phone: Optional[str] = None
    village_assigned: str
    district: str
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class AssignPatientRequest(BaseModel):
    patient_id: str
    village_notes: Optional[str] = None


class AshaPatientItem(BaseModel):
    patient_id: str
    user_id: str
    full_name: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    age: Optional[int] = 72
    gender: Optional[str] = "other"
    dementia_type: Optional[str] = None
    village: str = "Guwahati Sector"
    district: str = "Kamrup"
    status: str = "Stable"
    status_color: str = "green"
    consent_for_asha: bool = True
    caregiver_name: Optional[str] = None
    caregiver_phone: Optional[str] = None
    baseline_memory: float = 70.0
    last_visit: str = "Recent"

    model_config = ConfigDict(from_attributes=True)


class CommunityPatientItem(BaseModel):
    patient_id: str
    user_id: str
    full_name: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    is_assigned: bool = False
    assigned_asha_name: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class CareCircleResponse(BaseModel):
    caregiver: Optional[dict] = None
    asha_worker: Optional[dict] = None
    patient_name: str
    patient_email: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
