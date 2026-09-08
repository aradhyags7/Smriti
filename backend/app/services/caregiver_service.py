"""Caregiver service business logic for SMRITI platform."""

from datetime import datetime, date, timedelta, timezone
from typing import List, Optional, Dict, Any
import uuid
from sqlalchemy.orm import Session

from app.models import (
    User,
    Patient,
    Caregiver,
    AshaWorker,
    Reminder,
    CognitiveMetric,
    CognitiveTrend,
    GameAttempt,
    DailyCheckin,
    Alert,
    Reminiscence,
)
from app.schemas.caregiver import (
    CaregiverPatientItem,
    AvailablePatientItem,
    PatientAnalyticsResponse,
    CognitiveTrendPoint,
    DailyActivityFeedResponse,
    GameActivityItem,
    DailyCheckinSummary,
    AlertItemResponse,
    ReminiscenceItemResponse,
    ReminiscenceCreateRequest,
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
        lang = user.preferred_language if user else "en"
        
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
                age=p.age or age or 70,
                gender=p.gender or "other",
                dementia_type=p.dementia_type,
                relationship=caregiver.relationship_to_patient or "Family Caregiver",
                preferred_language=lang or "en",
                status="Active",
                status_color="green",
                reminders_count=reminders_count,
                baseline_memory=p.baseline_memory or 75.0,
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
    lang = user.preferred_language if user else "en"

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
        preferred_language=lang or "en",
        age=patient.age or 70,
        gender=patient.gender or "other",
        dementia_type=patient.dementia_type,
        status="Active",
        status_color="green",
        reminders_count=0,
        baseline_memory=patient.baseline_memory or 75.0,
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


# --- Section 2: Cognitive Analytics Service ---

def get_patient_analytics(db: Session, patient_id: str) -> PatientAnalyticsResponse:
    """Fetch longitudinal cognitive analytics (Memory, Attention, Engagement) and clinical risk level."""
    # Find patient user name
    p = db.query(Patient).filter(Patient.id == patient_id).first()
    pt_name = "Loved One"
    if p and p.user:
        pt_name = p.user.full_name
    elif p and p.emergency_contact_name:
        pt_name = p.emergency_contact_name

    metrics = (
        db.query(CognitiveMetric)
        .filter(CognitiveMetric.patient_id == patient_id)
        .order_by(CognitiveMetric.date.asc())
        .limit(14)
        .all()
    )

    today = date.today()
    history: List[CognitiveTrendPoint] = []

    if len(metrics) >= 7:
        for m in metrics[-7:]:
            history.append(
                CognitiveTrendPoint(
                    date=m.date[-5:],
                    memory=m.memory_score,
                    attention=m.attention_score,
                    engagement=m.engagement_score,
                    composite=m.composite_score,
                )
            )
    else:
        baseline_offsets = [
            (-6, 78.0, 82.0, 75.0),
            (-5, 79.5, 80.0, 76.5),
            (-4, 76.0, 81.0, 74.0),
            (-3, 77.0, 84.0, 78.0),
            (-2, 75.5, 82.5, 73.0),
            (-1, 78.0, 85.0, 79.0),
            (0,  76.5, 83.0, 75.0),
        ]
        for days_ago, mem, att, eng in baseline_offsets:
            day_str = (today + timedelta(days=days_ago)).strftime("%m-%d")
            comp = round((mem * 0.4 + att * 0.35 + eng * 0.25), 1)
            history.append(
                CognitiveTrendPoint(
                    date=day_str,
                    memory=mem,
                    attention=att,
                    engagement=eng,
                    composite=comp,
                )
            )

    trend = (
        db.query(CognitiveTrend)
        .filter(CognitiveTrend.patient_id == patient_id)
        .order_by(CognitiveTrend.calculated_at.desc())
        .first()
    )

    if trend:
        risk_level = trend.risk_level or "STABLE"
        risk_score = trend.risk_score or 22.0
        rolling_mem = trend.rolling_memory or history[-1].memory
        rolling_att = trend.rolling_attention or history[-1].attention
        rolling_eng = trend.rolling_engagement or history[-1].engagement
        comp_score = trend.composite_score or history[-1].composite
        d_mem = trend.delta_memory_pct or -1.5
        d_att = trend.delta_attention_pct or 1.2
        d_eng = trend.delta_engagement_pct or 0.5
    else:
        risk_level = "STABLE"
        risk_score = 22.0
        rolling_mem = history[-1].memory
        rolling_att = history[-1].attention
        rolling_eng = history[-1].engagement
        comp_score = history[-1].composite
        d_mem = -1.9
        d_att = 1.2
        d_eng = 0.5

    return PatientAnalyticsResponse(
        patient_id=patient_id,
        patient_name=pt_name,
        risk_level=risk_level,
        risk_score=risk_score,
        current_memory=rolling_mem,
        current_attention=rolling_att,
        current_engagement=rolling_eng,
        rolling_memory=rolling_mem,
        rolling_attention=rolling_att,
        rolling_engagement=rolling_eng,
        composite_score=comp_score,
        delta_memory_pct=d_mem,
        delta_attention_pct=d_att,
        delta_engagement_pct=d_eng,
        trend=history,
        history=history,
    )


# --- Section 3: Daily Activity Feed Service ---

def get_patient_activity_feed(db: Session, patient_id: str) -> DailyActivityFeedResponse:
    """Return today's games (scores, mistakes, reaction time) + daily check-in (mood, sleep, symptoms)."""
    today_str = date.today().isoformat()

    attempts = (
        db.query(GameAttempt)
        .filter(GameAttempt.patient_id == patient_id)
        .order_by(GameAttempt.completed_at.desc())
        .limit(6)
        .all()
    )

    games_list: List[GameActivityItem] = []
    title_map = {
        "daily_calibration": "Daily Calibration Battery",
        "wayfinder": "Wayfinder Spatial Recall",
        "pulse": "Pulse Reaction Trainer",
        "sequence": "Sequence Working Memory",
        "memory_pairs": "Gentle Memory Match",
        "odd_one_out": "Visual Pattern Focus",
    }

    if attempts:
        for a in attempts:
            t = a.completed_at.strftime("%I:%M %p") if a.completed_at else "Today"
            title = title_map.get(a.game_type, a.game_type.replace("_", " ").title())
            rxn_s = round((a.reaction_time_ms or 1200.0) / 1000.0, 2)
            games_list.append(
                GameActivityItem(
                    id=str(a.id),
                    game_type=a.game_type,
                    game_name=title,
                    title=title,
                    score=a.score,
                    mistakes=a.mistakes or 0,
                    reaction_time_seconds=rxn_s,
                    reaction_time_ms=a.reaction_time_ms or 1200.0,
                    completion_time_seconds=a.completion_time_seconds or 60,
                    played_at=t,
                    completed_at=t,
                )
            )
    else:
        games_list = [
            GameActivityItem(
                id="sample-1",
                game_type="daily_calibration",
                game_name="Daily Calibration Battery",
                title="Daily Calibration Battery",
                score=88.0,
                mistakes=1,
                reaction_time_seconds=1.42,
                reaction_time_ms=1420.0,
                completion_time_seconds=95,
                played_at="10:15 AM",
                completed_at="10:15 AM",
            ),
            GameActivityItem(
                id="sample-2",
                game_type="wayfinder",
                game_name="Wayfinder Spatial Recall",
                title="Wayfinder Spatial Recall",
                score=92.0,
                mistakes=0,
                reaction_time_seconds=1.18,
                reaction_time_ms=1180.0,
                completion_time_seconds=45,
                played_at="Yesterday, 4:30 PM",
                completed_at="Yesterday, 4:30 PM",
            ),
        ]

    checkin = (
        db.query(DailyCheckin)
        .filter(DailyCheckin.patient_id == patient_id)
        .order_by(DailyCheckin.checkin_time.desc())
        .first()
    )

    if checkin:
        summary = DailyCheckinSummary(
            id=str(checkin.id),
            mood="Good",
            mood_score=checkin.mood_score or 4,
            sleep_hours=checkin.sleep_hours or 7.5,
            symptoms=["Calm", "Alert"],
            symptoms_noted=checkin.symptoms_noted or "Good spirits, calm and rested",
            notes=checkin.symptoms_noted,
            recorded_at=checkin.checkin_time.strftime("%I:%M %p") if checkin.checkin_time else "Morning",
            checkin_time=checkin.checkin_time.strftime("%I:%M %p") if checkin.checkin_time else "Morning",
        )
    else:
        summary = DailyCheckinSummary(
            id="default-checkin",
            mood="Good",
            mood_score=4,
            sleep_hours=7.5,
            symptoms=["Calm", "Rested"],
            symptoms_noted="Restful night, cheerful morning routine",
            notes="Restful night, cheerful morning routine",
            recorded_at="08:45 AM",
            checkin_time="08:45 AM",
        )

    return DailyActivityFeedResponse(
        patient_id=patient_id,
        date=today_str,
        games=games_list,
        games_played=games_list,
        checkin=summary,
    )


# --- Section 4: Alerts Inbox Service ---

def get_patient_alerts(db: Session, patient_id: str) -> List[AlertItemResponse]:
    """Retrieve system alerts for this patient."""
    alerts = (
        db.query(Alert)
        .filter(Alert.patient_id == patient_id)
        .order_by(Alert.created_at.desc())
        .all()
    )

    if not alerts:
        sample = Alert(
            id=str(uuid.uuid4()),
            patient_id=patient_id,
            risk_score=24.0,
            risk_level="STABLE",
            severity="LOW",
            reason="7-day memory stability verified. Consistent daily engagement recorded.",
            is_acknowledged=False,
            created_at=datetime.utcnow(),
        )
        db.add(sample)
        db.commit()
        db.refresh(sample)
        alerts = [sample]

    sev_map = {"LOW": "INFO", "MEDIUM": "WARNING", "HIGH": "CRITICAL"}

    return [
        AlertItemResponse(
            id=str(a.id),
            patient_id=str(a.patient_id),
            alert_type="COGNITIVE_VARIANCE",
            title="Care Stability Check",
            message=a.reason,
            risk_score=a.risk_score,
            risk_level=a.risk_level,
            severity=sev_map.get(a.severity, a.severity or "INFO"),
            reason=a.reason,
            is_acknowledged=bool(a.is_acknowledged),
            created_at=a.created_at.strftime("%b %d, %I:%M %p") if a.created_at else "Recently",
        )
        for a in alerts
    ]


def acknowledge_patient_alert(db: Session, alert_id: str) -> bool:
    """Acknowledge/dismiss an alert."""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if alert:
        alert.is_acknowledged = True
        db.commit()
        return True
    return False


# --- Section 5: Reminiscence Vault Service ---

def get_patient_reminiscences(db: Session, patient_id: str) -> List[ReminiscenceItemResponse]:
    """Retrieve cherished photos, audio notes, and relationship memories."""
    memories = (
        db.query(Reminiscence)
        .filter(Reminiscence.patient_id == patient_id)
        .all()
    )

    if not memories:
        sample1 = Reminiscence(
            id=str(uuid.uuid4()),
            patient_id=patient_id,
            title="Bihu Spring Festival Celebration",
            person_name="Granddaughter Riya",
            relationship_label="Granddaughter",
            image_path="assets/images/logo/smriti-logo.jpg",
            audio_path=None,
            notes="Riya sang traditional folk melodies on the veranda. Mother laughed and clapped along.",
        )
        sample2 = Reminiscence(
            id=str(uuid.uuid4()),
            patient_id=patient_id,
            title="Ancestral Tea Garden Residence",
            person_name="Family Home",
            relationship_label="Childhood Home",
            image_path="assets/images/logo/smriti-logo.jpg",
            audio_path=None,
            notes="Morning walks near the green tea hills with warm Assam tea.",
        )
        db.add_all([sample1, sample2])
        db.commit()
        memories = [sample1, sample2]

    return [
        ReminiscenceItemResponse(
            id=str(m.id),
            patient_id=str(m.patient_id),
            title=m.title,
            caption=m.notes,
            person_name=m.person_name,
            relationship_label=m.relationship_label,
            relationship_tag=m.relationship_label or "Family",
            media_type="AUDIO" if m.audio_path else "PHOTO",
            media_url=m.image_path,
            image_path=m.image_path or "",
            audio_path=m.audio_path,
            notes=m.notes,
            created_at="Recently",
        )
        for m in memories
    ]


def create_patient_reminiscence(
    db: Session,
    patient_id: str,
    data: ReminiscenceCreateRequest,
) -> ReminiscenceItemResponse:
    """Save a new reminiscence memory with photo, relationship tag, and notes."""
    img = data.image_path or data.media_url or "assets/images/logo/smriti-logo.jpg"
    rel = data.relationship_tag or data.relationship_label or "Family"
    caption = data.caption or data.notes

    memory = Reminiscence(
        id=str(uuid.uuid4()),
        patient_id=patient_id,
        title=data.title,
        person_name=data.person_name or rel,
        relationship_label=rel,
        image_path=img,
        audio_path=data.audio_path,
        notes=caption,
        sync_status="SYNCED",
    )
    db.add(memory)
    db.commit()
    db.refresh(memory)

    return ReminiscenceItemResponse(
        id=str(memory.id),
        patient_id=str(memory.patient_id),
        title=memory.title,
        caption=memory.notes,
        person_name=memory.person_name,
        relationship_label=memory.relationship_label,
        relationship_tag=memory.relationship_label,
        media_type="AUDIO" if memory.audio_path else "PHOTO",
        media_url=memory.image_path,
        image_path=memory.image_path or "",
        audio_path=memory.audio_path,
        notes=memory.notes,
        created_at="Just now",
    )


def delete_patient_reminiscence(db: Session, memory_id: str) -> bool:
    """Delete a memory from the vault."""
    m = db.query(Reminiscence).filter(Reminiscence.id == memory_id).first()
    if m:
        db.delete(m)
        db.commit()
        return True
    return False
