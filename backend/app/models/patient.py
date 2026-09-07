# SMRITI - Patient Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class Patient(Base):
    __tablename__ = "patients"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    caregiver_id = Column(String, ForeignKey("caregivers.id"), nullable=True)
    asha_worker_id = Column(String, ForeignKey("asha_workers.id"), nullable=True)
    name = Column(String, nullable=False)
    age = Column(Integer, nullable=False)
    language = Column(String, default="as")  # 'as', 'bn', 'hi', 'en'
    location = Column(String, nullable=False, default="Dibrugarh, Assam")
    consent_for_asha = Column(Boolean, default=True)  # Consent gate for rural triage sharing
    baseline_memory = Column(Float, default=70.0)
    baseline_attention = Column(Float, default=70.0)
    baseline_engagement = Column(Float, default=70.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

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
