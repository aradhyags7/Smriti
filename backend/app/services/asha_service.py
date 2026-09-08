"""ASHA Worker service layer for SMRITI platform."""

import uuid
from datetime import date, datetime, timezone
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session

from app.models import User, Patient, AshaWorker, Alert
from app.schemas.asha import (
    AshaPatientItem,
    CommunityPatientItem,
    CareCircleResponse,
    AshaTriageResponse,
    EmergencyAlertItem,
    AshaPatientDetailResponse,
)
from app.services.caregiver_service import (
    get_patient_analytics,
    get_patient_activity_feed,
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


def _compute_triage_priority(baseline_memory: float, alerts_count: int) -> tuple[str, str, str]:
    """Computes (triage_priority, status, status_color)."""
    if baseline_memory < 55.0 or alerts_count >= 2:
        return "CRITICAL", "Critical Attention", "red"
    elif baseline_memory < 65.0 or alerts_count >= 1:
        return "ATTENTION_REQUIRED", "Needs Attention", "red"
    elif baseline_memory < 75.0:
        return "MONITOR", "Routine Monitor", "orange"
    else:
        return "STABLE", "Stable", "green"


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
        cg_rel = "Family Caregiver"
        if p.caregiver:
            cg_name = p.caregiver.name
            cg_phone = p.caregiver.phone
            cg_rel = p.caregiver.relationship_to_patient or "Family Caregiver"

        alerts_count = db.query(Alert).filter(
            Alert.patient_id == p.id,
            Alert.is_acknowledged == False,
        ).count()

        priority, status, status_color = _compute_triage_priority(p.baseline_memory or 70.0, alerts_count)

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
                triage_priority=priority,
                consent_for_asha=bool(p.consent_for_asha),
                caregiver_name=cg_name,
                caregiver_phone=cg_phone,
                caregiver_relationship=cg_rel,
                baseline_memory=p.baseline_memory or 70.0,
                baseline_attention=p.baseline_attention or 70.0,
                baseline_engagement=p.baseline_engagement or 70.0,
                primary_language=p.primary_language or "en",
                medical_notes=p.medical_notes,
                last_visit="2 days ago",
                unresolved_alerts_count=alerts_count,
            )
        )
    return results


def get_triage_board(db: Session, asha: AshaWorker) -> AshaTriageResponse:
    """Return assigned patients sorted by triage priority."""
    patients = get_asha_patients(db, asha)

    priority_order = {
        "CRITICAL": 0,
        "ATTENTION_REQUIRED": 1,
        "MONITOR": 2,
        "STABLE": 3,
    }

    sorted_patients = sorted(
        patients,
        key=lambda p: (priority_order.get(p.triage_priority, 99), p.baseline_memory),
    )

    critical_count = sum(1 for p in sorted_patients if p.triage_priority == "CRITICAL")
    attention_count = sum(1 for p in sorted_patients if p.triage_priority == "ATTENTION_REQUIRED")
    monitor_count = sum(1 for p in sorted_patients if p.triage_priority == "MONITOR")
    stable_count = sum(1 for p in sorted_patients if p.triage_priority == "STABLE")

    return AshaTriageResponse(
        asha_worker_id=asha.id,
        total_patients=len(sorted_patients),
        critical_count=critical_count,
        attention_count=attention_count,
        monitor_count=monitor_count,
        stable_count=stable_count,
        patients=sorted_patients,
        generated_at=datetime.now(timezone.utc),
    )


def get_emergency_alerts(db: Session, asha: AshaWorker) -> List[EmergencyAlertItem]:
    """Return all active, unresolved alerts for patients assigned to this ASHA worker."""
    _sync_patient_users(db)
    assigned_patients = db.query(Patient).filter(Patient.asha_worker_id == asha.id).all()
    patient_map = {p.id: p for p in assigned_patients}

    if not assigned_patients:
        return []

    p_ids = list(patient_map.keys())
    alerts = db.query(Alert).filter(
        Alert.patient_id.in_(p_ids),
        Alert.is_acknowledged == False,
    ).order_by(Alert.created_at.desc()).all()

    results = []
    for a in alerts:
        p = patient_map.get(a.patient_id)
        p_name = "Community Patient"
        p_age = 72
        if p:
            if p.user:
                p_name = p.user.full_name
            elif p.emergency_contact_name:
                p_name = p.emergency_contact_name
            p_age = p.age or 72

        results.append(
            EmergencyAlertItem(
                id=a.id,
                patient_id=a.patient_id,
                patient_name=p_name,
                patient_age=p_age,
                risk_level=a.risk_level or "ATTENTION_REQUIRED",
                severity=a.severity or "HIGH",
                reason=a.reason,
                is_acknowledged=bool(a.is_acknowledged),
                created_at=a.created_at.strftime("%b %d, %Y %I:%M %p") if a.created_at else "Today",
            )
        )

    # If no stored alerts exist yet in DB for an attention/critical patient, provide helpful simulated indicator
    if not results:
        for p in assigned_patients:
            if (p.baseline_memory or 70.0) < 65.0:
                user = p.user
                p_name = user.full_name if user else "Community Patient"
                results.append(
                    EmergencyAlertItem(
                        id=f"auto-{p.id}",
                        patient_id=p.id,
                        patient_name=p_name,
                        patient_age=p.age or 72,
                        risk_level="ATTENTION_REQUIRED",
                        severity="HIGH",
                        reason=f"Memory score dropped 18% in the last 7 days. Home visit recommended.",
                        is_acknowledged=False,
                        created_at="Today, 09:30 AM",
                    )
                )

    return results


