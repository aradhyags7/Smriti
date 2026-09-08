"""Authentication service business logic."""

from typing import Optional, Dict, Any
import uuid
from fastapi import HTTPException, status
from google.oauth2 import id_token
from google.auth.transport import requests
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import get_password_hash, verify_password
from app.models import User, Patient, Caregiver, AshaWorker
from app.schemas.auth import UserSignupRequest, UserRole


def register_user(db: Session, user_data: UserSignupRequest) -> User:
    """Register a new user account with email/password or phone/PIN.

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
        auth_provider="LOCAL",
        role=user_data.role,
        preferred_language=user_data.preferred_language,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Provision role profile
    if user.role == "patient":
        from datetime import date
        patient = Patient(
            id=str(uuid.uuid4()),
            user_id=user.id,
            date_of_birth=date(1955, 1, 1),
            gender="other",
            emergency_contact_name=user.full_name,
            emergency_contact_phone="+919999999999",
        )
        db.add(patient)
        db.commit()
    elif user.role == "caregiver":
        cg = Caregiver(
            id=str(uuid.uuid4()),
            user_id=user.id,
            name=user.full_name,
            relationship_to_patient="Family Caregiver",
        )
        db.add(cg)
        db.commit()
    elif user.role == "asha":
        asha = AshaWorker(
            id=str(uuid.uuid4()),
            user_id=user.id,
            name=user.full_name,
            phone=user.phone_number or "+919999999999",
            village_assigned="Guwahati Sector",
            district="Kamrup",
        )
        db.add(asha)
        db.commit()

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

    # Google-only accounts do not have a password
    if not user.hashed_password:
        return None

    secret = password or pin
    if not secret or not verify_password(secret, user.hashed_password):
        return None

    return user


def verify_google_id_token(token: str) -> Dict[str, Any]:
    """Cryptographically verify Google ID Token.

    Checks:
        1. Configured GOOGLE_SERVER_CLIENT_ID (fails if unconfigured; audience is never None)
        2. Cryptographic signature via Google public keys
        3. Expiration
        4. Issuer (accounts.google.com or https://accounts.google.com)
        5. Verified email presence
    """
    server_client_id = settings.GOOGLE_SERVER_CLIENT_ID
    if not server_client_id or not server_client_id.strip():
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Google authentication is not configured on the server. GOOGLE_SERVER_CLIENT_ID must be set in environment variables.",
        )

    # In development mode, allow mock / dev Google tokens for testing when Google Cloud Console is not configured
    if settings.ENVIRONMENT == "development" and (token.startswith("dev_google_token_") or token.startswith("dev_token_")):
        email = token.replace("dev_google_token_", "").replace("dev_token_", "").strip()
        if not email or "@" not in email:
            email = "google.user@smriti.care"
        name_parts = email.split("@")[0].replace(".", " ").title()
        return {
            "sub": f"google_dev_sub_{email}",
            "email": email,
            "name": name_parts,
            "email_verified": True,
            "picture": None,
        }

    try:
        id_info = id_token.verify_oauth2_token(
            token,
            requests.Request(),
            audience=server_client_id.strip(),
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google ID token: {str(exc)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if id_info.get("iss") not in ["accounts.google.com", "https://accounts.google.com"]:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google token issuer",
            headers={"WWW-Authenticate": "Bearer"},
        )

    sub = id_info.get("sub")
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google token missing subject identifier",
        )

    email = id_info.get("email")
    email_verified = id_info.get("email_verified", False)
    if not email or not email_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google account email is missing or unverified",
        )

    return {
        "sub": sub,
        "email": email.lower().strip(),
        "name": id_info.get("name") or "Google User",
        "picture": id_info.get("picture"),
    }


def authenticate_or_create_google_user(
    db: Session,
    google_info: Dict[str, Any],
    requested_role: Optional[UserRole] = None,
) -> User:
    """Find user by google_subject or provision a new Google-authenticated user.

    Enforces:
        - Google `sub` as the permanent identity key (never email).
        - Account collision safety: 409 Conflict if email belongs to an existing LOCAL account.
        - Idempotency: same Google account always resolves to the same SMRITI user.
        - Role provisioning: strictly creates Patient for PATIENT, Caregiver for CAREGIVER, AshaWorker for ASHA.
    """
    sub = google_info["sub"]
    email = google_info["email"]
    name = google_info.get("name") or "Google User"

    # 1. Look up user by permanent Google subject identifier
    user = db.query(User).filter(User.google_subject == sub).first()
    if user:
        return user

    # 2. Safety check: Email collision with existing LOCAL or other account
    existing_user_by_email = db.query(User).filter(User.email == email).first()
    if existing_user_by_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists with password authentication. Please sign in with your password.",
        )

    # 3. Create new Google-authenticated user
    role_str = "patient"
    if requested_role:
        val = requested_role.value if hasattr(requested_role, "value") else str(requested_role)
        if val.lower() in ["patient", "caregiver", "asha"]:
            role_str = val.lower()

    new_user = User(
        id=str(uuid.uuid4()),
        full_name=name,
        email=email,
        phone_number=None,
        hashed_password=None,
        auth_provider="GOOGLE",
        google_subject=sub,
        role=role_str,
        preferred_language="en",
        is_active=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # 4. Strictly provision role profile
    if role_str == "patient":
        from datetime import date
        patient = Patient(
            id=str(uuid.uuid4()),
            user_id=new_user.id,
            date_of_birth=date(1955, 1, 1),
            gender="other",
            emergency_contact_name=new_user.full_name,
            emergency_contact_phone="+919999999999",
        )
        db.add(patient)
        db.commit()
    elif role_str == "caregiver":
        cg = Caregiver(
            id=str(uuid.uuid4()),
            user_id=new_user.id,
            name=new_user.full_name,
            relationship_to_patient="Family Caregiver",
        )
        db.add(cg)
        db.commit()
    elif role_str == "asha":
        asha = AshaWorker(
            id=str(uuid.uuid4()),
            user_id=new_user.id,
            name=new_user.full_name,
            phone=new_user.phone_number or "+919999999999",
            village_assigned="Guwahati Sector",
            district="Kamrup",
        )
        db.add(asha)
        db.commit()

    db.refresh(new_user)
    return new_user
