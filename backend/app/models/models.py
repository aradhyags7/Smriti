"""SQLAlchemy Database Models for SMRITI Backend.

Defines the database schema, entity relationships, and table definitions
for patients, users, cognitive assessments, gaming sessions, offline sync,
and caregiver alerts.
"""

from datetime import datetime, timezone
import enum
from typing import List, Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    Enum as SQLEnum,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


def utc_now() -> datetime:
    """Return the current timezone-aware UTC datetime."""
    return datetime.now(timezone.utc)


class UserRole(str, enum.Enum):
    """Roles supported within the SMRITI platform."""
    PATIENT = "patient"
    CAREGIVER = "caregiver"
    ASHA = "asha"
    ADMIN = "admin"


class User(Base):
    """User account model for authentication and role-based access control."""
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        SQLEnum(UserRole, native_enum=False, values_callable=lambda obj: [e.value for e in obj]),
        nullable=False,
        default=UserRole.PATIENT,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )

    # Relationships
    patient_profile: Mapped[Optional["Patient"]] = relationship(
        "Patient",
        foreign_keys="[Patient.user_id]",
        back_populates="user",
        uselist=False,
    )
    caregiver_patients: Mapped[List["Patient"]] = relationship(
        "Patient",
        foreign_keys="[Patient.caregiver_id]",
        back_populates="caregiver",
    )
    asha_patients: Mapped[List["Patient"]] = relationship(
        "Patient",
        foreign_keys="[Patient.asha_id]",
        back_populates="asha",
    )


class Patient(Base):
    """Patient demographic and profile model."""
    __tablename__ = "patients"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)  # e.g., "P101"
    user_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    gender: Mapped[str] = mapped_column(String(50), nullable=False)
    primary_language: Mapped[str] = mapped_column(String(50), nullable=False, default="en")
    caregiver_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    asha_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )

    # User & Provider relationships
    user: Mapped[Optional["User"]] = relationship(
        "User", foreign_keys=[user_id], back_populates="patient_profile"
    )
    caregiver: Mapped[Optional["User"]] = relationship(
        "User", foreign_keys=[caregiver_id], back_populates="caregiver_patients"
    )
    asha: Mapped[Optional["User"]] = relationship(
        "User", foreign_keys=[asha_id], back_populates="asha_patients"
    )

    # Clinical and assessment relationships
    baselines: Mapped[List["Baseline"]] = relationship(
        "Baseline", back_populates="patient", cascade="all, delete-orphan"
    )
    sessions: Mapped[List["Session"]] = relationship(
        "Session", back_populates="patient", cascade="all, delete-orphan"
    )
    game_attempts: Mapped[List["GameAttempt"]] = relationship(
        "GameAttempt", back_populates="patient", cascade="all, delete-orphan"
    )
    daily_checkins: Mapped[List["DailyCheckin"]] = relationship(
        "DailyCheckin", back_populates="patient", cascade="all, delete-orphan"
    )
    reminders: Mapped[List["Reminder"]] = relationship(
        "Reminder", back_populates="patient", cascade="all, delete-orphan"
    )
    memory_items: Mapped[List["MemoryItem"]] = relationship(
        "MemoryItem", back_populates="patient", cascade="all, delete-orphan"
    )
    voice_interactions: Mapped[List["VoiceInteraction"]] = relationship(
        "VoiceInteraction", back_populates="patient", cascade="all, delete-orphan"
    )
    alerts: Mapped[List["Alert"]] = relationship(
        "Alert", back_populates="patient", cascade="all, delete-orphan"
    )
    consents: Mapped[List["Consent"]] = relationship(
        "Consent", back_populates="patient", cascade="all, delete-orphan"
    )


class Baseline(Base):
    """Clinical cognitive baseline assessment score and notes."""
    __tablename__ = "baselines"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    baseline_score: Mapped[int] = mapped_column(Integer, nullable=False)
    assessed_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    patient: Mapped["Patient"] = relationship("Patient", back_populates="baselines")


class Session(Base):
    """Therapy, cognitive training, or evaluation session tracking."""
    __tablename__ = "sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    session_type: Mapped[str] = mapped_column(String(100), nullable=False)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )
    completed_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    status: Mapped[str] = mapped_column(String(50), nullable=False, default="in_progress")

    patient: Mapped["Patient"] = relationship("Patient", back_populates="sessions")


class GameAttempt(Base):
    """Individual cognitive game performance record, including offline sync timestamps."""
    __tablename__ = "game_attempts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    game_type: Mapped[str] = mapped_column(String(100), nullable=False, index=True)  # e.g., "memory_pairs"
    score: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    mistakes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    reaction_time_ms: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    difficulty: Mapped[str] = mapped_column(String(50), nullable=False, default="normal")
    played_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )
    client_timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
        index=True,
    )

    patient: Mapped["Patient"] = relationship("Patient", back_populates="game_attempts")


class DailyCheckin(Base):
    """Daily patient well-being check-in, mood, and sleep log."""
    __tablename__ = "daily_checkins"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    mood: Mapped[str] = mapped_column(String(50), nullable=False)
    sleep_hours: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    symptoms: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )
    client_timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
        index=True,
    )

    patient: Mapped["Patient"] = relationship("Patient", back_populates="daily_checkins")


class Reminder(Base):
    """Medication, task, or appointment reminder for patient care."""
    __tablename__ = "reminders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    reminder_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    frequency: Mapped[str] = mapped_column(String(50), nullable=False, default="daily")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )

    patient: Mapped["Patient"] = relationship("Patient", back_populates="reminders")


class MemoryItem(Base):
    """Reminiscence therapy media (photo, voice note, video) and description."""
    __tablename__ = "memory_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    media_url: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    category: Mapped[str] = mapped_column(String(100), nullable=False, default="general")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )

    patient: Mapped["Patient"] = relationship("Patient", back_populates="memory_items")


class VoiceInteraction(Base):
    """Patient audio log, speech recognition transcript, and intent classification."""
    __tablename__ = "voice_interactions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    audio_filepath: Mapped[str] = mapped_column(String(500), nullable=False)
    transcript: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    intent: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )

    patient: Mapped["Patient"] = relationship("Patient", back_populates="voice_interactions")


class Alert(Base):
    """Clinical or caregiver alerts triggered by anomaly detection or early warnings."""
    __tablename__ = "alerts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    severity: Mapped[str] = mapped_column(String(50), nullable=False, default="medium")
    message: Mapped[str] = mapped_column(Text, nullable=False)
    resolved: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )

    patient: Mapped["Patient"] = relationship("Patient", back_populates="alerts")


class Consent(Base):
    """Data processing, clinical study, and privacy consent records."""
    __tablename__ = "consents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    patient_id: Mapped[str] = mapped_column(
        String(50), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    consent_type: Mapped[str] = mapped_column(String(100), nullable=False)
    agreed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )
    is_revoked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    patient: Mapped["Patient"] = relationship("Patient", back_populates="consents")
