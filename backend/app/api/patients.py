"""Patient API routes."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models import User
from app.schemas.patient import (
    PatientCreate,
    PatientResponse,
    PatientOnboardingRequest,
    PatientProfileResponse,
)
from app.services.patient_service import (
    create_patient,
    get_patient,
    get_or_create_patient_profile,
    build_patient_profile_response,
    complete_patient_onboarding,
)

router = APIRouter()


@router.get(
    "/me",
    response_model=PatientProfileResponse,
    summary="Get current patient profile",
)
def get_current_patient_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve the profile and onboarding state of the currently authenticated patient."""
    patient = get_or_create_patient_profile(db=db, user=current_user)
    return build_patient_profile_response(user=current_user, patient=patient)


@router.post(
    "/onboarding",
    response_model=PatientProfileResponse,
    summary="Complete patient one-time onboarding",
)
def submit_patient_onboarding(
    data: PatientOnboardingRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Save patient's age, gender, and dementia diagnosis. Called once during initial signup."""
    patient = complete_patient_onboarding(db=db, user=current_user, data=data)
    return build_patient_profile_response(user=current_user, patient=patient)


@router.post(
    "/",
    response_model=PatientResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new patient",
)
def create_new_patient(
    patient_data: PatientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Register a new patient profile (requires authentication)."""
    return create_patient(db=db, data=patient_data)


@router.get(
    "/{patient_id}",
    response_model=PatientResponse,
    summary="Get patient by ID",
)
def get_patient_by_id(
    patient_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve patient demographic details by patient ID (requires authentication)."""
    patient = get_patient(db=db, patient_id=patient_id)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Patient with ID '{patient_id}' not found",
        )
    return patient
