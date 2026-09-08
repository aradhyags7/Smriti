# SMRITI - Sync Payload Validator
# Owner: Aradhya (AI + Database + Sync)

from typing import Dict, Any, Tuple, Optional

class SyncValidator:
    REQUIRED_EVENT_FIELDS = {"event_id", "event_type", "payload"}

    @classmethod
    def validate_payload(cls, data: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        if not isinstance(data, dict):
            return False, "Payload must be a JSON object"

        if not data.get("patient_id"):
            return False, "Missing required field: 'patient_id'"

        events = data.get("events")
        if not isinstance(events, list):
            return False, "Field 'events' must be a list of event objects"

        for idx, event in enumerate(events):
            if not isinstance(event, dict):
                return False, f"Event at index {idx} must be a JSON object"
            
            missing = cls.REQUIRED_EVENT_FIELDS - set(event.keys())
            if missing:
                return False, f"Event at index {idx} missing required fields: {missing}"

        return True, None
