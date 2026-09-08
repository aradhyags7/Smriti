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
    PatientAnalyticsResponse,
    DailyActivityFeedResponse,
    AlertItemResponse,
    ReminiscenceItemResponse,
    ReminiscenceCreateRequest,
)
from app.services.caregiver_service import (
    get_or_create_caregiver_profile,
    get_caregiver_patients,
    get_available_patients,
    connect_patient,
    disconnect_patient,
    get_patient_analytics,
    get_patient_activity_feed,
    get_patient_alerts,
    acknowledge_patient_alert,
    get_patient_reminiscences,
    create_patient_reminiscence,
    delete_patient_reminiscence,
)

router = APIRouter()


# --- Section 1: Patient Profiles & Connection ---

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


# --- Section 2: Cognitive Analytics ---

@router.get(
    "/patient/{patient_id}/analytics",
    response_model=PatientAnalyticsResponse,
    summary="Get patient cognitive analytics and 7-day trend",
)
def get_analytics_endpoint(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve line chart trends (Memory, Attention, Engagement) and clinical risk level."""
    return get_patient_analytics(db=db, patient_id=patient_id)


# --- Section 3: Daily Activity Feed ---

@router.get(
    "/patient/{patient_id}/activity-feed",
    response_model=DailyActivityFeedResponse,
    summary="Get patient daily activity feed",
)
def get_activity_feed_endpoint(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve today's games (scores, mistakes, reaction time) and latest daily check-in."""
    return get_patient_activity_feed(db=db, patient_id=patient_id)


# --- Section 4: Alerts Inbox ---

@router.get(
    "/patient/{patient_id}/alerts",
    response_model=List[AlertItemResponse],
    summary="Get patient system alerts",
)
def get_alerts_endpoint(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve system alerts and clinical notifications."""
    return get_patient_alerts(db=db, patient_id=patient_id)


@router.post(
    "/alerts/{alert_id}/acknowledge",
    summary="Acknowledge an alert",
)
def acknowledge_alert_endpoint(
    alert_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark an alert as acknowledged by the caregiver."""
    success = acknowledge_patient_alert(db=db, alert_id=alert_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found",
        )
    return {"status": "success", "message": "Alert acknowledged"}


# --- Section 5: Reminiscence Vault ---

@router.get(
    "/patient/{patient_id}/reminiscence",
    response_model=List[ReminiscenceItemResponse],
    summary="Get patient reminiscence memories",
)
def get_reminiscence_endpoint(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve reminiscence photos, audio notes, and relationship memories."""
    return get_patient_reminiscences(db=db, patient_id=patient_id)


@router.post(
    "/patient/{patient_id}/reminiscence",
    response_model=ReminiscenceItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a reminiscence memory",
)
def create_reminiscence_endpoint(
    patient_id: str,
    data: ReminiscenceCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Save a memory with photo, relationship tag, and notes to the patient vault."""
    return create_patient_reminiscence(db=db, patient_id=patient_id, data=data)


@router.delete(
    "/reminiscence/{memory_id}",
    summary="Delete a reminiscence memory",
)
def delete_reminiscence_endpoint(
    memory_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove a memory from the vault."""
    success = delete_patient_reminiscence(db=db, memory_id=memory_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Memory not found",
        )
    return {"status": "success", "message": "Memory deleted"}
