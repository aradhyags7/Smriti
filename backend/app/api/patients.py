"""Patient API routes."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.models import User
from app.schemas.patient import PatientCreate, PatientOut
from app.services.patient_service import create_patient, get_patient

router = APIRouter()


@router.post(
    "/",
    response_model=PatientOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new patient",
)
def create_new_patient(
    patient_data: PatientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Register a new patient profile (requires authentication)."""
    # If user_id is not explicitly provided and user is a patient, link to current user
    return create_patient(db=db, data=patient_data)


@router.get(
    "/{patient_id}",
    response_model=PatientOut,
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
