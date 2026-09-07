# SMRITI - Reminder Entity
# Owner: Aradhya (AI + Database + Sync)

from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(String, primary_key=True, index=True)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    title = Column(String, nullable=False)
    reminder_type = Column(String, default="MEDICINE")  # MEDICINE, ROUTINE, HYDRATION, CHECKIN
    scheduled_time = Column(String, nullable=False)
    frequency = Column(String, default="DAILY")
    is_acknowledged = Column(Boolean, default=False)
    sync_status = Column(String, default="SYNCED")

    patient = relationship("Patient", back_populates="reminders")
