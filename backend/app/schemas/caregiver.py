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
    relationship: str = "Family Caregiver"
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
