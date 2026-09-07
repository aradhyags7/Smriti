"""
SMRITI Pydantic v2 Schema Package.

Re-exports every public schema for convenient imports:
    from backend.app.schemas import GameAttemptCreate, SyncPayloadRequest
"""

# ── Auth ──────────────────────────────────────────────────────────────────
from .auth import (
    ForgotPinRequest,
    OTPRequest,
    OTPVerifyRequest,
    TokenResponse,
    UserLoginRequest,
    UserRole,
    UserSignupRequest,
)

# ── User ──────────────────────────────────────────────────────────────────
from .user import (
    UserBase,
    UserResponse,
    UserUpdate,
)

# ── Patient ───────────────────────────────────────────────────────────────
from .patient import (
    BaselineAssessmentCreate,
    BaselineAssessmentResponse,
    EducationLevel,
    Gender,
    PatientCreate,
    PatientResponse,
    PatientUpdate,
)

# ── Session ───────────────────────────────────────────────────────────────
from .session import (
    DailySessionComplete,
    DailySessionResponse,
    DailySessionStart,
    SessionStatus,
)

# ── Game ──────────────────────────────────────────────────────────────────
from .game import (
    GameAttemptCreate,
    GameAttemptResponse,
    GameDifficulty,
    GameType,
)

# ── Check-in ──────────────────────────────────────────────────────────────
from .checkin import (
    DailyCheckinCreate,
    DailyCheckinResponse,
)

# ── Reminder ──────────────────────────────────────────────────────────────
from .reminder import (
    ReminderCreate,
    ReminderFrequency,
    ReminderResponse,
    ReminderStatus,
    ReminderType,
    ReminderUpdate,
)

# ── Memory / Reminiscence ─────────────────────────────────────────────────
from .memory import (
    MemoryItemType,
    ReminiscenceItemCreate,
    ReminiscenceItemResponse,
)

# ── Alert ─────────────────────────────────────────────────────────────────
from .alert import (
    AlertAcknowledge,
    AlertCreate,
    AlertResponse,
    AlertSeverity,
    AlertStatus,
    AlertType,
)

# ── Sync ──────────────────────────────────────────────────────────────────
from .sync import (
    SyncEntityResult,
    SyncEntityStatus,
    SyncPayloadRequest,
    SyncPayloadResponse,
)

# ── ASHA ──────────────────────────────────────────────────────────────────
from .asha import (
    AshaPatientSummary,
    AshaTriageResponse,
    ConsentStatus,
    TriagePriority,
)

# ── Cognitive ─────────────────────────────────────────────────────────────
from .cognitive import (
    CognitiveDomain,
    CognitiveDomainScore,
    CognitiveReport,
    GamePerformanceSummary,
    TrendDirection,
)

# ── Trend ─────────────────────────────────────────────────────────────────
from .trend import (
    PatientTrendResponse,
    TrendDataPoint,
    TrendSeries,
)

__all__ = [
    # Auth
    "UserRole",
    "UserSignupRequest",
    "UserLoginRequest",
    "TokenResponse",
    "OTPRequest",
    "OTPVerifyRequest",
    "ForgotPinRequest",
    # User
    "UserBase",
    "UserUpdate",
    "UserResponse",
    # Patient
    "Gender",
    "EducationLevel",
    "PatientCreate",
    "PatientUpdate",
    "PatientResponse",
    "BaselineAssessmentCreate",
    "BaselineAssessmentResponse",
    # Session
    "SessionStatus",
    "DailySessionStart",
    "DailySessionComplete",
    "DailySessionResponse",
    # Game
    "GameType",
    "GameDifficulty",
    "GameAttemptCreate",
    "GameAttemptResponse",
    # Check-in
    "DailyCheckinCreate",
    "DailyCheckinResponse",
    # Reminder
    "ReminderFrequency",
    "ReminderType",
    "ReminderStatus",
    "ReminderCreate",
    "ReminderUpdate",
    "ReminderResponse",
    # Memory
    "MemoryItemType",
    "ReminiscenceItemCreate",
    "ReminiscenceItemResponse",
    # Alert
    "AlertSeverity",
    "AlertType",
    "AlertStatus",
    "AlertCreate",
    "AlertAcknowledge",
    "AlertResponse",
    # Sync
    "SyncEntityStatus",
    "SyncEntityResult",
    "SyncPayloadRequest",
    "SyncPayloadResponse",
    # ASHA
    "ConsentStatus",
    "TriagePriority",
    "AshaPatientSummary",
    "AshaTriageResponse",
    # Cognitive
    "CognitiveDomain",
    "TrendDirection",
    "CognitiveDomainScore",
    "GamePerformanceSummary",
    "CognitiveReport",
    # Trend
    "TrendDataPoint",
    "TrendSeries",
    "PatientTrendResponse",
]
