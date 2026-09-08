"""ASHA Worker schemas for SMRITI platform."""

from datetime import datetime
from enum import Enum
from typing import List, Optional, Any
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
    """Condensed patient card shown on the ASHA triage dashboard."""
    patient_id: str = Field(..., description="Patient UUID.")
    patient_name: str = Field(..., description="Patient's full name.")
    age: int = Field(..., ge=0, description="Patient's age in years.")
    primary_language: str = Field(..., description="Patient's primary language code.")
    consent_status: ConsentStatus = Field(
        ...,
        description="Current consent state (must be 'granted' for access).",
    )
    last_session_date: Optional[datetime] = None
    last_checkin_date: Optional[datetime] = None
    average_score_7d: Optional[float] = None
    average_mood_7d: Optional[float] = None
    score_trend: Optional[str] = None
    active_alerts_count: int = 0
    highest_alert_severity: Optional[AlertSeverity] = None
    triage_priority: TriagePriority = TriagePriority.STABLE
    days_since_last_activity: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class AshaTriageResponse(BaseModel):
    """Full triage dashboard response for an ASHA worker."""
    asha_worker_id: str
    total_patients: int = 0
    critical_count: int = 0
    attention_count: int = 0
    monitor_count: int = 0
    stable_count: int = 0
    patients: List["AshaPatientItem"] = Field(default_factory=list)
    generated_at: datetime

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
    triage_priority: str = "STABLE"  # CRITICAL, ATTENTION_REQUIRED, MONITOR, STABLE
    consent_for_asha: bool = True
    caregiver_name: Optional[str] = None
    caregiver_phone: Optional[str] = None
    caregiver_relationship: Optional[str] = "Family Caregiver"
    baseline_memory: float = 70.0
    baseline_attention: float = 70.0
    baseline_engagement: float = 70.0
    primary_language: str = "en"
    medical_notes: Optional[str] = None
    last_visit: str = "Recent"
    unresolved_alerts_count: int = 0

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


class EmergencyAlertItem(BaseModel):
    id: str
    patient_id: str
    patient_name: str
    patient_age: Optional[int] = 72
    risk_level: str  # CRITICAL, ATTENTION_REQUIRED, MONITOR
    severity: str    # HIGH, MEDIUM, LOW
    reason: str
    is_acknowledged: bool = False
    created_at: str

    model_config = ConfigDict(from_attributes=True)


class UpdateMedicalNotesRequest(BaseModel):
    notes: str
    visit_date: Optional[str] = None


class AshaPatientDetailResponse(BaseModel):
    patient: AshaPatientItem
    analytics: Optional[dict] = None
    activity_feed: Optional[dict] = None
    alerts: List[EmergencyAlertItem] = Field(default_factory=list)
    medical_notes_history: List[str] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)
