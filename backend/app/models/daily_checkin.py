# SMRITI - Daily Check-in Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Integer, Text, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class DailyCheckin(Base):
    __tablename__ = "daily_checkins"

    id = Column(String, primary_key=True, index=True)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    mood = Column(Integer, nullable=False, default=4)  # 1 to 5 scale
    sleep_quality = Column(Integer, nullable=False, default=3)  # 1 to 5 scale
    activity_level = Column(Integer, nullable=False, default=3)  # 1 to 5 scale
    notes = Column(Text, nullable=True)
    timestamp = Column(String, nullable=False, default=lambda: datetime.utcnow().isoformat(), index=True)
    sync_status = Column(String, default="SYNCED")

    patient = relationship("Patient", back_populates="checkins")
