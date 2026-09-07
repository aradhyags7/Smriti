# SMRITI - Daily Check-in Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Integer, Text, ForeignKey, Float, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

class DailyCheckin(Base):
    __tablename__ = "daily_checkins"

    id = Column(String, primary_key=True, index=True)
    client_checkin_id = Column(String, unique=True, index=True, nullable=False)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    mood_score = Column(Integer, nullable=False, default=4)  # 1 to 5 scale
    sleep_hours = Column(Float, nullable=False, default=7.0) 
    symptoms_noted = Column(Text, nullable=True)
    checkin_time = Column(DateTime, nullable=False, default=datetime.utcnow, index=True)
    sync_status = Column(String, default="SYNCED")

    patient = relationship("Patient", back_populates="checkins")
