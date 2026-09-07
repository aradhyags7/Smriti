"""Cognitive game assessment service business logic."""

from sqlalchemy.orm import Session

from app.models.models import GameAttempt
from app.schemas.game import GameAttemptCreate


def record_game_attempt(db: Session, data: GameAttemptCreate) -> GameAttempt:
    """Record a single cognitive game attempt into the database."""
    attempt = GameAttempt(**data.model_dump())
    db.add(attempt)
    db.commit()
    db.refresh(attempt)
    return attempt
