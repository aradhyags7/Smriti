# SMRITI - Sync Batch Processor Unit Tests
# Owner: Aradhya (AI + Database + Sync)

import pytest
import uuid
from datetime import datetime
from app.models.patient import Patient
from app.models.game_attempt import GameAttempt
from app.models.daily_checkin import DailyCheckin
from app.models.sync_record import SyncRecord
from app.sync.sync_processor import SyncProcessor
from app.sync.sync_validator import SyncValidator
from app.sync.sync_conflict import SyncConflictResolver

def test_sync_validator():
    # Valid payload
    valid_payload = {
        "patient_id": "pat_test_1",
        "sync_version": "1.0",
        "events": [
            {
                "event_id": str(uuid.uuid4()),
                "local_id": 1,
                "patient_id": "pat_test_1",
                "event_type": "GAME_ATTEMPT",
                "created_at": datetime.utcnow().isoformat(),
                "payload": {"score": 85.0},
                "sync_status": "PENDING"
            }
        ]
    }
    is_valid, err = SyncValidator.validate_payload(valid_payload)
    assert is_valid is True
    assert err is None

    # Invalid: Missing patient_id
    invalid_1 = {"events": []}
    is_valid, err = SyncValidator.validate_payload(invalid_1)
    assert is_valid is False
    assert "patient_id" in err

    # Invalid: events is not a list
    invalid_2 = {"patient_id": "pat_1", "events": "not_a_list"}
    is_valid, err = SyncValidator.validate_payload(invalid_2)
    assert is_valid is False
    assert "list" in err

    # Invalid event missing event_id
    invalid_event = {
        "patient_id": "pat_1",
        "events": [{"local_id": 1, "event_type": "GAME_ATTEMPT"}]
    }
    is_valid, err = SyncValidator.validate_payload(invalid_event)
    assert is_valid is False
    assert "event_id" in err

def test_sync_conflict_resolver():
    server_time = "2026-09-07T10:00:00"
    incoming_newer = "2026-09-07T10:05:00"
    incoming_older = "2026-09-07T09:55:00"

    # Last-write-wins: incoming newer should win
    assert SyncConflictResolver.should_overwrite(server_time, incoming_newer) is True

    # Incoming older should NOT overwrite
    assert SyncConflictResolver.should_overwrite(server_time, incoming_older) is False

    # Server None means no existing record, incoming wins
    assert SyncConflictResolver.should_overwrite(None, incoming_newer) is True

def test_sync_batch_processor_e2e_and_idempotency(db_session):
    processor = SyncProcessor(db_session)

    # Seed patient
    patient = Patient(
        id="pat_sync_100",
        name="Kamala Devi",
        age=72,
        language="as",
        location="Dibrugarh, Assam",
        consent_for_asha=True,
    )
    db_session.add(patient)
    db_session.commit()

    evt1_id = f"EVT-GAME-{uuid.uuid4().hex[:8]}"
    evt2_id = f"EVT-CHK-{uuid.uuid4().hex[:8]}"
    evt3_id = f"EVT-REM-{uuid.uuid4().hex[:8]}"
    evt4_id = f"EVT-SES-{uuid.uuid4().hex[:8]}"

    batch_payload = {
        "patient_id": patient.id,
        "sync_version": "1.0",
        "events": [
            {
                "event_id": evt1_id,
                "local_id": 1,
                "patient_id": patient.id,
                "event_type": "GAME_ATTEMPT",
                "created_at": "2026-09-07T08:00:00",
                "payload": {
                    "game_type": "memory_pairs",
                    "score": 92.0,
                    "mistakes": 1,
                    "reaction_time_ms": 1150.0,
                    "difficulty": "MEDIUM",
                    "completed": True,
                },
                "sync_status": "PENDING"
            },
            {
                "event_id": evt2_id,
                "local_id": 2,
                "patient_id": patient.id,
                "event_type": "DAILY_CHECKIN",
                "created_at": "2026-09-07T08:30:00",
                "payload": {
                    "mood": 5,
                    "sleep_quality": 4,
                    "activity_level": 3,
                    "notes": "Feeling energetic"
                },
                "sync_status": "PENDING"
            },
            {
                "event_id": evt3_id,
                "local_id": 3,
                "patient_id": patient.id,
                "event_type": "REMINDER",
                "created_at": "2026-09-07T09:00:00",
                "payload": {
                    "id": "rem_sync_1",
                    "title": "Drink Water",
                    "reminder_type": "ROUTINE",
                    "is_acknowledged": True
                },
                "sync_status": "PENDING"
            },
            {
                "event_id": evt4_id,
                "local_id": 4,
                "patient_id": patient.id,
                "event_type": "SESSION",
                "created_at": "2026-09-07T09:15:00",
                "payload": {
                    "id": "ses_sync_1",
                    "session_type": "DAILY_CST",
                    "duration_seconds": 900
                },
                "sync_status": "PENDING"
            },
        ]
    }

    # 1. First sync run - should process all 4 events
    response = processor.process_sync_batch(batch_payload)
    assert response.status == "success"
    assert response.synced_count == 4
    assert evt1_id in response.synced_event_ids
    assert evt2_id in response.synced_event_ids
    assert 1 in response.synced_local_ids
    assert 2 in response.synced_local_ids

    # Verify DB state
    games = db_session.query(GameAttempt).filter(GameAttempt.patient_id == patient.id).all()
    assert len(games) == 1
    assert games[0].score == 92.0
    assert games[0].sync_status == "SYNCED"

    checkins = db_session.query(DailyCheckin).filter(DailyCheckin.patient_id == patient.id).all()
    assert len(checkins) == 1
    assert checkins[0].mood == 5

    sync_records = db_session.query(SyncRecord).filter(SyncRecord.patient_id == patient.id).all()
    assert len(sync_records) == 4

    # 2. Re-submit the exact same batch (Idempotency check)
    response_dup = processor.process_sync_batch(batch_payload)
    assert response_dup.status == "success"
    assert response_dup.synced_count == 4  # Acknowledged as synced without re-inserting

    # Verify DB still only has 1 game attempt and 4 sync records (no duplicates created!)
    games_after = db_session.query(GameAttempt).filter(GameAttempt.patient_id == patient.id).all()
    assert len(games_after) == 1

    checkins_after = db_session.query(DailyCheckin).filter(DailyCheckin.patient_id == patient.id).all()
    assert len(checkins_after) == 1

    sync_records_after = db_session.query(SyncRecord).filter(SyncRecord.patient_id == patient.id).all()
    assert len(sync_records_after) == 4
