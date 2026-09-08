"""Authentication service business logic."""

from typing import Optional
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.models import User
from app.schemas.auth import UserSignupRequest


def register_user(db: Session, user_data: UserSignupRequest) -> User:
    """Register a new user account.

    Raises:
        ValueError: If a user with the given email or phone number already exists.
    """
    if user_data.email:
        existing_email = db.query(User).filter(User.email == user_data.email.lower().strip()).first()
        if existing_email:
            raise ValueError(f"User with email '{user_data.email}' already exists")

    if user_data.phone_number:
        existing_phone = db.query(User).filter(User.phone_number == user_data.phone_number.strip()).first()
        if existing_phone:
            raise ValueError(f"User with phone number '{user_data.phone_number}' already exists")

    secret = user_data.password or user_data.pin
    if not secret:
        raise ValueError("Password or PIN must be provided")

    hashed_pw = get_password_hash(secret)
    user = User(
        full_name=user_data.full_name,
        email=user_data.email.lower().strip() if user_data.email else None,
        phone_number=user_data.phone_number.strip() if user_data.phone_number else None,
        hashed_password=hashed_pw,
        role=user_data.role,
        preferred_language=user_data.preferred_language,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(
    db: Session,
    phone_number: Optional[str] = None,
    pin: Optional[str] = None,
    email: Optional[str] = None,
    password: Optional[str] = None,
) -> Optional[User]:
    """Authenticate a user with email/password or phone_number/PIN.

    Returns:
        User model if authentication succeeds, None otherwise.
    """
    user = None
    if email:
        user = db.query(User).filter(User.email == email.lower().strip()).first()
    elif phone_number:
        user = db.query(User).filter(User.phone_number == phone_number.strip()).first()

    if not user:
        return None

    secret = password or pin
    if not secret or not verify_password(secret, user.hashed_password):
        return None

    return user
