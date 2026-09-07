# SMRITI - Sync Batch Processor
# Owner: Aradhya (AI + Database + Sync)

import uuid
from datetime import datetime
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from backend.app.models.patient import Patient
from backend.app.models.game_attempt import GameAttempt
from backend.app.models.daily_checkin import DailyCheckin
from backend.app.models.reminder import Reminder
from backend.app.models.session import Session as DbSession
from backend.app.repositories.patient_repository import PatientRepository
from backend.app.repositories.game_repository import GameRepository
from backend.app.repositories.checkin_repository import CheckinRepository
from backend.app.repositories.reminder_repository import ReminderRepository
from backend.app.repositories.session_repository import SessionRepository
from backend.app.repositories.sync_repository import SyncRepository
from .sync_validator import SyncValidator
from .sync_status import SyncAckResponse, SyncStatus

class SyncProcessor:
    def __init__(self, db: Session):
        self.db = db
        self.patient_repo = PatientRepository(db)
        self.game_repo = GameRepository(db)
        self.checkin_repo = CheckinRepository(db)
        self.reminder_repo = ReminderRepository(db)
        self.session_repo = SessionRepository(db)
        self.sync_repo = SyncRepository(db)

    def process_sync_batch(self, payload: Dict[str, Any]) -> SyncAckResponse:
        # 1. Validate payload structure
        is_valid, err_msg = SyncValidator.validate_payload(payload)
        if not is_valid:
            raise ValueError(err_msg)

        patient_id = payload["patient_id"]

        # Ensure patient exists or seed default
        patient = self.patient_repo.get_by_id(patient_id)
        if not patient:
            patient = Patient(
                id=patient_id,
                name="Kamala Devi",
                age=72,
                language="as",
                location="Dibrugarh, Assam",
                consent_for_asha=True,
            )
            self.patient_repo.save(patient)

        synced_event_ids: List[str] = []
        synced_local_ids: List[Any] = []

        events = payload.get("events", [])
        for event in events:
            event_id = event.get("event_id")
            event_type = str(event.get("event_type", "")).upper()
            local_id = event.get("local_id")
            event_payload = event.get("payload", {})
            created_at = event.get("created_at") or datetime.utcnow().isoformat()

            # 2. De-duplication: check if event was already processed
            if self.sync_repo.is_event_processed(event_id):
                synced_event_ids.append(event_id)
                if local_id is not None:
                    synced_local_ids.append(local_id)
                continue

            # 3. Route by event type to corresponding repository
            if event_type in ("GAME_ATTEMPT", "game_attempt"):
                attempt = GameAttempt(
                    id=f"GA-{uuid.uuid4().hex[:8]}",
                    patient_id=patient_id,
                    game_type=event_payload.get("game_type", "memory_pairs"),
                    score=float(event_payload.get("score", 70.0)),
                    mistakes=int(event_payload.get("mistakes", 0)),
                    reaction_time_ms=float(event_payload.get("reaction_time_ms", 1200.0)),
                    difficulty=str(event_payload.get("difficulty", "EASY")),
                    completed=bool(event_payload.get("completed", True)),
                    timestamp=created_at,
                    sync_status=SyncStatus.SYNCED.value,
                )
                self.game_repo.save_game_attempt(attempt)

            elif event_type in ("DAILY_CHECKIN", "daily_checkin"):
                checkin = DailyCheckin(
                    id=f"DC-{uuid.uuid4().hex[:8]}",
                    patient_id=patient_id,
                    mood=int(event_payload.get("mood", 4)),
                    sleep_quality=int(event_payload.get("sleep_quality", 3)),
                    activity_level=int(event_payload.get("activity_level", 3)),
                    notes=event_payload.get("notes"),
                    timestamp=created_at,
                    sync_status=SyncStatus.SYNCED.value,
                )
                self.checkin_repo.save_checkin(checkin)

            elif event_type in ("REMINDER", "reminder"):
                reminder = Reminder(
                    id=event_payload.get("id", f"REM-{uuid.uuid4().hex[:8]}"),
                    patient_id=patient_id,
                    title=event_payload.get("title", "Routine reminder"),
                    reminder_type=event_payload.get("reminder_type", "MEDICINE"),
                    scheduled_time=event_payload.get("scheduled_time", created_at),
                    frequency=event_payload.get("frequency", "DAILY"),
                    is_acknowledged=bool(event_payload.get("is_acknowledged", False)),
                    sync_status=SyncStatus.SYNCED.value,
                )
                self.reminder_repo.save_reminder(reminder)

            elif event_type in ("SESSION", "session"):
                session = DbSession(
                    id=event_payload.get("id", f"SES-{uuid.uuid4().hex[:8]}"),
                    patient_id=patient_id,
                    session_type=event_payload.get("session_type", "DAILY_CST"),
                    duration_seconds=int(event_payload.get("duration_seconds", 0)),
                    started_at=created_at,
                    completed_at=event_payload.get("completed_at"),
                    sync_status=SyncStatus.SYNCED.value,
                )
                self.session_repo.save_session(session)

            # Record in sync audit table for idempotency
            self.sync_repo.record_sync_event(
                event_id=event_id,
                patient_id=patient_id,
                event_type=event_type,
                local_id=local_id,
                payload=event_payload,
                sync_status=SyncStatus.SYNCED.value,
            )

            synced_event_ids.append(event_id)
            if local_id is not None:
                synced_local_ids.append(local_id)

        return SyncAckResponse(
            status="success",
            synced_count=len(synced_event_ids),
            synced_event_ids=synced_event_ids,
            synced_local_ids=synced_local_ids,
            message=f"Synchronized {len(synced_event_ids)} offline events successfully.",
        )
