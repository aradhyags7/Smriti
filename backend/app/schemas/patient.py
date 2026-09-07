"""
Patient schemas for the SMRITI platform.

Covers patient registration, profile updates, full response models,
and baseline cognitive assessment recording.
"""

from datetime import date, datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class Gender(str, Enum):
    """Biological gender for medical context."""
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class EducationLevel(str, Enum):
    """Highest education attained — relevant for cognitive baseline norms."""
    NONE = "none"
    PRIMARY = "primary"
    SECONDARY = "secondary"
    HIGHER_SECONDARY = "higher_secondary"
    GRADUATE = "graduate"
    POST_GRADUATE = "post_graduate"


# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------

class PatientCreate(BaseModel):
    """Register a new patient profile linked to a user account."""
    user_id: str = Field(
        ...,
        description="UUID of the parent user account.",
    )
    date_of_birth: date = Field(
        ...,
        description="Patient's date of birth (YYYY-MM-DD).",
    )
    gender: Gender = Field(
        ...,
        description="Biological gender.",
    )
    education_level: EducationLevel = Field(
        default=EducationLevel.NONE,
        description="Highest education level attained.",
    )
    primary_language: str = Field(
        default="hi",
        max_length=5,
        description="ISO 639-1 code for primary spoken language.",
    )
    emergency_contact_name: str = Field(
        ...,
        min_length=2,
        max_length=120,
        description="Name of emergency contact person.",
    )
    emergency_contact_phone: str = Field(
        ...,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="Emergency contact phone (E.164).",
    )
    medical_notes: Optional[str] = Field(
        default=None,
        max_length=2000,
        description="Free-text medical history notes.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------

class PatientUpdate(BaseModel):
    """Partial update of patient profile."""
    education_level: Optional[EducationLevel] = Field(
        default=None,
        description="Updated education level.",
    )
    primary_language: Optional[str] = Field(
        default=None,
        max_length=5,
        description="Updated primary language code.",
    )
    emergency_contact_name: Optional[str] = Field(
        default=None,
        min_length=2,
        max_length=120,
        description="Updated emergency contact name.",
    )
    emergency_contact_phone: Optional[str] = Field(
        default=None,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="Updated emergency contact phone.",
    )
    medical_notes: Optional[str] = Field(
        default=None,
        max_length=2000,
        description="Updated medical notes.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

class PatientResponse(BaseModel):
    """Full patient record returned from the API."""
    id: str = Field(..., description="Server-assigned patient UUID.")
    user_id: str = Field(..., description="Linked user account UUID.")
    date_of_birth: date = Field(..., description="Date of birth.")
    gender: Gender = Field(..., description="Biological gender.")
    education_level: EducationLevel = Field(..., description="Education level.")
    primary_language: str = Field(..., description="Primary language code.")
    emergency_contact_name: str = Field(..., description="Emergency contact name.")
    emergency_contact_phone: str = Field(..., description="Emergency contact phone.")
    medical_notes: Optional[str] = Field(default=None, description="Medical notes.")
    created_at: datetime = Field(..., description="Record creation timestamp.")
    updated_at: datetime = Field(..., description="Last update timestamp.")

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Baseline Assessment
# ---------------------------------------------------------------------------

class BaselineAssessmentCreate(BaseModel):
    """
    Initial cognitive assessment recorded during patient onboarding.
    Used by the AI engine to calibrate difficulty and detect drift.
    """
    patient_id: str = Field(
        ...,
        description="UUID of the patient being assessed.",
    )
    assessor_id: str = Field(
        ...,
        description="UUID of the ASHA worker or caregiver administering the test.",
    )
    mmse_score: Optional[int] = Field(
        default=None,
        ge=0,
        le=30,
        description="Mini-Mental State Examination score (0–30).",
    )
    moca_score: Optional[int] = Field(
        default=None,
        ge=0,
        le=30,
        description="Montreal Cognitive Assessment score (0–30).",
    )
    clock_drawing_score: Optional[int] = Field(
        default=None,
        ge=0,
        le=10,
        description="Clock Drawing Test score (0–10).",
    )
    verbal_fluency_count: Optional[int] = Field(
        default=None,
        ge=0,
        description="Number of words produced in a verbal fluency test (60 s).",
    )
    assessment_notes: Optional[str] = Field(
        default=None,
        max_length=2000,
        description="Qualitative notes from the assessor.",
    )
    assessed_at: datetime = Field(
        ...,
        description="When the assessment was conducted (ISO 8601).",
    )

    model_config = ConfigDict(from_attributes=True)


class BaselineAssessmentResponse(BaseModel):
    """Stored baseline assessment record."""
    id: str = Field(..., description="Server-assigned assessment UUID.")
    patient_id: str = Field(..., description="Patient UUID.")
    assessor_id: str = Field(..., description="Assessor UUID.")
    mmse_score: Optional[int] = Field(default=None, description="MMSE score.")
    moca_score: Optional[int] = Field(default=None, description="MoCA score.")
    clock_drawing_score: Optional[int] = Field(default=None, description="Clock drawing score.")
    verbal_fluency_count: Optional[int] = Field(default=None, description="Verbal fluency word count.")
    assessment_notes: Optional[str] = Field(default=None, description="Assessor notes.")
    assessed_at: datetime = Field(..., description="Assessment timestamp.")
    created_at: datetime = Field(..., description="Record creation timestamp.")

    model_config = ConfigDict(from_attributes=True)
