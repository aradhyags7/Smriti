# SMRITI - Session Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.session import Session as DbSession

class SessionRepository:
    def __init__(self, db: Session):
        self.db = db

    def save_session(self, session: DbSession) -> DbSession:
        merged = self.db.merge(session)
        self.db.commit()
        return merged

    def get_recent_sessions(self, patient_id: str, since_date: str) -> List[DbSession]:
        return (
            self.db.query(DbSession)
            .filter(
                DbSession.patient_id == patient_id,
                DbSession.started_at >= since_date
            )
            .order_by(DbSession.started_at.asc())
            .all()
        )

    def get_patient_sessions(self, patient_id: str, limit: int = 50) -> List[DbSession]:
        return (
            self.db.query(DbSession)
            .filter(DbSession.patient_id == patient_id)
            .order_by(DbSession.started_at.desc())
            .limit(limit)
            .all()
        )
