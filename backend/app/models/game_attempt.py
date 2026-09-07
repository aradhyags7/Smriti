# SMRITI - Game Attempt Entity
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

class GameAttempt(Base):
    __tablename__ = "game_attempts"

    id = Column(String, primary_key=True, index=True)
    client_attempt_id = Column(String, unique=True, index=True, nullable=False)
    session_id = Column(String, ForeignKey("sessions.id"), nullable=True, index=True)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False, index=True)
    game_type = Column(String, nullable=False)  # 'memory_pairs', 'odd_one_out', 'simon_says', 'object_naming'
    score = Column(Float, nullable=False)
    mistakes = Column(Integer, default=0)
    reaction_time_ms = Column(Float, default=0.0)
    completion_time_seconds = Column(Integer, default=0)
    difficulty = Column(String, default="easy")  # easy, medium, hard
    completed = Column(Boolean, default=True)
    completed_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    sync_status = Column(String, default="SYNCED")

    patient = relationship("Patient", back_populates="game_attempts")
    session = relationship("Session", back_populates="attempts")
