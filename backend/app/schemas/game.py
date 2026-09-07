"""Cognitive game performance and assessment schemas."""

from datetime import datetime
from pydantic import BaseModel, ConfigDict


class GameAttemptCreate(BaseModel):
    """Payload for submitting a game attempt."""
    patient_id: str
    game_type: str
    score: int
    mistakes: int
    reaction_time_ms: int
    difficulty: str
    client_timestamp: datetime


class GameAttemptOut(GameAttemptCreate):
    """Game attempt response schema with ORM mode enabled."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    played_at: datetime
