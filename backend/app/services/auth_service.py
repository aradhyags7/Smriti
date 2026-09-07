"""Authentication service business logic."""

from typing import Optional
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.models.models import User
from app.schemas.auth import UserRegister


def register_user(db: Session, user_data: UserRegister) -> User:
    """Register a new user account.

    Raises:
        ValueError: If a user with the given email already exists.
    """
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise ValueError(f"User with email '{user_data.email}' already exists")

    hashed_pw = get_password_hash(user_data.password)
    user = User(
        email=user_data.email,
        hashed_password=hashed_pw,
        full_name=user_data.full_name,
        role=user_data.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    """Authenticate a user with email and plain password.

    Returns:
        User model if authentication succeeds, None otherwise.
    """
    user = db.query(User).filter(User.email == email).first()
    if not user:
        return None

    if not verify_password(password, user.hashed_password):
        return None

    return user
