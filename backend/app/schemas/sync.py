"""Offline-first synchronization schemas."""

from datetime import datetime
from typing import List
from pydantic import BaseModel, ConfigDict

from app.schemas.game import GameAttemptCreate


class SyncBatchRequest(BaseModel):
    """Payload for uploading batch data from offline mobile devices."""
    device_id: str
    games: List[GameAttemptCreate]


class SyncBatchResponse(BaseModel):
    """Response returned after processing offline batch sync."""
    model_config = ConfigDict(from_attributes=True)

    status: str
    records_synced: int
    timestamp: datetime
