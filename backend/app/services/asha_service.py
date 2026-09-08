"""ASHA service business logic for SMRITI platform."""

from datetime import datetime, date
from typing import List, Optional
import uuid
from sqlalchemy.orm import Session

from app.models import User, Patient, Caregiver, AshaWorker
from app.schemas.asha import (
    AshaPatientItem,
    CommunityPatientItem,
    CareCircleResponse,
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


def get_or_create_asha_profile(db: Session, user: User) -> AshaWorker:
    """Ensure the user has an associated ASHA Worker profile."""
    worker = db.query(AshaWorker).filter(AshaWorker.user_id == user.id).first()
    if not worker:
        worker = AshaWorker(
            id=str(uuid.uuid4()),
            user_id=user.id,
            name=user.full_name,
            phone=user.phone_number,
            village_assigned="Guwahati Sector 4",
            district="Kamrup",
        )
        db.add(worker)
        db.commit()
        db.refresh(worker)
    return worker


def get_asha_patients(db: Session, asha: AshaWorker) -> List[AshaPatientItem]:
    """Return all patients assigned to this ASHA worker."""
    _sync_patient_users(db)
    patients = db.query(Patient).filter(Patient.asha_worker_id == asha.id).all()
    results = []

    for p in patients:
        user = p.user
        name = user.full_name if user else p.emergency_contact_name or "Community Patient"
        email = user.email if user else None
        phone = user.phone_number if user else p.emergency_contact_phone

        age = None
        if p.date_of_birth:
            today = date.today()
            age = today.year - p.date_of_birth.year - (
                (today.month, today.day) < (p.date_of_birth.month, p.date_of_birth.day)
            )

        cg_name = None
        cg_phone = None
        if p.caregiver:
            cg_name = p.caregiver.name
            cg_phone = p.caregiver.phone

        status = "Stable"
        status_color = "green"
        if (p.baseline_memory or 70.0) < 60.0:
            status = "Needs Attention"
            status_color = "red"
        elif (p.baseline_memory or 70.0) < 75.0:
            status = "Routine Monitor"
            status_color = "orange"

        results.append(
            AshaPatientItem(
                patient_id=str(p.id),
                user_id=str(p.user_id),
                full_name=name,
                email=email,
                phone_number=phone,
                age=p.age or age or 72,
                gender=p.gender or "other",
                dementia_type=p.dementia_type,
                village=asha.village_assigned,
                district=asha.district,
                status=status,
                status_color=status_color,
                consent_for_asha=bool(p.consent_for_asha),
                caregiver_name=cg_name,
                caregiver_phone=cg_phone,
                baseline_memory=p.baseline_memory or 70.0,
                last_visit="2 days ago",
            )
        )
    return results


def get_community_patients(db: Session, asha: AshaWorker) -> List[CommunityPatientItem]:
    """Return all community patients available for assignment."""
    _sync_patient_users(db)
    patients = db.query(Patient).all()
    results = []

    for p in patients:
        user = p.user
        name = user.full_name if user else p.emergency_contact_name or "Patient"
        email = user.email if user else None
        phone = user.phone_number if user else p.emergency_contact_phone
        is_assigned = p.asha_worker_id == asha.id
        assigned_name = p.asha_worker.name if p.asha_worker else None

        results.append(
            CommunityPatientItem(
                patient_id=str(p.id),
                user_id=str(p.user_id),
                full_name=name,
                email=email,
                phone_number=phone,
                is_assigned=is_assigned,
                assigned_asha_name=assigned_name,
            )
        )
    return results


def assign_patient_to_asha(
    db: Session,
    asha: AshaWorker,
    patient_id: str,
    village_notes: Optional[str] = None,
) -> AshaPatientItem:
    """Assign a patient to this ASHA worker's active roster."""
    _sync_patient_users(db)
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        patient = db.query(Patient).filter(Patient.user_id == patient_id).first()

    if not patient:
        raise ValueError(f"Patient with ID '{patient_id}' not found")

    patient.asha_worker_id = asha.id
    if village_notes:
        patient.medical_notes = (patient.medical_notes or "") + f"\n[ASHA Note]: {village_notes}"

    db.commit()
    db.refresh(patient)

    user = patient.user
    name = user.full_name if user else patient.emergency_contact_name
    email = user.email if user else None
    phone = user.phone_number if user else patient.emergency_contact_phone

    cg_name = None
    cg_phone = None
    if patient.caregiver:
        cg_name = patient.caregiver.name
        cg_phone = patient.caregiver.phone

    return AshaPatientItem(
        patient_id=str(patient.id),
        user_id=str(patient.user_id),
        full_name=name,
        email=email,
        phone_number=phone,
        age=patient.age or 72,
        gender=patient.gender or "other",
        dementia_type=patient.dementia_type,
        village=asha.village_assigned,
        district=asha.district,
        status="Stable",
        status_color="green",
        consent_for_asha=bool(patient.consent_for_asha),
        caregiver_name=cg_name,
        caregiver_phone=cg_phone,
        baseline_memory=patient.baseline_memory or 70.0,
        last_visit="Today",
    )


def unassign_patient_from_asha(db: Session, asha: AshaWorker, patient_id: str) -> bool:
    """Remove patient from ASHA worker's assigned list."""
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.asha_worker_id == asha.id,
    ).first()
    if patient:
        patient.asha_worker_id = None
        db.commit()
        return True
    return False


def get_care_circle_for_patient(db: Session, user: User) -> CareCircleResponse:
    """Return the Care Circle (Caregiver & ASHA worker) for this patient."""
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

    cg_data = None
    if patient.caregiver:
        cg = patient.caregiver
        cg_user = cg.user
        cg_data = {
            "id": cg.id,
            "name": cg.name,
            "phone": cg.phone or (cg_user.phone_number if cg_user else None),
            "email": cg_user.email if cg_user else None,
            "relationship": cg.relationship_to_patient or "Family Caregiver",
        }

    asha_data = None
    if patient.asha_worker:
        aw = patient.asha_worker
        aw_user = aw.user
        asha_data = {
            "id": aw.id,
            "name": aw.name,
            "phone": aw.phone or (aw_user.phone_number if aw_user else None),
            "village": aw.village_assigned,
            "district": aw.district,
        }

    return CareCircleResponse(
        caregiver=cg_data,
        asha_worker=asha_data,
        patient_name=user.full_name,
        patient_email=user.email,
    )
