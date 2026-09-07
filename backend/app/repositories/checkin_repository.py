# SMRITI - Daily Check-in Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import List
from sqlalchemy.orm import Session
from backend.app.models.daily_checkin import DailyCheckin

class CheckinRepository:
    def __init__(self, db: Session):
        self.db = db

    def save_checkin(self, checkin: DailyCheckin) -> DailyCheckin:
        self.db.add(checkin)
        self.db.commit()
        self.db.refresh(checkin)
        return checkin

    def get_recent_checkins(self, patient_id: str, since_timestamp: str) -> List[DailyCheckin]:
        return (
            self.db.query(DailyCheckin)
            .filter(
                DailyCheckin.patient_id == patient_id,
                DailyCheckin.timestamp >= since_timestamp
            )
            .order_by(DailyCheckin.timestamp.asc())
            .all()
        )

    def get_patient_checkins(self, patient_id: str, limit: int = 30) -> List[DailyCheckin]:
        return (
            self.db.query(DailyCheckin)
            .filter(DailyCheckin.patient_id == patient_id)
            .order_by(DailyCheckin.timestamp.desc())
            .limit(limit)
            .all()
        )
