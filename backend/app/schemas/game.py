"""
Game schemas for the SMRITI platform.

Defines the four cognitive game types, difficulty levels, and the
GameAttemptCreate / GameAttemptResponse models.  Every attempt carries
the full metric set required by the AI engine (see .agent_memory.md §5).
"""

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class GameType(str, Enum):
    """Supported cognitive game catalogue."""
    MEMORY_PAIRS = "memory_pairs"
    ODD_ONE_OUT = "odd_one_out"
    SIMON_SAYS = "simon_says"
    OBJECT_NAMING = "object_naming"


class GameDifficulty(str, Enum):
    """Adaptive difficulty tiers set by the AI engine or caregiver."""
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


# ---------------------------------------------------------------------------
# Create (from Flutter client)
# ---------------------------------------------------------------------------

class GameAttemptCreate(BaseModel):
    """
    Single game attempt submitted by the mobile app.

    The client generates `client_attempt_id` locally (UUID v4) so the
    record can be stored in SQLite while offline and later synced.
    """
    client_attempt_id: str = Field(
        ...,
        description="Client-generated UUID v4 for idempotent sync.",
    )
    patient_id: str = Field(
        ...,
        description="UUID of the patient who played.",
    )
    session_id: Optional[str] = Field(
        default=None,
        description="Session UUID; null if played outside a formal session.",
    )
    game_type: GameType = Field(
        ...,
        description="Which cognitive game was played.",
    )
    difficulty: GameDifficulty = Field(
        ...,
        description="Difficulty level of this attempt.",
    )
    score: int = Field(
        ...,
        ge=0,
        le=100,
        description="Normalised score (0–100).",
    )
    mistakes: int = Field(
        ...,
        ge=0,
        description="Total errors / wrong taps during the attempt.",
    )
    reaction_time_ms: int = Field(
        ...,
        ge=0,
        description="Average reaction time in milliseconds.",
    )
    completion_time_seconds: int = Field(
        ...,
        ge=0,
        description="Wall-clock time to finish the game in seconds.",
    )
    completed_at: datetime = Field(
        ...,
        description="Client-side timestamp when the attempt finished.",
    )

    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "client_attempt_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "patient_id": "p-uuid-001",
                "session_id": "s-uuid-001",
                "game_type": "memory_pairs",
                "difficulty": "medium",
                "score": 78,
                "mistakes": 3,
                "reaction_time_ms": 1250,
                "completion_time_seconds": 45,
                "completed_at": "2026-09-07T10:30:00Z",
            }
        },
    )


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

class GameAttemptResponse(BaseModel):
    """Full game attempt record returned by the API."""
    id: str = Field(..., description="Server-assigned attempt UUID.")
    client_attempt_id: str = Field(..., description="Client-generated UUID.")
    patient_id: str = Field(..., description="Patient UUID.")
    session_id: Optional[str] = Field(default=None, description="Session UUID.")
    game_type: GameType = Field(..., description="Game type played.")
    difficulty: GameDifficulty = Field(..., description="Difficulty level.")
    score: int = Field(..., ge=0, le=100, description="Score (0–100).")
    mistakes: int = Field(..., ge=0, description="Mistake count.")
    reaction_time_ms: int = Field(..., ge=0, description="Reaction time (ms).")
    completion_time_seconds: int = Field(
        ..., ge=0, description="Completion time (s)."
    )
    completed_at: datetime = Field(..., description="Client completion timestamp.")
    sync_status: str = Field(
        default="SYNCED",
        description="Sync state: PENDING | SYNCED.",
    )
    created_at: datetime = Field(..., description="Server record creation timestamp.")

    model_config = ConfigDict(from_attributes=True)
