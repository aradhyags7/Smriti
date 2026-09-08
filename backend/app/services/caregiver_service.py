"""Caregiver service business logic for SMRITI platform."""

from datetime import datetime, date, timezone
from typing import List, Optional
import uuid
from sqlalchemy.orm import Session

from app.models import User, Patient, Caregiver, AshaWorker, Reminder
from app.schemas.caregiver import (
    CaregiverPatientItem,
    AvailablePatientItem,
)


def _sync_patient_users(db: Session):
    """Ensure all users with role 'patient' have a Patient record."""
    patient_users = db.query(User).filter(User.role == "patient").all()
    for u in patient_users:
        p = db.query(Patient).filter(Patient.user_id == u.id).first()
        if not p:
            p = Patient(
                id=str(uuid.uuid4()),
                user_id=u.id,
                date_of_birth=date(1955, 1, 1),
                gender="other",
                emergency_contact_name=u.full_name,
                emergency_contact_phone=u.phone_number or "+919999999999",
            )
            db.add(p)
    db.commit()


def get_or_create_caregiver_profile(db: Session, user: User) -> Caregiver:
    """Ensure the user has an associated Caregiver profile."""
    cg = db.query(Caregiver).filter(Caregiver.user_id == user.id).first()
    if not cg:
        cg = Caregiver(
            id=str(uuid.uuid4()),
            user_id=user.id,
            name=user.full_name,
            phone=user.phone_number,
            relationship_to_patient="Family Caregiver",
        )
        db.add(cg)
        db.commit()
        db.refresh(cg)
    return cg


def get_caregiver_patients(db: Session, caregiver: Caregiver) -> List[CaregiverPatientItem]:
    """Return all patients connected to this caregiver."""
    _sync_patient_users(db)
    patients = db.query(Patient).filter(Patient.caregiver_id == caregiver.id).all()
    results = []
    
    for p in patients:
        user = p.user
        name = user.full_name if user else p.emergency_contact_name or "Loved One"
        email = user.email if user else None
        phone = user.phone_number if user else p.emergency_contact_phone
        
        age = None
        if p.date_of_birth:
            today = date.today()
            age = today.year - p.date_of_birth.year - (
                (today.month, today.day) < (p.date_of_birth.month, p.date_of_birth.day)
            )

        reminders_count = db.query(Reminder).filter(Reminder.patient_id == p.id).count()

        asha_name = None
        asha_phone = None
        if p.asha_worker:
            asha_name = p.asha_worker.name
            asha_phone = p.asha_worker.phone

        results.append(
            CaregiverPatientItem(
                patient_id=str(p.id),
                user_id=str(p.user_id),
                full_name=name,
                email=email,
                phone_number=phone,
                date_of_birth=p.date_of_birth.isoformat() if p.date_of_birth else None,
                age=age or 70,
                gender=p.gender or "other",
                relationship=caregiver.relationship_to_patient or "Family Caregiver",
                status="Active",
                status_color="green",
                reminders_count=reminders_count,
                baseline_memory=p.baseline_memory or 70.0,
                asha_name=asha_name,
                asha_phone=asha_phone,
                medical_notes=p.medical_notes,
            )
        )
    return results


def get_available_patients(db: Session, caregiver: Caregiver) -> List[AvailablePatientItem]:
    """Return all registered patients for selection."""
    _sync_patient_users(db)
    patients = db.query(Patient).all()
    results = []
    
    for p in patients:
        user = p.user
        name = user.full_name if user else p.emergency_contact_name or "Patient"
        email = user.email if user else None
        phone = user.phone_number if user else p.emergency_contact_phone
        is_connected = p.caregiver_id == caregiver.id

        results.append(
            AvailablePatientItem(
                patient_id=str(p.id),
                user_id=str(p.user_id),
                full_name=name,
                email=email,
                phone_number=phone,
                is_connected=is_connected,
            )
        )
    return results


def connect_patient(
    db: Session,
    caregiver: Caregiver,
    patient_id: Optional[str] = None,
    patient_email: Optional[str] = None,
    relationship: str = "Family Caregiver",
) -> CaregiverPatientItem:
    """Connect a patient to this caregiver."""
    _sync_patient_users(db)
    patient = None
    if patient_id:
        patient = db.query(Patient).filter(Patient.id == patient_id).first()
        if not patient:
            patient = db.query(Patient).filter(Patient.user_id == patient_id).first()
            
    if not patient and patient_email:
        user = db.query(User).filter(User.email == patient_email.lower().strip()).first()
        if user:
            patient = db.query(Patient).filter(Patient.user_id == user.id).first()
            if not patient:
                patient = Patient(
                    id=str(uuid.uuid4()),
                    user_id=user.id,
                    date_of_birth=date(1955, 1, 1),
                    gender="other",
                    emergency_contact_name=user.full_name,
                    emergency_contact_phone=user.phone_number or "+919999999999",
                )
                db.add(patient)
                db.commit()
                db.refresh(patient)

    if not patient:
        raise ValueError("Patient not found. Please check patient details.")

    patient.caregiver_id = caregiver.id
    caregiver.relationship_to_patient = relationship or "Family Caregiver"
    db.commit()
    db.refresh(patient)
    db.refresh(caregiver)

    user = patient.user
    name = user.full_name if user else patient.emergency_contact_name
    email = user.email if user else None
    phone = user.phone_number if user else patient.emergency_contact_phone

    asha_name = None
    asha_phone = None
    if patient.asha_worker:
        asha_name = patient.asha_worker.name
        asha_phone = patient.asha_worker.phone

    return CaregiverPatientItem(
        patient_id=str(patient.id),
        user_id=str(patient.user_id),
        full_name=name,
        email=email,
        phone_number=phone,
        relationship=caregiver.relationship_to_patient,
        status="Active",
        status_color="green",
        reminders_count=0,
        baseline_memory=patient.baseline_memory or 70.0,
        asha_name=asha_name,
        asha_phone=asha_phone,
    )


def disconnect_patient(db: Session, caregiver: Caregiver, patient_id: str) -> bool:
    """Disconnect caregiver from patient."""
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.caregiver_id == caregiver.id,
    ).first()
    if patient:
        patient.caregiver_id = None
        db.commit()
        return True
    return False
