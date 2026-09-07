"""Offline sync service business logic."""

from sqlalchemy.orm import Session

from app.models.models import GameAttempt, utc_now
from app.schemas.sync import SyncBatchRequest, SyncBatchResponse


def process_offline_sync(db: Session, payload: SyncBatchRequest) -> SyncBatchResponse:
    """Process a batch of offline cognitive game records uploaded by a device.

    Iterates over all submitted game attempts, adds them to the session,
    commits the transaction, and returns a sync response summary.
    """
    for game_data in payload.games:
        attempt = GameAttempt(**game_data.model_dump())
        db.add(attempt)

    db.commit()

    return SyncBatchResponse(
        status="success",
        records_synced=len(payload.games),
        timestamp=utc_now(),
    )
