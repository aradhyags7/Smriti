# SMRITI - Reminiscence Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Optional
from sqlalchemy.orm import Session
from backend.app.models.reminiscence import Reminiscence

class ReminiscenceRepository:
    def __init__(self, db: Session):
        self.db = db

    def save(self, item: Reminiscence) -> Reminiscence:
        merged = self.db.merge(item)
        self.db.commit()
        return merged

    def save_reminiscence(self, item: Reminiscence) -> Reminiscence:
        return self.save(item)

    def get_by_patient(self, patient_id: str) -> List[Reminiscence]:
        return (
            self.db.query(Reminiscence)
            .filter(Reminiscence.patient_id == patient_id)
            .all()
        )

    def get_patient_memories(self, patient_id: str) -> List[Reminiscence]:
        return self.get_by_patient(patient_id)
