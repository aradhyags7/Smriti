# SMRITI - User Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, nullable=False, default="PATIENT")  # PATIENT, CAREGIVER, ASHA, ADMIN
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    caregiver_profile = relationship("Caregiver", back_populates="user", uselist=False)
    asha_profile = relationship("AshaWorker", back_populates="user", uselist=False)
    patient_profile = relationship("Patient", back_populates="user", uselist=False)
