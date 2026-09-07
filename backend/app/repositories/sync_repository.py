# SMRITI - Sync Repository (De-duplication & Idempotency)
# Owner: Aradhya (AI + Database + Sync)

import json
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from backend.app.models.sync_record import SyncRecord

class SyncRepository:
    def __init__(self, db: Session):
        self.db = db

    def is_event_processed(self, event_id: str) -> bool:
        """Checks if an event_id was already received and processed, preventing duplicate processing."""
        return self.db.query(SyncRecord).filter(SyncRecord.event_id == event_id).first() is not None

    def record_sync_event(
        self,
        event_id: str,
        patient_id: str,
        event_type: str,
        local_id: Optional[int],
        payload: Dict[str, Any],
        sync_status: str = "SYNCED",
    ) -> SyncRecord:
        record = SyncRecord(
            id=f"SR-{event_id[:8]}",
            event_id=event_id,
            patient_id=patient_id,
            event_type=event_type,
            local_id=local_id,
            payload_json=json.dumps(payload),
            sync_status=sync_status,
            created_at=payload.get("timestamp") or payload.get("created_at") or "",
        )
        self.db.add(record)
        self.db.commit()
        return record
