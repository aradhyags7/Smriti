# SMRITI - Cognitive Metric Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class CognitiveMetric(Base):
    __tablename__ = "cognitive_metrics"

    id = Column(String, primary_key=True, index=True)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    date = Column(String, nullable=False, index=True)
    memory_score = Column(Float, nullable=False, default=70.0)
    attention_score = Column(Float, nullable=False, default=70.0)
    engagement_score = Column(Float, nullable=False, default=70.0)
    composite_score = Column(Float, nullable=False, default=70.0)
    calculated_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", back_populates="cognitive_metrics")
