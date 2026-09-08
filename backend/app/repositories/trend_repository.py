# SMRITI - Cognitive Trend Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.cognitive_trend import CognitiveTrend

class TrendRepository:
    def __init__(self, db: Session):
        self.db = db

    def save_trend(self, trend: CognitiveTrend) -> CognitiveTrend:
        self.db.add(trend)
        self.db.commit()
        self.db.refresh(trend)
        return trend

    def get_latest_trend(self, patient_id: str) -> Optional[CognitiveTrend]:
        return (
            self.db.query(CognitiveTrend)
            .filter(CognitiveTrend.patient_id == patient_id)
            .order_by(CognitiveTrend.calculated_at.desc())
            .first()
        )
