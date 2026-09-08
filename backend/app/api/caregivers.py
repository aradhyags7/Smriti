"""Caregiver API routes for SMRITI platform."""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models import User
from app.schemas.caregiver import (
    CaregiverResponse,
    ConnectPatientRequest,
    CaregiverPatientItem,
    AvailablePatientItem,
)
from app.services.caregiver_service import (
    get_or_create_caregiver_profile,
    get_caregiver_patients,
    get_available_patients,
    connect_patient,
    disconnect_patient,
)

router = APIRouter()


@router.get(
    "/profile",
    response_model=CaregiverResponse,
    summary="Get caregiver profile",
)
def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve the current caregiver profile."""
    return get_or_create_caregiver_profile(db=db, user=current_user)


@router.get(
    "/my-patients",
    response_model=List[CaregiverPatientItem],
    summary="Get connected patients",
)
def list_connected_patients(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve all patients currently connected to this caregiver."""
    cg = get_or_create_caregiver_profile(db=db, user=current_user)
    return get_caregiver_patients(db=db, caregiver=cg)


@router.get(
    "/available-patients",
    response_model=List[AvailablePatientItem],
    summary="Get available patients to connect",
)
def list_available_patients(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve list of registered patients for connection."""
    cg = get_or_create_caregiver_profile(db=db, user=current_user)
    return get_available_patients(db=db, caregiver=cg)


@router.post(
    "/connect-patient",
    response_model=CaregiverPatientItem,
    summary="Connect a patient",
)
def connect_patient_endpoint(
    request: ConnectPatientRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Connect a patient to this caregiver account."""
    cg = get_or_create_caregiver_profile(db=db, user=current_user)
    try:
        return connect_patient(
            db=db,
            caregiver=cg,
            patient_id=request.patient_id,
            patient_email=request.patient_email,
            relationship=request.relationship or "Family Caregiver",
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.post(
    "/disconnect-patient/{patient_id}",
    summary="Disconnect a patient",
)
def disconnect_patient_endpoint(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Disconnect a patient from this caregiver account."""
    cg = get_or_create_caregiver_profile(db=db, user=current_user)
    success = disconnect_patient(db=db, caregiver=cg, patient_id=patient_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not connected to this caregiver",
        )
    return {"status": "success", "message": "Patient disconnected"}
