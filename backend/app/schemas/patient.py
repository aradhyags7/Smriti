"""Patient schemas for creation and profile retrieval."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class PatientCreate(BaseModel):
    """Payload for registering a new patient."""
    id: str
    name: str
    age: int
    gender: str
    primary_language: Optional[str] = "en"
    user_id: Optional[int] = None
    caregiver_id: Optional[int] = None
    asha_id: Optional[int] = None


class PatientOut(BaseModel):
    """Patient response schema with ORM mode enabled."""
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: Optional[int] = None
    name: str
    age: int
    gender: Optional[str] = None
    primary_language: Optional[str] = "en"
    caregiver_id: Optional[int] = None
    asha_id: Optional[int] = None
    created_at: Optional[datetime] = None
