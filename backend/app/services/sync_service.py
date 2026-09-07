"""Offline sync service business logic."""

from sqlalchemy.orm import Session

from datetime import datetime
from app.models import GameAttempt, DailyCheckin
from app.schemas.sync import SyncPayloadRequest, SyncPayloadResponse


def process_offline_sync(db: Session, payload: SyncPayloadRequest) -> SyncPayloadResponse:
    """Process a batch of offline cognitive game records uploaded by a device.

    Iterates over all submitted game attempts, adds them to the session,
    commits the transaction, and returns a sync response summary.
    """
    total_synced = 0
    if payload.pending_games:
        for game_data in payload.pending_games:
            attempt = GameAttempt(**game_data.model_dump())
            db.add(attempt)
            total_synced += 1

    if payload.pending_checkins:
        for checkin_data in payload.pending_checkins:
            checkin = DailyCheckin(**checkin_data.model_dump())
            db.add(checkin)
            total_synced += 1

    db.commit()

    return SyncPayloadResponse(
        status="success",
        records_synced=total_synced,
        timestamp=datetime.utcnow(),
    )
