# SMRITI - Reminiscence Entity
# Owner: Aradhya (AI + Database + Sync)

from sqlalchemy import Column, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Reminiscence(Base):
    __tablename__ = "reminiscences"

    id = Column(String, primary_key=True, index=True)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    title = Column(String, nullable=False)
    person_name = Column(String, nullable=True)
    relationship_label = Column(String, nullable=True)
    image_path = Column(String, nullable=False)
    audio_path = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    sync_status = Column(String, default="SYNCED")

    patient = relationship("Patient", back_populates="memories")
