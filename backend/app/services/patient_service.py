"""Patient management service business logic."""

from datetime import date
from typing import Optional
import uuid
from sqlalchemy.orm import Session

from app.models import Patient, User
from app.schemas.patient import PatientCreate, PatientOnboardingRequest, PatientProfileResponse


def create_patient(db: Session, data: PatientCreate) -> Patient:
    """Create a new patient record in the database."""
    patient = Patient(**data.model_dump())
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return patient


def get_patient(db: Session, patient_id: str) -> Optional[Patient]:
    """Retrieve a patient by their unique identifier."""
    return db.query(Patient).filter(Patient.id == patient_id).first()


def get_patient_by_user_id(db: Session, user_id: str) -> Optional[Patient]:
    """Retrieve a patient record linked to a user account."""
    return db.query(Patient).filter(Patient.user_id == user_id).first()


def get_or_create_patient_profile(db: Session, user: User) -> Patient:
    """Ensure that a User with role patient has an active Patient record."""
    patient = db.query(Patient).filter(Patient.user_id == user.id).first()
    if not patient:
        patient = Patient(
            id=str(uuid.uuid4()),
            user_id=user.id,
            date_of_birth=date(1955, 1, 1),
            gender="other",
            emergency_contact_name=user.full_name,
            emergency_contact_phone=user.phone_number or "+919999999999",
            is_onboarded=False,
        )
        db.add(patient)
        db.commit()
        db.refresh(patient)
    return patient


def build_patient_profile_response(user: User, patient: Patient) -> PatientProfileResponse:
    """Construct a clean PatientProfileResponse model."""
    age = patient.age
    if age is None and patient.date_of_birth:
        today = date.today()
        age = today.year - patient.date_of_birth.year - (
            (today.month, today.day) < (patient.date_of_birth.month, patient.date_of_birth.day)
        )

    return PatientProfileResponse(
        id=str(patient.id),
        user_id=str(user.id),
        full_name=user.full_name,
        email=user.email,
        phone_number=user.phone_number,
        age=age or 70,
        gender=patient.gender or "other",
        dementia_type=patient.dementia_type,
        is_onboarded=bool(patient.is_onboarded),
        preferred_language=user.preferred_language or "en",
        emergency_contact_name=patient.emergency_contact_name,
        emergency_contact_phone=patient.emergency_contact_phone,
    )


def complete_patient_onboarding(db: Session, user: User, data: PatientOnboardingRequest) -> Patient:
    """Save patient onboarding responses (age, gender, dementia type) and mark onboarded."""
    patient = get_or_create_patient_profile(db, user)
    patient.age = data.age
    patient.gender = data.gender.strip().lower()
    patient.dementia_type = data.dementia_type.strip()
    
    # Calculate approximate date_of_birth from age
    today = date.today()
    patient.date_of_birth = date(today.year - data.age, 1, 1)
    patient.is_onboarded = True

    db.commit()
    db.refresh(patient)
    return patient
