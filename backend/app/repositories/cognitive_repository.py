# SMRITI - Cognitive Metric Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.cognitive_metric import CognitiveMetric

class CognitiveRepository:
    def __init__(self, db: Session):
        self.db = db

    def save_metric(self, metric: CognitiveMetric) -> CognitiveMetric:
        self.db.add(metric)
        self.db.commit()
        self.db.refresh(metric)
        return metric

    def get_metrics_for_period(self, patient_id: str, start_date: str, end_date: str) -> List[CognitiveMetric]:
        return (
            self.db.query(CognitiveMetric)
            .filter(
                CognitiveMetric.patient_id == patient_id,
                CognitiveMetric.date >= start_date,
                CognitiveMetric.date <= end_date,
            )
            .order_by(CognitiveMetric.date.asc())
            .all()
        )

    def get_latest_metric(self, patient_id: str) -> Optional[CognitiveMetric]:
        return (
            self.db.query(CognitiveMetric)
            .filter(CognitiveMetric.patient_id == patient_id)
            .order_by(CognitiveMetric.calculated_at.desc())
            .first()
        )