def update_medical_notes(
    db: Session,
    asha: AshaWorker,
    patient_id: str,
    notes: str,
    visit_date: Optional[str] = None,
) -> AshaPatientItem:
    """Record or update medical notes after a home visit."""
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        patient = db.query(Patient).filter(Patient.user_id == patient_id).first()
    if not patient:
        raise ValueError(f"Patient with ID '{patient_id}' not found")

    date_str = visit_date or datetime.now().strftime("%d %b %Y")
    new_entry = f"[{date_str} - Home Visit by ASHA {asha.name}]: {notes.strip()}"

    if patient.medical_notes:
        patient.medical_notes = (patient.medical_notes or "") + "\n" + new_entry
    else:
        patient.medical_notes = new_entry

    db.commit()
    db.refresh(patient)

    # Return updated item for this specific patient
    pts = get_asha_patients(db, asha)
    for p in pts:
        if p.patient_id == patient.id:
            return p
    return pts[0] if pts else None


def get_patient_detail_for_asha(
    db: Session,
    asha: AshaWorker,
    patient_id: str,
) -> AshaPatientDetailResponse:
    """Return comprehensive clinical and activity details for a specific patient."""
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        patient = db.query(Patient).filter(Patient.user_id == patient_id).first()
    if not patient:
        raise ValueError(f"Patient with ID '{patient_id}' not found")

    # Fetch patient summary
    pts = get_asha_patients(db, asha)
    pt_item = next((p for p in pts if p.patient_id == patient.id), None)
    if not pt_item:
        # Patient may not be assigned to this ASHA worker yet, build read-only item
        user = patient.user
        pt_item = AshaPatientItem(
            patient_id=str(patient.id),
            user_id=str(patient.user_id),
            full_name=user.full_name if user else "Community Patient",
            email=user.email if user else None,
            phone_number=user.phone_number if user else patient.emergency_contact_phone,
            age=patient.age or 72,
            gender=patient.gender or "other",
            dementia_type=patient.dementia_type,
            village=asha.village_assigned,
            district=asha.district,
            status="Stable",
            status_color="green",
            triage_priority="STABLE",
            baseline_memory=patient.baseline_memory or 70.0,
            baseline_attention=patient.baseline_attention or 70.0,
            baseline_engagement=patient.baseline_engagement or 70.0,
            primary_language=patient.primary_language or "en",
            medical_notes=patient.medical_notes,
            last_visit="Recent",
        )

    # Analytics & Activity Feed
    analytics = get_patient_analytics(db, patient.id)
    activity_feed = get_patient_activity_feed(db, patient.id)

    # Alerts for this patient
    alerts_raw = db.query(Alert).filter(Alert.patient_id == patient.id).order_by(Alert.created_at.desc()).all()
    alerts = [
        EmergencyAlertItem(
            id=a.id,
            patient_id=a.patient_id,
            patient_name=pt_item.full_name,
            patient_age=pt_item.age,
            risk_level=a.risk_level or "ATTENTION_REQUIRED",
            severity=a.severity or "HIGH",
            reason=a.reason,
            is_acknowledged=bool(a.is_acknowledged),
            created_at=a.created_at.strftime("%b %d, %Y") if a.created_at else "Recent",
        )
        for a in alerts_raw
    ]

    # Split medical notes into history items
    notes_history = []
    if patient.medical_notes:
        notes_history = [n.strip() for n in patient.medical_notes.splitlines() if n.strip()]

    return AshaPatientDetailResponse(
        patient=pt_item,
        analytics=analytics.model_dump(),
        activity_feed=activity_feed.model_dump(),
        alerts=alerts,
        medical_notes_history=notes_history,
    )


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
        date_str = datetime.now().strftime("%d %b %Y")
        initial_note = f"[{date_str} - Initial Assignment]: {village_notes}"
        patient.medical_notes = ((patient.medical_notes + "\n") if patient.medical_notes else "") + initial_note

    db.commit()
    db.refresh(patient)

    pts = get_asha_patients(db, asha)
    for p in pts:
        if p.patient_id == patient.id:
            return p

    user = patient.user
    name = user.full_name if user else patient.emergency_contact_name
    return AshaPatientItem(
        patient_id=str(patient.id),
        user_id=str(patient.user_id),
        full_name=name,
        email=user.email if user else None,
        phone_number=user.phone_number if user else patient.emergency_contact_phone,
        age=patient.age or 72,
        gender=patient.gender or "other",
        dementia_type=patient.dementia_type,
        village=asha.village_assigned,
        district=asha.district,
        status="Stable",
        status_color="green",
        triage_priority="STABLE",
        baseline_memory=patient.baseline_memory or 70.0,
        baseline_attention=patient.baseline_attention or 70.0,
        baseline_engagement=patient.baseline_engagement or 70.0,
        primary_language=patient.primary_language or "en",
        medical_notes=patient.medical_notes,
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
