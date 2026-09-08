"""
Alert schemas for the SMRITI platform.

Alerts are system- or AI-generated notifications surfaced to
caregivers and ASHA workers when a patient's metrics indicate concern
(e.g., sharp cognitive decline, missed sessions, critical mood drop).
"""

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class AlertSeverity(str, Enum):
    """Urgency level of the alert."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class AlertType(str, Enum):
    """Category of the alert trigger."""
    COGNITIVE_DECLINE = "cognitive_decline"
    MISSED_SESSION = "missed_session"
    MOOD_DROP = "mood_drop"
    MEDICATION_MISSED = "medication_missed"
    ABNORMAL_SLEEP = "abnormal_sleep"
    CAREGIVER_BURNOUT = "caregiver_burnout"
    SYSTEM = "system"


class AlertStatus(str, Enum):
    """Lifecycle status of an alert."""
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"


# ---------------------------------------------------------------------------
# Create (system / AI engine)
# ---------------------------------------------------------------------------

class AlertCreate(BaseModel):
    """Create an alert (typically called by the AI engine or backend)."""
    patient_id: str = Field(
        ...,
        description="UUID of the patient the alert pertains to.",
    )
    alert_type: AlertType = Field(
        ...,
        description="Category of the alert trigger.",
    )
    severity: AlertSeverity = Field(
        ...,
        description="Urgency level.",
    )
    title: str = Field(
        ...,
        min_length=1,
        max_length=200,
        description="Short summary of the alert.",
    )
    message: str = Field(
        ...,
        min_length=1,
        max_length=2000,
        description="Detailed description and recommended action.",
    )
    triggered_by: Optional[str] = Field(
        default=None,
        description="Identifier of the system component that raised the alert.",
    )
    related_entity_id: Optional[str] = Field(
        default=None,
        description="UUID of the game attempt, check-in, or session that triggered this.",
    )
    triggered_at: datetime = Field(
        ...,
        description="Timestamp when the condition was detected.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Acknowledge
# ---------------------------------------------------------------------------

class AlertAcknowledge(BaseModel):
    """Acknowledge or resolve an alert."""
    alert_id: str = Field(
        ...,
        description="UUID of the alert being acknowledged.",
    )
    acknowledged_by: str = Field(
        ...,
        description="UUID of the caregiver or ASHA worker acknowledging.",
    )
    status: AlertStatus = Field(
        default=AlertStatus.ACKNOWLEDGED,
        description="New status (acknowledged / resolved / dismissed).",
    )
    notes: Optional[str] = Field(
        default=None,
        max_length=1000,
        description="Optional notes about the action taken.",
    )
    acknowledged_at: datetime = Field(
        ...,
        description="Timestamp of acknowledgement.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

class AlertResponse(BaseModel):
    """Full alert record returned by the API."""
    id: str = Field(..., description="Server-assigned alert UUID.")
    patient_id: str = Field(..., description="Patient UUID.")
    alert_type: AlertType = Field(..., description="Alert category.")
    severity: AlertSeverity = Field(..., description="Severity level.")
    title: str = Field(..., description="Alert title.")
    message: str = Field(..., description="Alert detail message.")
    status: AlertStatus = Field(..., description="Current lifecycle status.")
    triggered_by: Optional[str] = Field(
        default=None, description="Triggering component."
    )
    related_entity_id: Optional[str] = Field(
        default=None, description="Related entity UUID."
    )
    triggered_at: datetime = Field(..., description="Trigger timestamp.")
    acknowledged_by: Optional[str] = Field(
        default=None, description="Acknowledger UUID."
    )
    acknowledged_at: Optional[datetime] = Field(
        default=None, description="Acknowledgement timestamp."
    )
    notes: Optional[str] = Field(default=None, description="Acknowledgement notes.")
    created_at: datetime = Field(..., description="Record creation timestamp.")
    updated_at: datetime = Field(..., description="Last update timestamp.")

    model_config = ConfigDict(from_attributes=True)
