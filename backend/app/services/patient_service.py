"""Patient management service business logic."""

from typing import Optional
from sqlalchemy.orm import Session

from app.models import Patient
from app.schemas.patient import PatientCreate


def create_patient(db: Session, data: PatientCreate) -> Patient:
    """Create a new patient record in the database."""
    patient = Patient(**data.model_dump())
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return patient


def get_patient(db: Session, patient_id: str) -> Optional[Patient]:
    """Retrieve a patient by their unique identifier."""
    return db.query(Patient).filter(Patient.id == patient_id).first()
