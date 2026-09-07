# SMRITI - Cognitive Trend Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class CognitiveTrend(Base):
    __tablename__ = "cognitive_trends"

    id = Column(String, primary_key=True, index=True)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    window_start = Column(String, nullable=False)
    window_end = Column(String, nullable=False)
    rolling_memory = Column(Float, nullable=False, default=70.0)
    rolling_attention = Column(Float, nullable=False, default=70.0)
    rolling_engagement = Column(Float, nullable=False, default=70.0)
    delta_memory_pct = Column(Float, default=0.0)
    delta_attention_pct = Column(Float, default=0.0)
    delta_engagement_pct = Column(Float, default=0.0)
    composite_score = Column(Float, default=70.0)
    risk_score = Column(Float, default=30.0)
    risk_level = Column(String, default="STABLE")  # STABLE, MONITOR, ATTENTION_REQUIRED
    disclaimer = Column(
        String,
        default="The prototype cognitive-performance risk score is a decision-support indicator and is not a medical diagnosis."
    )
    calculated_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", back_populates="trends")
