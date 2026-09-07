"""SMRITI Pydantic Schemas Package.

Exports all request and response schemas for authentication, patients,
game attempts, and offline synchronization.
"""

from app.schemas.auth import TokenResponse, UserLogin, UserOut, UserRegister
from app.schemas.game import GameAttemptCreate, GameAttemptOut
from app.schemas.patient import PatientCreate, PatientOut
from app.schemas.sync import SyncBatchRequest, SyncBatchResponse

__all__ = [
    "UserRegister",
    "UserLogin",
    "TokenResponse",
    "UserOut",
    "PatientCreate",
    "PatientOut",
    "GameAttemptCreate",
    "GameAttemptOut",
    "SyncBatchRequest",
    "SyncBatchResponse",
]
