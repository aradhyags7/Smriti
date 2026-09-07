# SMRITI - Alert Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class Alert(Base):
    __tablename__ = "alerts"

    id = Column(String, primary_key=True, index=True)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    risk_score = Column(Float, nullable=False)
    risk_level = Column(String, nullable=False)  # STABLE, MONITOR, ATTENTION_REQUIRED
    severity = Column(String, default="LOW")     # LOW, MEDIUM, HIGH
    reason = Column(Text, nullable=False)
    disclaimer = Column(
        String,
        default="The prototype cognitive-performance risk score is a decision-support indicator and is not a medical diagnosis."
    )
    patient_consent_given = Column(Boolean, default=True)
    asha_notified = Column(Boolean, default=False)
    is_acknowledged = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", back_populates="alerts")
