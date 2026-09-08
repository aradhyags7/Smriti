"""Reminders API routes."""

import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models import User, Patient, Reminder

router = APIRouter()


class ReminderItemSchema(BaseModel):
    id: str
    patient_id: str
    title: str
    reminder_type: str
    scheduled_time: str
    frequency: str
    is_acknowledged: bool
    sync_status: str

    model_config = ConfigDict(from_attributes=True)



class ReminderCreateSchema(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    scheduled_time: str = Field(..., description="e.g. 08:30 AM")
    reminder_type: str = Field(default="MEDICINE")  # MEDICINE, ROUTINE, HYDRATION, CHECKIN, GAME_SESSION
    frequency: str = Field(default="DAILY")         # DAILY, ONCE, WEEKLY
    patient_id: Optional[str] = None


@router.get(
    "/",
    response_model=List[ReminderItemSchema],
    summary="List reminders",
)
def list_reminders(
    patient_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List reminders. If patient_id is not specified, returns all accessible reminders."""
    query = db.query(Reminder)
    if patient_id:
        query = query.filter(Reminder.patient_id == patient_id)
    else:
        # If user is a patient, show their patient reminders
        patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
        if patient:
            query = query.filter(Reminder.patient_id == patient.id)
    return query.order_by(Reminder.scheduled_time.asc()).all()


@router.post(
    "/",
    response_model=ReminderItemSchema,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new reminder",
)
def create_reminder(
    data: ReminderCreateSchema,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new reminder. Automatically provisions or links patient if needed."""
    target_patient_id = data.patient_id
    if not target_patient_id:
        patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
        if not patient:
            from datetime import date
            patient = Patient(
                user_id=current_user.id,
                date_of_birth=date(1955, 1, 1),
                gender="not_specified",
                emergency_contact_name=current_user.full_name or "Caregiver",
                emergency_contact_phone=current_user.phone_number or "+919999999999",
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
        target_patient_id = patient.id

    reminder = Reminder(
        id=str(uuid.uuid4()),
        patient_id=target_patient_id,
        title=data.title.strip(),
        reminder_type=data.reminder_type.upper(),
        scheduled_time=data.scheduled_time.strip(),
        frequency=data.frequency.upper(),
        is_acknowledged=False,
        sync_status="SYNCED",
    )
    db.add(reminder)
    db.commit()
    db.refresh(reminder)
    return reminder


@router.patch(
    "/{reminder_id}/acknowledge",
    response_model=ReminderItemSchema,
    summary="Toggle reminder acknowledgement status",
)
def toggle_acknowledge(
    reminder_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Toggle the is_acknowledged state of a reminder."""
    reminder = db.query(Reminder).filter(Reminder.id == reminder_id).first()
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Reminder with ID '{reminder_id}' not found",
        )
    reminder.is_acknowledged = not reminder.is_acknowledged
    db.commit()
    db.refresh(reminder)
    return reminder


@router.delete(
    "/{reminder_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a reminder",
)
def delete_reminder(
    reminder_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a reminder by ID."""
    reminder = db.query(Reminder).filter(Reminder.id == reminder_id).first()
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Reminder with ID '{reminder_id}' not found",
        )
    db.delete(reminder)
    db.commit()
    return None
