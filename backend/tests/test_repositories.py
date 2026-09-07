# SMRITI - Repository Unit Tests
# Owner: Aradhya (AI + Database + Sync)

import pytest
from datetime import datetime
from app.models import (
    User,
    Caregiver,
    Patient,
    Session,
    GameAttempt,
    DailyCheckin,
    Reminder,
    Reminiscence,
    CognitiveMetric,
    CognitiveTrend,
    Alert,
)
from app.repositories import (
    UserRepository,
    PatientRepository,
    SessionRepository,
    GameRepository,
    CheckinRepository,
    ReminderRepository,
    ReminiscenceRepository,
    CognitiveRepository,
    TrendRepository,
    AlertRepository,
    SyncRepository,
)

def test_user_and_patient_repositories(db_session):
    user_repo = UserRepository(db_session)
    patient_repo = PatientRepository(db_session)

    # User CRUD
    u = User(
        id="usr_rep_1",
        email="caregiver.aradhya@test.com",
        hashed_password="password_hash_123",
        role="CAREGIVER",
    )
    user_repo.save(u)

    retrieved_u = user_repo.get_by_id("usr_rep_1")
    assert retrieved_u is not None
    assert retrieved_u.email == "caregiver.aradhya@test.com"

    by_email = user_repo.get_by_email("caregiver.aradhya@test.com")
    assert by_email is not None
    assert by_email.id == "usr_rep_1"

    # Caregiver profile
    cg = Caregiver(
        id="cg_rep_1",
        user_id=u.id,
        name="Aradhya Caregiver",
        phone="+919988776655",
        relationship_to_patient="Primary Caregiver",
    )
    db_session.add(cg)
    db_session.commit()

    # Patient CRUD
    pat = Patient(
        id="pat_rep_1",
        caregiver_id=cg.id,
        name="Lila Bordoloi",
        age=68,
        language="as",
        location="Jorhat, Assam",
        baseline_memory=72.0,
        baseline_attention=68.0,
        baseline_engagement=80.0,
        consent_for_asha=True,
    )
    patient_repo.save(pat)

    retrieved_pat = patient_repo.get_by_id("pat_rep_1")
    assert retrieved_pat is not None
    assert retrieved_pat.name == "Lila Bordoloi"

    all_patients = patient_repo.get_all()
    assert len(all_patients) >= 1

    cg_patients = patient_repo.get_by_caregiver(cg.id)
    assert len(cg_patients) == 1
    assert cg_patients[0].id == "pat_rep_1"

def test_activity_and_intelligence_repositories(db_session):
    patient = Patient(
        id="pat_rep_2",
        name="Biren Saikia",
        age=75,
        language="as",
        location="Nagaon, Assam",
    )
    db_session.add(patient)
    db_session.commit()

    # 1. Session & Game
    session_repo = SessionRepository(db_session)
    game_repo = GameRepository(db_session)

    ses = Session(
        id="ses_rep_1",
        patient_id=patient.id,
        session_type="DAILY_CST",
        duration_seconds=600,
    )
    session_repo.save_session(ses)
    patient_sessions = session_repo.get_patient_sessions(patient.id)
    assert len(patient_sessions) == 1
    assert patient_sessions[0].id == "ses_rep_1"

    ga = GameAttempt(
        id="ga_rep_1",
        session_id=ses.id,
        patient_id=patient.id,
        game_type="odd_one_out",
        score=90.0,
        mistakes=0,
        reaction_time_ms=1100.0,
        difficulty="EASY",
    )
    game_repo.save_game_attempt(ga)
    attempts = game_repo.get_patient_attempts(patient.id)
    assert len(attempts) == 1
    assert attempts[0].score == 90.0

    # 2. Daily Check-in
    checkin_repo = CheckinRepository(db_session)
    chk = DailyCheckin(
        id="chk_rep_1",
        patient_id=patient.id,
        mood=5,
        sleep_quality=4,
        activity_level=4,
        notes="Active day",
    )
    checkin_repo.save_checkin(chk)
    checkins = checkin_repo.get_patient_checkins(patient.id)
    assert len(checkins) == 1
    assert checkins[0].mood == 5

    # 3. Reminder & Reminiscence
    reminder_repo = ReminderRepository(db_session)
    rem = Reminder(
        id="rem_rep_1",
        patient_id=patient.id,
        title="Evening Walk",
        reminder_type="ROUTINE",
        scheduled_time=datetime.utcnow(),
        is_acknowledged=False,
    )
    rem = reminder_repo.save_reminder(rem)
    reminders = reminder_repo.get_patient_reminders(patient.id)
    assert len(reminders) == 1
    assert reminders[0].is_acknowledged is False

    reminder_repo.acknowledge_reminder("rem_rep_1")
    db_session.refresh(rem)
    assert rem.is_acknowledged is True

    reminiscence_repo = ReminiscenceRepository(db_session)
    mem = Reminiscence(
        id="mem_rep_1",
        patient_id=patient.id,
        title="Garden Tea Time",
        person_name="Biren",
        relationship_label="Self",
        image_path="local://tea_garden.jpg",
    )
    reminiscence_repo.save_reminiscence(mem)
    memories = reminiscence_repo.get_patient_memories(patient.id)
    assert len(memories) == 1

    # 4. Cognitive Metric & Trend
    cog_repo = CognitiveRepository(db_session)
    trend_repo = TrendRepository(db_session)

    metric = CognitiveMetric(
        id="met_rep_1",
        patient_id=patient.id,
        date="2026-09-07",
        memory_score=78.0,
        attention_score=75.0,
        engagement_score=80.0,
        composite_score=77.45,
    )
    cog_repo.save_metric(metric)
    latest_metric = cog_repo.get_latest_metric(patient.id)
    assert latest_metric is not None
    assert latest_metric.composite_score == 77.45

    tr = CognitiveTrend(
        id="tr_rep_1",
        patient_id=patient.id,
        window_start="2026-09-01",
        window_end="2026-09-07",
        rolling_memory=75.0,
        rolling_attention=72.0,
        rolling_engagement=78.0,
        delta_memory_pct=-2.0,
        delta_attention_pct=-1.5,
        delta_engagement_pct=3.0,
        composite_score=74.7,
        risk_score=25.3,
        risk_level="STABLE",
    )
    trend_repo.save_trend(tr)
    latest_trend = trend_repo.get_latest_trend(patient.id)
    assert latest_trend is not None
    assert latest_trend.risk_level == "STABLE"

    # 5. Alert & Sync Repositories
    alert_repo = AlertRepository(db_session)
    alt = Alert(
        id="alt_rep_1",
        patient_id=patient.id,
        risk_score=65.0,
        risk_level="ATTENTION_REQUIRED",
        severity="HIGH",
        reason="Noticeable performance variability across 7 days.",
        is_acknowledged=False,
    )
    alert_repo.save_alert(alt)
    unack_alerts = alert_repo.get_unacknowledged_alerts()
    assert len(unack_alerts) >= 1
    assert any(a.id == "alt_rep_1" for a in unack_alerts)

    alert_repo.acknowledge_alert("alt_rep_1")
    db_session.refresh(alt)
    assert alt.is_acknowledged is True

    sync_repo = SyncRepository(db_session)
    assert sync_repo.is_event_processed("evt_unique_123") is False

    sync_repo.record_sync_event(
        event_id="evt_unique_123",
        patient_id=patient.id,
        event_type="GAME_ATTEMPT",
        local_id=1,
        payload={"score": 85},
        sync_status="SYNCED",
    )
    assert sync_repo.is_event_processed("evt_unique_123") is True
