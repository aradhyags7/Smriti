"""
Offline sync schemas for the SMRITI platform.

Implements the batch sync protocol used by the Flutter app to push
locally-queued game attempts and daily check-ins to the backend.
See `.agent_memory.md` §3 (Offline-First Synchronization).
"""

from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

from .checkin import DailyCheckinCreate
from .game import GameAttemptCreate


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class SyncEntityStatus(str, Enum):
    """Status of an individual entity within a sync response."""
    SYNCED = "SYNCED"
    CONFLICT = "CONFLICT"
    ERROR = "ERROR"


# ---------------------------------------------------------------------------
# Request
# ---------------------------------------------------------------------------

class SyncPayloadRequest(BaseModel):
    """
    Batch sync request sent by the Flutter app.

    The mobile client collects all PENDING game attempts and check-ins
    from local SQLite and submits them in a single HTTP call to
    POST /api/v1/sync/push.
    """
    patient_id: str = Field(
        ...,
        description="UUID of the patient whose data is being synced.",
    )
    client_sync_time: datetime = Field(
        ...,
        description="Client-side timestamp when the sync was initiated.",
    )
    pending_games: List[GameAttemptCreate] = Field(
        default_factory=list,
        description="List of game attempts queued locally with status PENDING.",
    )
    pending_checkins: List[DailyCheckinCreate] = Field(
        default_factory=list,
        description="List of daily check-ins queued locally with status PENDING.",
    )

    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "patient_id": "p-uuid-001",
                "client_sync_time": "2026-09-07T11:00:00Z",
                "pending_games": [
                    {
                        "client_attempt_id": "a1b2c3d4-0001",
                        "patient_id": "p-uuid-001",
                        "session_id": "s-uuid-001",
                        "game_type": "memory_pairs",
                        "difficulty": "easy",
                        "score": 85,
                        "mistakes": 2,
                        "reaction_time_ms": 1100,
                        "completion_time_seconds": 38,
                        "completed_at": "2026-09-07T10:30:00Z",
                    }
                ],
                "pending_checkins": [
                    {
                        "client_checkin_id": "c1d2e3f4-0001",
                        "patient_id": "p-uuid-001",
                        "mood_score": 4,
                        "sleep_hours": 7.0,
                        "symptoms_noted": None,
                        "checkin_time": "2026-09-07T08:00:00Z",
                    }
                ],
            }
        },
    )


# ---------------------------------------------------------------------------
# Per-Entity Result
# ---------------------------------------------------------------------------

class SyncEntityResult(BaseModel):
    """Status of a single entity after server-side processing."""
    client_id: str = Field(
        ...,
        description="The client-generated UUID (client_attempt_id or client_checkin_id).",
    )
    server_id: str = Field(
        ...,
        description="Server-assigned UUID for the persisted record.",
    )
    status: SyncEntityStatus = Field(
        ...,
        description="Result status: SYNCED, CONFLICT, or ERROR.",
    )
    error_message: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Human-readable error detail (only if status is ERROR).",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

class SyncPayloadResponse(BaseModel):
    """
    Response returned after processing a batch sync push.

    Includes per-entity results so the client can mark each record
    as SYNCED in local SQLite or retry on ERROR.
    """
    patient_id: str = Field(..., description="Patient UUID.")
    server_sync_time: datetime = Field(
        ...,
        description="Server timestamp when sync was processed.",
    )
    games_synced: int = Field(
        ...,
        ge=0,
        description="Count of game attempts successfully synced.",
    )
    checkins_synced: int = Field(
        ...,
        ge=0,
        description="Count of check-ins successfully synced.",
    )
    game_results: List[SyncEntityResult] = Field(
        default_factory=list,
        description="Per-entity results for game attempts.",
    )
    checkin_results: List[SyncEntityResult] = Field(
        default_factory=list,
        description="Per-entity results for check-ins.",
    )
    has_errors: bool = Field(
        default=False,
        description="True if any entity failed to sync.",
    )

    model_config = ConfigDict(from_attributes=True)
