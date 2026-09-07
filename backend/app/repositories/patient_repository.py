# SMRITI - Patient Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import Optional, List, Dict
from sqlalchemy.orm import Session
from backend.app.models.patient import Patient

class PatientRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, patient_id: str) -> Optional[Patient]:
        return self.db.query(Patient).filter(Patient.id == patient_id).first()

    def get_all(self) -> List[Patient]:
        return self.db.query(Patient).all()

    def get_by_caregiver(self, caregiver_id: str) -> List[Patient]:
        return self.db.query(Patient).filter(Patient.caregiver_id == caregiver_id).all()

    def save(self, patient: Patient) -> Patient:
        merged = self.db.merge(patient)
        self.db.commit()
        return merged

    def update_consent(self, patient_id: str, consent_for_asha: bool) -> Optional[Patient]:
        patient = self.get_by_id(patient_id)
        if patient:
            patient.consent_for_asha = consent_for_asha
            self.db.commit()
            self.db.refresh(patient)
        return patient

    def update_baseline(self, patient_id: str, baseline_memory: float, baseline_attention: float, baseline_engagement: float) -> Optional[Patient]:
        patient = self.get_by_id(patient_id)
        if patient:
            patient.baseline_memory = baseline_memory
            patient.baseline_attention = baseline_attention
            patient.baseline_engagement = baseline_engagement
            self.db.commit()
            self.db.refresh(patient)
        return patient
