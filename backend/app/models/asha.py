# SMRITI - ASHA Worker Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class AshaWorker(Base):
    __tablename__ = "asha_workers"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    village_assigned = Column(String, nullable=False)
    district = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="asha_profile")
    assigned_patients = relationship("Patient", back_populates="asha_worker")
