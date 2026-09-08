# SMRITI - Sync Conflict Resolver
# Owner: Aradhya (AI + Database + Sync)

from typing import Dict, Any

class SyncConflictResolver:
    """
    Handles event de-duplication and timestamp-based conflict resolution.
    """

    @staticmethod
    def should_apply_update(existing_timestamp: str, incoming_timestamp: str) -> bool:
        """
        Determines if incoming payload is newer than existing record (Last-Write-Wins).
        """
        if not existing_timestamp:
            return True
        if not incoming_timestamp:
            return False
        return incoming_timestamp >= existing_timestamp

    @classmethod
    def should_overwrite(cls, existing_timestamp: str, incoming_timestamp: str) -> bool:
        return cls.should_apply_update(existing_timestamp, incoming_timestamp)
