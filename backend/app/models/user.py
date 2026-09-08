# SMRITI - User Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

def utc_now():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    full_name = Column(String, nullable=False)
    phone_number = Column(String, unique=True, index=True, nullable=True)
    email = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String, nullable=False)
    role = Column(String, nullable=False, default="patient")  # patient, caregiver, asha
    preferred_language = Column(String, default="en")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now)

    caregiver_profile = relationship("Caregiver", back_populates="user", uselist=False)
    asha_profile = relationship("AshaWorker", back_populates="user", uselist=False)
    patient_profile = relationship("Patient", back_populates="user", uselist=False)
