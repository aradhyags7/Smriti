# SMRITI - Caregiver Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class Caregiver(Base):
    __tablename__ = "caregivers"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    relationship_to_patient = Column(String, default="Family Caregiver")
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="caregiver_profile")
    patients = relationship("Patient", back_populates="caregiver")
