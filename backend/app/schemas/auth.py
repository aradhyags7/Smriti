"""
Authentication schemas for the SMRITI platform.

Covers user registration, login (email or PIN-based), JWT token issuance,
OTP verification, and PIN recovery flows.
All models use Pydantic v2 conventions (ConfigDict, Field, model_validator).
"""

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, model_validator


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
    """Payload for new user registration (supports email and/or phone)."""
    full_name: str = Field(
        ...,
        min_length=2,
        max_length=120,
        description="Full legal name of the user.",
    )
    email: Optional[EmailStr] = Field(
        default=None,
        description="Email address for authentication and notifications.",
    )
    password: Optional[str] = Field(
        default=None,
        min_length=4,
        max_length=128,
        description="Password for authentication.",
    )
    phone_number: Optional[str] = Field(
        default=None,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="E.164-formatted phone number used as identifier.",
    )
    role: UserRole = Field(
        ...,
        description="Role assigned at registration (patient, caregiver, asha).",
    )
    pin: Optional[str] = Field(
        default=None,
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
        description="Numeric PIN (4-6 digits) used for authentication.",
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
                "email": "tanishka@example.com",
                "password": "password123",
                "phone_number": "+919876543210",
                "role": "caregiver",
                "pin": "1234",
                "preferred_language": "en",
            }
        },
    )

    @model_validator(mode="after")
    def validate_identifier_and_secret(self):
        if not self.email and not self.phone_number:
            raise ValueError("Either email or phone_number must be provided")
        if not self.password and not self.pin:
            raise ValueError("Either password or pin must be provided")
        return self


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

class UserLoginRequest(BaseModel):
    """Email or PIN-based login request."""
    email: Optional[EmailStr] = Field(
        default=None,
        description="Registered email address.",
    )
    password: Optional[str] = Field(
        default=None,
        description="Password for email authentication.",
    )
    phone_number: Optional[str] = Field(
        default=None,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="Registered phone number.",
    )
    pin: Optional[str] = Field(
        default=None,
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
        description="Numeric PIN for authentication.",
    )

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="after")
    def validate_login_fields(self):
        if not self.email and not self.phone_number:
            raise ValueError("Either email or phone_number must be provided for login")
        if not self.password and not self.pin:
            raise ValueError("Either password or pin must be provided for login")
        return self


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
    full_name: Optional[str] = Field(
        default=None,
        description="Full display name of the authenticated user.",
    )
    email: Optional[EmailStr] = Field(
        default=None,
        description="Email address of the authenticated user.",
    )
    is_onboarded: Optional[bool] = Field(
        default=None,
        description="Whether first-time onboarding has been completed for patient.",
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


# ---------------------------------------------------------------------------
# Google OAuth
# ---------------------------------------------------------------------------

class GoogleLoginRequest(BaseModel):
    """Payload for Google OAuth ID token verification."""
    id_token: str = Field(
        ...,
        min_length=10,
        description="Google ID Token issued by Google Sign-In SDK.",
    )
    role: Optional[UserRole] = Field(
        default=UserRole.PATIENT,
        description="Requested account role if creating a new user (PATIENT, CAREGIVER, or ASHA).",
    )

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="after")
    def validate_public_role(self):
        allowed = {UserRole.PATIENT, UserRole.CAREGIVER, UserRole.ASHA}
        if self.role and self.role not in allowed:
            raise ValueError("Role must be one of: patient, caregiver, asha")
        return self
