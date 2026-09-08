"""ASHA Worker API routes for SMRITI platform."""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models import User
from app.schemas.asha import (
    AshaWorkerResponse,
    AssignPatientRequest,
    AshaPatientItem,
    CommunityPatientItem,
    CareCircleResponse,
)
from app.services.asha_service import (
    get_or_create_asha_profile,
    get_asha_patients,
    get_community_patients,
    assign_patient_to_asha,
    unassign_patient_from_asha,
    get_care_circle_for_patient,
)

router = APIRouter()


@router.get(
    "/profile",
    response_model=AshaWorkerResponse,
    summary="Get ASHA worker profile",
)
def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve the current ASHA worker profile."""
    return get_or_create_asha_profile(db=db, user=current_user)


@router.get(
    "/my-patients",
    response_model=List[AshaPatientItem],
    summary="Get assigned patients",
)
def list_assigned_patients(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve all patients assigned to this ASHA worker."""
    worker = get_or_create_asha_profile(db=db, user=current_user)
    return get_asha_patients(db=db, asha=worker)


@router.get(
    "/community-patients",
    response_model=List[CommunityPatientItem],
    summary="Get all community patients",
)
def list_community_patients(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve community patients for assignment."""
    worker = get_or_create_asha_profile(db=db, user=current_user)
    return get_community_patients(db=db, asha=worker)


@router.post(
    "/assign-patient",
    response_model=AshaPatientItem,
    summary="Assign a patient to roster",
)
def assign_patient_endpoint(
    request: AssignPatientRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Assign a community patient to this ASHA worker's active roster."""
    worker = get_or_create_asha_profile(db=db, user=current_user)
    try:
        return assign_patient_to_asha(
            db=db,
            asha=worker,
            patient_id=request.patient_id,
            village_notes=request.village_notes,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.post(
    "/unassign-patient/{patient_id}",
    summary="Unassign a patient",
)
def unassign_patient_endpoint(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove a patient from this ASHA worker's roster."""
    worker = get_or_create_asha_profile(db=db, user=current_user)
    success = unassign_patient_from_asha(db=db, asha=worker, patient_id=patient_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not assigned to this ASHA worker",
        )
    return {"status": "success", "message": "Patient unassigned"}


@router.get(
    "/care-circle",
    response_model=CareCircleResponse,
    summary="Get patient care circle",
)
def care_circle_endpoint(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get connected caregiver and assigned ASHA worker for the current patient."""
    return get_care_circle_for_patient(db=db, user=current_user)
