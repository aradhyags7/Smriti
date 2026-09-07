# SMRITI - Patient Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, Date, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base

def utc_now():
    return datetime.now(timezone.utc)

class Patient(Base):
    __tablename__ = "patients"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), unique=True, nullable=False)
    caregiver_id = Column(String, ForeignKey("caregivers.id"), nullable=True)
    asha_worker_id = Column(String, ForeignKey("asha_workers.id"), nullable=True)
    
    date_of_birth = Column(Date, nullable=False)
    gender = Column(String, nullable=False)
    education_level = Column(String, default="none")
    primary_language = Column(String, default="hi")
    emergency_contact_name = Column(String, nullable=False)
    emergency_contact_phone = Column(String, nullable=False)
    medical_notes = Column(String, nullable=True)
    
    consent_for_asha = Column(Boolean, default=True)
    baseline_memory = Column(Float, default=70.0)
    baseline_attention = Column(Float, default=70.0)
    baseline_engagement = Column(Float, default=70.0)
    
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now)

    user = relationship("User", back_populates="patient_profile")
    caregiver = relationship("Caregiver", back_populates="patients")
    asha_worker = relationship("AshaWorker", back_populates="assigned_patients")
    sessions = relationship("Session", back_populates="patient", cascade="all, delete-orphan")
    game_attempts = relationship("GameAttempt", back_populates="patient", cascade="all, delete-orphan")
    checkins = relationship("DailyCheckin", back_populates="patient", cascade="all, delete-orphan")
    reminders = relationship("Reminder", back_populates="patient", cascade="all, delete-orphan")
    memories = relationship("Reminiscence", back_populates="patient", cascade="all, delete-orphan")
    cognitive_metrics = relationship("CognitiveMetric", back_populates="patient", cascade="all, delete-orphan")
    trends = relationship("CognitiveTrend", back_populates="patient", cascade="all, delete-orphan")
    alerts = relationship("Alert", back_populates="patient", cascade="all, delete-orphan")
    sync_records = relationship("SyncRecord", back_populates="patient", cascade="all, delete-orphan")
