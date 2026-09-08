"""Authentication service business logic."""

from typing import Optional
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.models import User
from app.schemas.auth import UserSignupRequest


def register_user(db: Session, user_data: UserSignupRequest) -> User:
    """Register a new user account.

    Raises:
        ValueError: If a user with the given phone number already exists.
    """
    existing_user = db.query(User).filter(User.phone_number == user_data.phone_number).first()
    if existing_user:
        raise ValueError(f"User with phone number '{user_data.phone_number}' already exists")

    hashed_pw = get_password_hash(user_data.pin)
    user = User(
        phone_number=user_data.phone_number,
        hashed_password=hashed_pw,
        full_name=user_data.full_name,
        role=user_data.role,
        preferred_language=user_data.preferred_language,
        email=user_data.email
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, phone_number: str, pin: str) -> Optional[User]:
    """Authenticate a user with phone number and plain PIN.

    Returns:
        User model if authentication succeeds, None otherwise.
    """
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if not user:
        return None

    if not verify_password(pin, user.hashed_password):
        return None

    return user
