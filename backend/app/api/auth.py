"""Authentication API routes."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import create_access_token
from app.schemas.auth import TokenResponse, UserSignupRequest, UserLoginRequest
from app.schemas.user import UserResponse
from app.services.auth_service import authenticate_user, register_user

router = APIRouter()


@router.post(
    "/signup",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
)
def register(
    user_data: UserSignupRequest,
    db: Session = Depends(get_db),
):
    """Register a new user account.

    Raises 400 Bad Request if the phone number is already registered.
    """
    try:
        user = register_user(db=db, user_data=user_data)
        return user
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Login for access token",
)
def login(
    login_data: UserLoginRequest,
    db: Session = Depends(get_db),
):
    """Authenticate user credentials and return a Bearer JWT access token."""
    user = authenticate_user(
        db=db,
        phone_number=login_data.phone_number,
        pin=login_data.pin,
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone number or PIN",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(data={"sub": user.phone_number})
    # Provide dummy values for refresh_token, expires_in, and role, user_id since they are required by TokenResponse
    return TokenResponse(
        access_token=access_token, 
        token_type="bearer",
        refresh_token="dummy_refresh_token",
        expires_in=3600,
        user_id=str(user.id),
        role=user.role
    )
