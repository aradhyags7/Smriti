"""
Comprehensive pytest suite for SMRITI Pydantic v2 schemas.

Covers:
  - Valid instantiation and JSON serialisation
  - Boundary / constraint validation errors
  - Composite models (SyncPayloadRequest with nested lists)
  - Enum value validation
"""

import sys
from datetime import datetime

import pytest
from pydantic import ValidationError

sys.path.insert(0, ".")

from app.schemas import (
    AlertAcknowledge,
    AlertCreate,
    AlertSeverity,
    AlertType,
    AshaPatientSummary,
    DailyCheckinCreate,
    DailyCheckinResponse,
    DailySessionComplete,
    DailySessionStart,
    GameAttemptCreate,
    GameAttemptResponse,
    GameDifficulty,
    GameType,
    MemoryItemType,
    OTPRequest,
    OTPVerifyRequest,
    PatientCreate,
    ReminderCreate,
    ReminderFrequency,
    ReminderType,
    ReminiscenceItemCreate,
    SessionStatus,
    SyncEntityResult,
    SyncEntityStatus,
    SyncPayloadRequest,
    SyncPayloadResponse,
    TokenResponse,
    TriagePriority,
    UserLoginRequest,
    UserRole,
    UserSignupRequest,
)


# ─── Fixtures ─────────────────────────────────────────────────────────────

