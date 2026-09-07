# SMRITI - Game Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.game_attempt import GameAttempt

class GameRepository:
    def __init__(self, db: Session):
        self.db = db

    def save_game_attempt(self, attempt: GameAttempt) -> GameAttempt:
        self.db.add(attempt)
        self.db.commit()
        self.db.refresh(attempt)
        return attempt

    def get_patient_attempts(self, patient_id: str, limit: int = 100) -> List[GameAttempt]:
        return (
            self.db.query(GameAttempt)
            .filter(GameAttempt.patient_id == patient_id)
            .order_by(GameAttempt.completed_at.desc())
            .limit(limit)
            .all()
        )

    def get_recent_attempts(self, patient_id: str, since_timestamp: str) -> List[GameAttempt]:
        return (
            self.db.query(GameAttempt)
            .filter(
                GameAttempt.patient_id == patient_id,
                GameAttempt.timestamp >= since_timestamp
            )
            .order_by(GameAttempt.timestamp.asc())
            .all()
        )
