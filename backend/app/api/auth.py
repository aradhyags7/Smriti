"""Authentication API routes."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.security import create_access_token
from app.models import User
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

    Raises 400 Bad Request if the email or phone number is already registered.
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
        email=str(login_data.email) if login_data.email else None,
        password=login_data.password,
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    sub = user.email or user.phone_number or str(user.id)
    access_token = create_access_token(data={"sub": sub})
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        refresh_token="dummy_refresh_token",
        expires_in=3600,
        user_id=str(user.id),
        role=user.role,
        full_name=user.full_name,
        email=user.email,
    )


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current user profile",
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    """Retrieve the profile of the currently logged-in user."""
    return current_user