@pytest.fixture
def valid_game_attempt_data():
    return {
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


@pytest.fixture
def valid_checkin_data():
    return {
        "client_checkin_id": "c1d2e3f4-a5b6-7890-cdef-1234567890ab",
        "patient_id": "p-uuid-001",
        "mood_score": 4,
        "sleep_hours": 7.5,
        "symptoms_noted": "Mild headache in the morning",
        "checkin_time": "2026-09-07T08:00:00Z",
    }


@pytest.fixture
def valid_signup_data():
    return {
        "full_name": "Tanishka Sawant",
        "phone_number": "+919876543210",
        "role": "caregiver",
        "pin": "1234",
        "email": "tanishka@example.com",
        "preferred_language": "en",
    }


# ═══════════════════════════════════════════════════════════════════════════
# 1. VALID INSTANTIATION & SERIALISATION
# ═══════════════════════════════════════════════════════════════════════════


class TestGameAttemptCreateValid:
    """Valid GameAttemptCreate instantiation and serialisation."""

    def test_create_with_all_fields(self, valid_game_attempt_data):
        g = GameAttemptCreate(**valid_game_attempt_data)
        assert g.score == 78
        assert g.game_type == GameType.MEMORY_PAIRS
        assert g.difficulty == GameDifficulty.MEDIUM
        assert g.mistakes == 3
        assert g.reaction_time_ms == 1250
        assert g.completion_time_seconds == 45
        assert g.client_attempt_id == "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

    def test_create_without_session_id(self, valid_game_attempt_data):
        valid_game_attempt_data.pop("session_id")
        g = GameAttemptCreate(**valid_game_attempt_data)
        assert g.session_id is None

    def test_serialisation_roundtrip(self, valid_game_attempt_data):
        g = GameAttemptCreate(**valid_game_attempt_data)
        json_str = g.model_dump_json()
        assert "memory_pairs" in json_str
        assert "client_attempt_id" in json_str

    def test_model_dump_contains_all_keys(self, valid_game_attempt_data):
        g = GameAttemptCreate(**valid_game_attempt_data)
        d = g.model_dump()
        expected_keys = {
            "client_attempt_id", "patient_id", "session_id",
            "game_type", "difficulty", "score", "mistakes",
            "reaction_time_ms", "completion_time_seconds", "completed_at",
        }
        assert expected_keys == set(d.keys())

    def test_boundary_score_zero(self, valid_game_attempt_data):
        valid_game_attempt_data["score"] = 0
        g = GameAttemptCreate(**valid_game_attempt_data)
        assert g.score == 0

    def test_boundary_score_hundred(self, valid_game_attempt_data):
        valid_game_attempt_data["score"] = 100
        g = GameAttemptCreate(**valid_game_attempt_data)
        assert g.score == 100

    def test_zero_mistakes(self, valid_game_attempt_data):
        valid_game_attempt_data["mistakes"] = 0
        g = GameAttemptCreate(**valid_game_attempt_data)
        assert g.mistakes == 0

    def test_zero_reaction_time(self, valid_game_attempt_data):
        valid_game_attempt_data["reaction_time_ms"] = 0
        g = GameAttemptCreate(**valid_game_attempt_data)
        assert g.reaction_time_ms == 0


class TestDailyCheckinCreateValid:
    """Valid DailyCheckinCreate instantiation and serialisation."""

    def test_create_with_all_fields(self, valid_checkin_data):
        c = DailyCheckinCreate(**valid_checkin_data)
        assert c.mood_score == 4
        assert c.sleep_hours == 7.5
        assert c.symptoms_noted == "Mild headache in the morning"

    def test_create_without_optional_fields(self):
        c = DailyCheckinCreate(
            client_checkin_id="uuid-min",
            patient_id="p-001",
            mood_score=3,
            sleep_hours=6.0,
            checkin_time="2026-09-07T08:00:00Z",
        )
        assert c.symptoms_noted is None
        assert c.appetite_rating is None
        assert c.energy_level is None

    def test_serialisation_roundtrip(self, valid_checkin_data):
        c = DailyCheckinCreate(**valid_checkin_data)
        d = c.model_dump()
        assert d["mood_score"] == 4
        assert d["sleep_hours"] == 7.5

    def test_boundary_mood_min(self):
        c = DailyCheckinCreate(
            client_checkin_id="uuid-1",
            patient_id="p-001",
            mood_score=1,
            sleep_hours=0.0,
            checkin_time="2026-09-07T08:00:00Z",
        )
        assert c.mood_score == 1
        assert c.sleep_hours == 0.0

    def test_boundary_mood_max(self):
        c = DailyCheckinCreate(
            client_checkin_id="uuid-5",
            patient_id="p-001",
            mood_score=5,
            sleep_hours=24.0,
            checkin_time="2026-09-07T08:00:00Z",
        )
        assert c.mood_score == 5
        assert c.sleep_hours == 24.0


class TestUserSignupRequestValid:
    """Valid UserSignupRequest instantiation and serialisation."""

    def test_create_with_all_fields(self, valid_signup_data):
        u = UserSignupRequest(**valid_signup_data)
        assert u.full_name == "Tanishka Sawant"
        assert u.role == UserRole.CAREGIVER
        assert u.phone_number == "+919876543210"

    def test_create_without_optional_email(self, valid_signup_data):
        valid_signup_data.pop("email")
        u = UserSignupRequest(**valid_signup_data)
        assert u.email is None

    def test_all_roles(self, valid_signup_data):
        for role in ["patient", "caregiver", "asha"]:
            valid_signup_data["role"] = role
            u = UserSignupRequest(**valid_signup_data)
            assert u.role.value == role

    def test_serialisation_snake_case(self, valid_signup_data):
        u = UserSignupRequest(**valid_signup_data)
        d = u.model_dump()
        assert "full_name" in d
        assert "phone_number" in d
        assert "preferred_language" in d


class TestSyncPayloadRequestValid:
    """Valid SyncPayloadRequest with nested game and checkin lists."""

    def test_create_with_pending_games_and_checkins(
        self, valid_game_attempt_data, valid_checkin_data
    ):
        game = GameAttemptCreate(**valid_game_attempt_data)
        checkin = DailyCheckinCreate(**valid_checkin_data)

        sync = SyncPayloadRequest(
            patient_id="p-uuid-001",
            client_sync_time="2026-09-07T11:00:00Z",
            pending_games=[game],
            pending_checkins=[checkin],
        )
        assert len(sync.pending_games) == 1
        assert len(sync.pending_checkins) == 1
        assert sync.pending_games[0].score == 78
        assert sync.pending_checkins[0].mood_score == 4

    def test_create_with_multiple_games(self, valid_game_attempt_data):
        games = []
        for i in range(5):
            data = valid_game_attempt_data.copy()
            data["client_attempt_id"] = f"uuid-{i}"
            data["score"] = 60 + i * 10
            games.append(GameAttemptCreate(**data))

        sync = SyncPayloadRequest(
            patient_id="p-uuid-001",
            client_sync_time="2026-09-07T11:00:00Z",
            pending_games=games,
            pending_checkins=[],
        )
        assert len(sync.pending_games) == 5
        assert sync.pending_games[4].score == 100

    def test_create_with_empty_lists(self):
        sync = SyncPayloadRequest(
            patient_id="p-uuid-001",
            client_sync_time="2026-09-07T11:00:00Z",
            pending_games=[],
            pending_checkins=[],
        )
        assert len(sync.pending_games) == 0
        assert len(sync.pending_checkins) == 0

    def test_serialisation_preserves_nested_data(
        self, valid_game_attempt_data, valid_checkin_data
    ):
        game = GameAttemptCreate(**valid_game_attempt_data)
        checkin = DailyCheckinCreate(**valid_checkin_data)

        sync = SyncPayloadRequest(
            patient_id="p-uuid-001",
            client_sync_time="2026-09-07T11:00:00Z",
            pending_games=[game],
            pending_checkins=[checkin],
        )
        d = sync.model_dump()
        assert d["pending_games"][0]["game_type"] == "memory_pairs"
        assert d["pending_checkins"][0]["mood_score"] == 4


# ═══════════════════════════════════════════════════════════════════════════
# 2. BOUNDARY VALIDATION ERRORS
# ═══════════════════════════════════════════════════════════════════════════


class TestGameAttemptCreateValidationErrors:
    """GameAttemptCreate must reject invalid field values."""

    def test_score_above_100(self, valid_game_attempt_data):
        valid_game_attempt_data["score"] = 101
        with pytest.raises(ValidationError) as exc_info:
            GameAttemptCreate(**valid_game_attempt_data)
        assert "score" in str(exc_info.value)

    def test_score_below_zero(self, valid_game_attempt_data):
        valid_game_attempt_data["score"] = -1
        with pytest.raises(ValidationError):
            GameAttemptCreate(**valid_game_attempt_data)

    def test_negative_mistakes(self, valid_game_attempt_data):
        valid_game_attempt_data["mistakes"] = -1
        with pytest.raises(ValidationError) as exc_info:
            GameAttemptCreate(**valid_game_attempt_data)
        assert "mistakes" in str(exc_info.value)

    def test_negative_reaction_time(self, valid_game_attempt_data):
        valid_game_attempt_data["reaction_time_ms"] = -100
        with pytest.raises(ValidationError) as exc_info:
            GameAttemptCreate(**valid_game_attempt_data)
        assert "reaction_time_ms" in str(exc_info.value)

    def test_negative_completion_time(self, valid_game_attempt_data):
        valid_game_attempt_data["completion_time_seconds"] = -1
        with pytest.raises(ValidationError):
            GameAttemptCreate(**valid_game_attempt_data)

    def test_invalid_game_type(self, valid_game_attempt_data):
        valid_game_attempt_data["game_type"] = "invalid_game"
        with pytest.raises(ValidationError):
            GameAttemptCreate(**valid_game_attempt_data)

    def test_invalid_difficulty(self, valid_game_attempt_data):
        valid_game_attempt_data["difficulty"] = "impossible"
        with pytest.raises(ValidationError):
            GameAttemptCreate(**valid_game_attempt_data)

    def test_missing_required_field(self, valid_game_attempt_data):
        valid_game_attempt_data.pop("score")
        with pytest.raises(ValidationError):
            GameAttemptCreate(**valid_game_attempt_data)


class TestDailyCheckinCreateValidationErrors:
    """DailyCheckinCreate must reject invalid field values."""

    def test_mood_score_zero(self, valid_checkin_data):
        valid_checkin_data["mood_score"] = 0
        with pytest.raises(ValidationError) as exc_info:
            DailyCheckinCreate(**valid_checkin_data)
        assert "mood_score" in str(exc_info.value)

    def test_mood_score_six(self, valid_checkin_data):
        valid_checkin_data["mood_score"] = 6
        with pytest.raises(ValidationError):
            DailyCheckinCreate(**valid_checkin_data)

    def test_negative_sleep_hours(self, valid_checkin_data):
        valid_checkin_data["sleep_hours"] = -1.0
        with pytest.raises(ValidationError):
            DailyCheckinCreate(**valid_checkin_data)

    def test_sleep_hours_above_24(self, valid_checkin_data):
        valid_checkin_data["sleep_hours"] = 25.0
        with pytest.raises(ValidationError):
            DailyCheckinCreate(**valid_checkin_data)

    def test_missing_required_patient_id(self, valid_checkin_data):
        valid_checkin_data.pop("patient_id")
        with pytest.raises(ValidationError):
            DailyCheckinCreate(**valid_checkin_data)


class TestUserSignupRequestValidationErrors:
    """UserSignupRequest must reject invalid field values."""

    def test_invalid_phone_format(self, valid_signup_data):
        valid_signup_data["phone_number"] = "not-a-phone"
        with pytest.raises(ValidationError):
            UserSignupRequest(**valid_signup_data)

    def test_pin_too_short(self, valid_signup_data):
        valid_signup_data["pin"] = "12"
        with pytest.raises(ValidationError):
            UserSignupRequest(**valid_signup_data)

    def test_pin_too_long(self, valid_signup_data):
        valid_signup_data["pin"] = "1234567"
        with pytest.raises(ValidationError):
            UserSignupRequest(**valid_signup_data)

    def test_pin_non_numeric(self, valid_signup_data):
        valid_signup_data["pin"] = "abcd"
        with pytest.raises(ValidationError):
            UserSignupRequest(**valid_signup_data)

    def test_invalid_role(self, valid_signup_data):
        valid_signup_data["role"] = "admin"
        with pytest.raises(ValidationError):
            UserSignupRequest(**valid_signup_data)

    def test_name_too_short(self, valid_signup_data):
        valid_signup_data["full_name"] = "A"
        with pytest.raises(ValidationError):
            UserSignupRequest(**valid_signup_data)

    def test_invalid_email_format(self, valid_signup_data):
        valid_signup_data["email"] = "not-an-email"
        with pytest.raises(ValidationError):
            UserSignupRequest(**valid_signup_data)


# ═══════════════════════════════════════════════════════════════════════════
# 3. ENUM VALUE TESTS
# ═══════════════════════════════════════════════════════════════════════════


class TestEnumValues:
    """Verify enum members match the API contract."""

    def test_user_role_values(self):
        assert set(r.value for r in UserRole) == {"patient", "caregiver", "asha"}

    def test_game_type_values(self):
        assert set(g.value for g in GameType) == {
            "memory_pairs", "odd_one_out", "simon_says", "object_naming"
        }

    def test_game_difficulty_values(self):
        assert set(d.value for d in GameDifficulty) == {"easy", "medium", "hard"}

    def test_alert_severity_values(self):
        assert set(s.value for s in AlertSeverity) == {
            "low", "medium", "high", "critical"
        }

    def test_triage_priority_values(self):
        assert set(t.value for t in TriagePriority) == {
            "stable", "monitor", "urgent"
        }

    def test_sync_entity_status_values(self):
        assert set(s.value for s in SyncEntityStatus) == {
            "SYNCED", "CONFLICT", "ERROR"
        }

    def test_memory_item_type_values(self):
        assert set(m.value for m in MemoryItemType) == {
            "photo", "audio", "text"
        }

    def test_reminder_frequency_values(self):
        assert set(f.value for f in ReminderFrequency) == {
            "once", "daily", "weekly", "custom"
        }

    def test_reminder_type_values(self):
        assert set(t.value for t in ReminderType) == {
            "medication", "exercise", "appointment",
            "game_session", "hydration", "custom"
        }

    def test_session_status_values(self):
        assert set(s.value for s in SessionStatus) == {
            "in_progress", "completed", "abandoned"
        }

    def test_alert_type_values(self):
        assert set(t.value for t in AlertType) == {
            "cognitive_decline", "missed_session", "mood_drop",
            "medication_missed", "abnormal_sleep", "caregiver_burnout", "system"
        }


# ═══════════════════════════════════════════════════════════════════════════
# 4. ALL GAME TYPES × DIFFICULTIES MATRIX
# ═══════════════════════════════════════════════════════════════════════════


class TestGameTypeDifficultyMatrix:
    """Every game_type × difficulty combination must be valid."""

    @pytest.mark.parametrize("game_type", ["memory_pairs", "odd_one_out", "simon_says", "object_naming"])
    @pytest.mark.parametrize("difficulty", ["easy", "medium", "hard"])
    def test_all_combinations(self, valid_game_attempt_data, game_type, difficulty):
        valid_game_attempt_data["game_type"] = game_type
        valid_game_attempt_data["difficulty"] = difficulty
        g = GameAttemptCreate(**valid_game_attempt_data)
        assert g.game_type.value == game_type
        assert g.difficulty.value == difficulty
