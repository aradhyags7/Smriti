"""Cognitive game performance API routes."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.models import User
from app.schemas.game import GameAttemptCreate, GameAttemptOut
from app.services.game_service import record_game_attempt

router = APIRouter()


@router.post(
    "/attempt",
    response_model=GameAttemptOut,
    status_code=status.HTTP_201_CREATED,
    summary="Record a game attempt",
)
def record_attempt(
    attempt_data: GameAttemptCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Record an individual cognitive game session attempt (requires authentication)."""
    return record_game_attempt(db=db, data=attempt_data)
