# SMRITI - Model Unit Tests
# Owner: Aradhya (AI + Database + Sync)

import pytest
from datetime import datetime
from sqlalchemy.exc import IntegrityError
from app.models import (
    User,
    Caregiver,
    AshaWorker,
    Patient,
    Session,
    GameAttempt,
    DailyCheckin,
    Reminder,
    Reminiscence,
    CognitiveMetric,
    CognitiveTrend,
    Alert,
    SyncRecord,
)

def test_models_creation_and_relationships(db_session):
    # 1. Create Users
    caregiver_user = User(
        id="usr_cg_1",
        email="rahul@example.com",
        hashed_password="hashed_secret_pw",
        role="CAREGIVER",
        is_active=True,
    )
    asha_user = User(
        id="usr_asha_1",
        email="anita.asha@assam.gov.in",
        hashed_password="hashed_secret_pw",
        role="ASHA",
        is_active=True,
    )
    patient_user = User(
        id="usr_pat_1",
        email="kamala.devi@smriti.local",
        hashed_password="hashed_secret_pw",
        role="PATIENT",
        is_active=True,
    )
    db_session.add_all([caregiver_user, asha_user, patient_user])
    db_session.commit()

    # 2. Create Profiles
    caregiver = Caregiver(
        id="cg_1",
        user_id=caregiver_user.id,
        name="Rahul Sharma",
        phone="+919876543210",
        relationship_to_patient="Son",
    )
    asha = AshaWorker(
        id="asha_1",
        user_id=asha_user.id,
        name="Anita Deka",
        phone="+919876500000",
        district="Dibrugarh",
        village_assigned="Lahowal",
    )
    db_session.add_all([caregiver, asha])
    db_session.commit()

    # 3. Create Patient
    patient = Patient(
        id="pat_1",
        user_id=patient_user.id,
        caregiver_id=caregiver.id,
        asha_worker_id=asha.id,
        name="Kamala Devi",
        age=72,
        language="as",
        location="Dibrugarh, Assam",
        baseline_memory=75.0,
        baseline_attention=70.0,
        baseline_engagement=85.0,
        consent_for_asha=True,
    )
    db_session.add(patient)
    db_session.commit()

    # Verify Patient Relationships
    assert patient.caregiver.name == "Rahul Sharma"
    assert patient.asha_worker.name == "Anita Deka"
    assert len(caregiver.patients) == 1
    assert caregiver.patients[0].id == "pat_1"

    # 4. Create Activities & Domain Entities
    session = Session(
        id="ses_1",
        patient_id=patient.id,
        session_type="DAILY_CST",
        duration_seconds=900,
        completed_at=datetime.utcnow(),
    )
    game_attempt = GameAttempt(
        id="ga_1",
        patient_id=patient.id,
        game_type="memory_pairs",
        score=85.0,
        mistakes=1,
        reaction_time_ms=1250.0,
        difficulty="MEDIUM",
        completed=True,
    )
    checkin = DailyCheckin(
        id="chk_1",
        patient_id=patient.id,
        mood=4,
        sleep_quality=4,
        activity_level=3,
        notes="Felt refreshed after morning tea.",
    )
    reminder = Reminder(
        id="rem_1",
        patient_id=patient.id,
        title="Morning Blood Pressure Medicine",
        reminder_type="MEDICINE",
        scheduled_time=datetime.utcnow(),
        frequency="DAILY",
        is_acknowledged=True,
    )
    memory = Reminiscence(
        id="rem_vault_1",
        patient_id=patient.id,
        title="Bihu Celebration 1985",
        person_name="Ananya (Daughter)",
        relationship_label="Daughter",
        image_path="local://memories/bihu_1985.jpg",
        audio_path="local://memories/bihu_audio.mp3",
        notes="Dancing at family gathering in Tezpur",
    )
    metric = CognitiveMetric(
        id="met_1",
        patient_id=patient.id,
        date="2026-09-07",
        memory_score=82.5,
        attention_score=78.0,
        engagement_score=85.0,
        composite_score=81.55,
    )
    trend = CognitiveTrend(
        id="tr_1",
        patient_id=patient.id,
        window_start="2026-09-01",
        window_end="2026-09-07",
        rolling_memory=80.0,
        rolling_attention=76.5,
        rolling_engagement=82.0,
        delta_memory_pct=6.7,
        delta_attention_pct=9.3,
        delta_engagement_pct=-3.5,
        composite_score=79.25,
        risk_score=20.75,
        risk_level="STABLE",
    )
    alert = Alert(
        id="alt_1",
        patient_id=patient.id,
        risk_score=68.5,
        risk_level="ATTENTION_REQUIRED",
        severity="HIGH",
        reason="Memory score decreased by 18% over rolling 7-day window.",
        disclaimer="Non-clinical decision-support metric.",
    )
    sync_rec = SyncRecord(
        id="syn_1",
        event_id="evt_uuid_101",
        patient_id=patient.id,
        event_type="GAME_ATTEMPT",
        local_id=1,
        sync_status="SYNCED",
    )

    db_session.add_all([
        session, game_attempt, checkin, reminder,
        memory, metric, trend, alert, sync_rec
    ])
    db_session.commit()

    # 5. Verify Navigation Collections from Patient
    db_session.refresh(patient)
    assert len(patient.sessions) == 1
    assert patient.sessions[0].session_type == "DAILY_CST"
    assert len(patient.game_attempts) == 1
    assert patient.game_attempts[0].game_type == "memory_pairs"
    assert len(patient.checkins) == 1
    assert patient.checkins[0].mood == 4
    assert len(patient.reminders) == 1
    assert patient.reminders[0].reminder_type == "MEDICINE"
    assert len(patient.memories) == 1
    assert patient.memories[0].title == "Bihu Celebration 1985"
    assert len(patient.cognitive_metrics) == 1
    assert patient.cognitive_metrics[0].composite_score == 81.55
    assert len(patient.trends) == 1
    assert patient.trends[0].risk_level == "STABLE"
    assert len(patient.alerts) == 1
    assert patient.alerts[0].severity == "HIGH"
    assert len(patient.sync_records) == 1
    assert patient.sync_records[0].event_id == "evt_uuid_101"

def test_sync_record_unique_event_id_constraint(db_session):
    rec1 = SyncRecord(
        id="syn_a",
        event_id="DUPLICATE_EVENT_UUID",
        patient_id="pat_dummy",
        event_type="GAME_ATTEMPT",
        local_id=10,
        sync_status="SYNCED",
    )
    db_session.add(rec1)
    db_session.commit()

    rec2 = SyncRecord(
        id="syn_b",
        event_id="DUPLICATE_EVENT_UUID",  # identical event_id
        patient_id="pat_dummy",
        event_type="GAME_ATTEMPT",
        local_id=10,
        sync_status="SYNCED",
    )
    db_session.add(rec2)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()
