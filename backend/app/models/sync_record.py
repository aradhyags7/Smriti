# SMRITI - Sync Record Entity (Idempotency & De-duplication)
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class SyncRecord(Base):
    __tablename__ = "sync_records"

    id = Column(String, primary_key=True, index=True)
    event_id = Column(String, unique=True, index=True, nullable=False)  # Universal UUID prevents duplicate uploads
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    event_type = Column(String, nullable=False)  # GAME_ATTEMPT, DAILY_CHECKIN, REMINDER, etc.
    local_id = Column(Integer, nullable=True)
    payload_json = Column(Text, nullable=True)
    sync_status = Column(String, default="SYNCED")  # PENDING, SYNCING, SYNCED, FAILED
    created_at = Column(String, nullable=True)
    synced_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", back_populates="sync_records")
