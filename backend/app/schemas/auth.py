"""
Authentication schemas for the SMRITI platform.

Covers user registration, login (PIN-based), JWT token issuance,
OTP verification, and PIN recovery flows.
All models use Pydantic v2 conventions (ConfigDict, Field).
"""

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class UserRole(str, Enum):
    """Three-role RBAC model used across the entire platform."""
    PATIENT = "patient"
    CAREGIVER = "caregiver"
    ASHA = "asha"


# ---------------------------------------------------------------------------
# Signup / Registration
# ---------------------------------------------------------------------------

class UserSignupRequest(BaseModel):
    """Payload for new user registration."""
    full_name: str = Field(
        ...,
        min_length=2,
        max_length=120,
        description="Full legal name of the user.",
    )
    phone_number: str = Field(
        ...,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="E.164-formatted phone number used as primary identifier.",
    )
    role: UserRole = Field(
        ...,
        description="Role assigned at registration (patient, caregiver, asha).",
    )
    pin: str = Field(
        ...,
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
        description="Numeric PIN (4–6 digits) used for authentication.",
    )
    email: Optional[EmailStr] = Field(
        default=None,
        description="Optional email address for notifications.",
    )
    preferred_language: str = Field(
        default="en",
        max_length=5,
        description="ISO 639-1 language code (e.g. 'hi', 'mr', 'en').",
    )

    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "full_name": "Tanishka Sawant",
                "phone_number": "+919876543210",
                "role": "caregiver",
                "pin": "1234",
                "email": "tanishka@example.com",
                "preferred_language": "en",
            }
        },
    )


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

class UserLoginRequest(BaseModel):
    """PIN-based login request."""
    phone_number: str = Field(
        ...,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="Registered phone number.",
    )
    pin: str = Field(
        ...,
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
        description="Numeric PIN for authentication.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# JWT Token Response
# ---------------------------------------------------------------------------

class TokenResponse(BaseModel):
    """Returned after successful authentication."""
    access_token: str = Field(
        ...,
        description="Short-lived JWT access token.",
    )
    refresh_token: str = Field(
        ...,
        description="Long-lived refresh token for silent re-authentication.",
    )
    token_type: str = Field(
        default="bearer",
        description="OAuth2 token type (always 'bearer').",
    )
    expires_in: int = Field(
        ...,
        gt=0,
        description="Access token lifetime in seconds.",
    )
    user_id: str = Field(
        ...,
        description="Server-assigned UUID of the authenticated user.",
    )
    role: UserRole = Field(
        ...,
        description="Role of the authenticated user.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# OTP Flow
# ---------------------------------------------------------------------------

class OTPRequest(BaseModel):
    """Request to send a one-time password via SMS."""
    phone_number: str = Field(
        ...,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="Phone number to receive the OTP.",
    )

    model_config = ConfigDict(from_attributes=True)


class OTPVerifyRequest(BaseModel):
    """Verify a received OTP code."""
    phone_number: str = Field(
        ...,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="Phone number the OTP was sent to.",
    )
    otp_code: str = Field(
        ...,
        min_length=6,
        max_length=6,
        pattern=r"^\d{6}$",
        description="Six-digit OTP code.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Forgot PIN
# ---------------------------------------------------------------------------

class ForgotPinRequest(BaseModel):
    """Initiate PIN reset after OTP verification."""
    phone_number: str = Field(
        ...,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="Registered phone number.",
    )
    otp_code: str = Field(
        ...,
        min_length=6,
        max_length=6,
        pattern=r"^\d{6}$",
        description="Verified OTP code proving phone ownership.",
    )
    new_pin: str = Field(
        ...,
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
        description="New numeric PIN to set.",
    )

    model_config = ConfigDict(from_attributes=True)
