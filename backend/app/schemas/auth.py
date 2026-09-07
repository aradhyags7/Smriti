"""Authentication and user management schemas."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr


class UserRegister(BaseModel):
    """Payload for user registration."""
    email: EmailStr
    password: str
    full_name: str
    role: str = "patient"


class UserLogin(BaseModel):
    """Payload for user authentication / login."""
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """Bearer token response payload."""
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    """Public user response schema with ORM mode enabled."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    full_name: str
    role: str
    created_at: Optional[datetime] = None
