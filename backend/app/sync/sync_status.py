# SMRITI - Sync Status Constants & ACK Model
# Owner: Aradhya (AI + Database + Sync)

from enum import Enum
from typing import List, Any, Optional
from pydantic import BaseModel

class SyncStatus(str, Enum):
    PENDING = "PENDING"
    SYNCING = "SYNCING"
    SYNCED = "SYNCED"
    FAILED = "FAILED"

class SyncAckResponse(BaseModel):
    status: str
    synced_count: int
    synced_event_ids: List[str]
    synced_local_ids: List[Any]
    message: str
