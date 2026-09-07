"""
ASHA worker schemas for the SMRITI platform.

ASHA (Accredited Social Health Activist) workers use the triage
dashboard to monitor their assigned patients, view cognitive trends,
and prioritise home visits.  Access requires valid patient consent.
"""

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
