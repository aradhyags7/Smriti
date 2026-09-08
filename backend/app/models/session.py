# SMRITI - Session Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Session(Base):
    __tablename__ = "sessions"

    id = Column(String, primary_key=True, index=True)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    session_type = Column(String, nullable=False, default="DAILY_CST")
    duration_seconds = Column(Integer, default=0)
    started_at = Column(String, nullable=False, default=lambda: datetime.utcnow().isoformat())
    completed_at = Column(String, nullable=True)
    sync_status = Column(String, default="SYNCED")  # PENDING, SYNCING, SYNCED, FAILED

    patient = relationship("Patient", back_populates="sessions")
    attempts = relationship("GameAttempt", back_populates="session", cascade="all, delete-orphan")
