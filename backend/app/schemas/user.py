"""
User schemas for the SMRITI platform.

Covers base user fields, profile updates, and user response models.
Shared across all three roles (PATIENT, CAREGIVER, ASHA).
"""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from .auth import UserRole


# ---------------------------------------------------------------------------
# Base
# ---------------------------------------------------------------------------

class UserBase(BaseModel):
    """Common user fields shared by create and read operations."""
    full_name: str = Field(
        ...,
        min_length=2,
        max_length=120,
        description="Full name of the user.",
    )
    phone_number: str = Field(
        ...,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="E.164-formatted phone number (primary identifier).",
    )
    role: UserRole = Field(
        ...,
        description="User role in the system.",
    )
    email: Optional[EmailStr] = Field(
        default=None,
        description="Optional email for notifications.",
    )
    preferred_language: str = Field(
        default="en",
        max_length=5,
        description="ISO 639-1 language code.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------

class UserUpdate(BaseModel):
    """Partial update payload — all fields optional."""
    full_name: Optional[str] = Field(
        default=None,
        min_length=2,
        max_length=120,
        description="Updated full name.",
    )
    email: Optional[EmailStr] = Field(
        default=None,
        description="Updated email address.",
    )
    preferred_language: Optional[str] = Field(
        default=None,
        max_length=5,
        description="Updated language preference.",
    )
    is_active: Optional[bool] = Field(
        default=None,
        description="Activate or deactivate the account.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

class UserResponse(BaseModel):
    """Full user record returned by the API."""
    id: str = Field(
        ...,
        description="Server-assigned UUID.",
    )
    full_name: str = Field(
        ...,
        description="Full name.",
    )
    phone_number: str = Field(
        ...,
        description="Registered phone number.",
    )
    role: UserRole = Field(
        ...,
        description="Assigned role.",
    )
    email: Optional[EmailStr] = Field(
        default=None,
        description="Email address, if provided.",
    )
    preferred_language: str = Field(
        ...,
        description="Language code.",
    )
    is_active: bool = Field(
        ...,
        description="Whether the account is active.",
    )
    created_at: datetime = Field(
        ...,
        description="Account creation timestamp (ISO 8601).",
    )
    updated_at: datetime = Field(
        ...,
        description="Last profile update timestamp (ISO 8601).",
    )

    model_config = ConfigDict(from_attributes=True)
