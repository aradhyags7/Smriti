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
    AshaTriageResponse,
    EmergencyAlertItem,
    UpdateMedicalNotesRequest,
    AshaPatientDetailResponse,
)
from app.services.asha_service import (
    get_or_create_asha_profile,
    get_asha_patients,
    get_community_patients,
    assign_patient_to_asha,
    unassign_patient_from_asha,
    get_care_circle_for_patient,
    get_triage_board,
    get_emergency_alerts,
    update_medical_notes,
    get_patient_detail_for_asha,
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
    "/triage-board",
    response_model=AshaTriageResponse,
    summary="Get prioritized triage board",
)
def get_triage_board_endpoint(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve patient roster sorted by priority: CRITICAL -> ATTENTION_REQUIRED -> MONITOR -> STABLE."""
    worker = get_or_create_asha_profile(db=db, user=current_user)
    return get_triage_board(db=db, asha=worker)


@router.get(
    "/emergency-alerts",
    response_model=List[EmergencyAlertItem],
    summary="Get all unresolved emergency alerts",
)
def get_emergency_alerts_endpoint(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve all unresolved high-severity alerts across assigned village patients."""
    worker = get_or_create_asha_profile(db=db, user=current_user)
    return get_emergency_alerts(db=db, asha=worker)


@router.get(
    "/patient/{patient_id}/detail",
    response_model=AshaPatientDetailResponse,
    summary="Get patient detail for ASHA worker",
)
def get_patient_detail_endpoint(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve read-only patient detail (trends, check-ins, games, and medical notes)."""
    worker = get_or_create_asha_profile(db=db, user=current_user)
    try:
        return get_patient_detail_for_asha(db=db, asha=worker, patient_id=patient_id)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.post(
    "/patient/{patient_id}/medical-notes",
    response_model=AshaPatientItem,
    summary="Update medical notes after home visit",
)
def update_medical_notes_endpoint(
    patient_id: str,
    request: UpdateMedicalNotesRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Record clinical observations and notes after an ASHA home visit."""
    worker = get_or_create_asha_profile(db=db, user=current_user)
    try:
        return update_medical_notes(
            db=db,
            asha=worker,
            patient_id=patient_id,
            notes=request.notes,
            visit_date=request.visit_date,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


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
