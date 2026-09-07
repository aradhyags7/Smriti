# SMRITI - Intelligence Layer Unit Tests
# Owner: Aradhya (AI + Database + Sync)

import pytest
from datetime import datetime, timedelta
from backend.app.intelligence import (
    RiskEngine,
    AdaptiveDifficultyEngine,
    BaselineEngine,
    CognitiveTrendEngine,
    EarlyWarningEngine,
    calculate_memory_metric,
    calculate_attention_metric,
    calculate_engagement_metric,
)

def test_risk_engine_formula_and_classification():
    # 1. Formula verification
    # Memory: 80, Attention: 70, Engagement: 90
    # Composite = 0.40 * 80 + 0.35 * 70 + 0.25 * 90 = 32 + 24.5 + 22.5 = 79.0
    # Risk = 100 - 79.0 = 21.0
    res = RiskEngine.evaluate(memory=80.0, attention=70.0, engagement=90.0)
    assert res["composite_score"] == 79.0
    assert res["risk_score"] == 21.0
    assert res["risk_level"] == "STABLE"

    # 2. Risk 30 to 60 -> MONITOR
    # Memory: 50, Attention: 50, Engagement: 50
    # Composite = 50.0 -> Risk = 50.0
    res_monitor = RiskEngine.evaluate(memory=50.0, attention=50.0, engagement=50.0)
    assert res_monitor["risk_score"] == 50.0
    assert res_monitor["risk_level"] == "MONITOR"

    # Boundary: exactly 30.0 -> MONITOR
    assert RiskEngine.classify_risk(30.0) == "MONITOR"
    # Boundary: exactly 60.0 -> MONITOR
    assert RiskEngine.classify_risk(60.0) == "MONITOR"

    # 3. Risk > 60 -> ATTENTION_REQUIRED
    # Memory: 30, Attention: 30, Engagement: 30
    # Composite = 30.0 -> Risk = 70.0
    res_att = RiskEngine.evaluate(memory=30.0, attention=30.0, engagement=30.0)
    assert res_att["risk_score"] == 70.0
    assert res_att["risk_level"] == "ATTENTION_REQUIRED"

def test_adaptive_difficulty_engine():
    # 1. Progression: High score & low mistakes -> Increase difficulty
    high_perf = [
        {"score": 90.0, "mistakes": 0},
        {"score": 88.0, "mistakes": 1},
        {"score": 92.0, "mistakes": 0},
    ]
    next_diff = AdaptiveDifficultyEngine.calculate_next_difficulty(high_perf, current_difficulty="EASY")
    assert next_diff == "MEDIUM"

    next_diff_max = AdaptiveDifficultyEngine.calculate_next_difficulty(high_perf, current_difficulty="HARD")
    assert next_diff_max == "HARD"  # Cap at HARD

    # 2. Regression: Low score or excessive mistakes -> Lower difficulty
    low_perf = [
        {"score": 50.0, "mistakes": 4},
        {"score": 55.0, "mistakes": 5},
        {"score": 45.0, "mistakes": 4},
    ]
    next_diff_reg = AdaptiveDifficultyEngine.calculate_next_difficulty(low_perf, current_difficulty="HARD")
    assert next_diff_reg == "MEDIUM"

    next_diff_min = AdaptiveDifficultyEngine.calculate_next_difficulty(low_perf, current_difficulty="EASY")
    assert next_diff_min == "EASY"  # Cap at EASY

    # 3. Stable: Moderate performance -> Maintain difficulty
    mid_perf = [
        {"score": 75.0, "mistakes": 2},
        {"score": 70.0, "mistakes": 2},
        {"score": 72.0, "mistakes": 2},
    ]
    assert AdaptiveDifficultyEngine.calculate_next_difficulty(mid_perf, current_difficulty="MEDIUM") == "MEDIUM"

def test_baseline_engine():
    onboarding_attempts = [
        {"game_type": "photo_memory", "score": 80.0},
        {"game_type": "memory_pairs", "score": 84.0},
        {"game_type": "simon_says", "score": 75.0},
        {"game_type": "odd_one_out", "score": 77.0},
    ]
    baseline = BaselineEngine.calculate_day_zero_baseline(onboarding_attempts)
    assert baseline["baseline_memory"] == 82.0
    assert baseline["baseline_attention"] == 76.0
    assert baseline["baseline_engagement"] == 80.0

def test_cognitive_trend_engine():
    now = datetime(2026, 9, 7, 12, 0, 0)
    baseline = {"baseline_memory": 80.0, "baseline_attention": 75.0, "baseline_engagement": 80.0}

    # Generate 7 days of mock game attempts and checkins
    games = []
    checkins = []
    sessions = []
    reminders = []

    for i in range(7):
        day_date = (now - timedelta(days=6 - i)).strftime("%Y-%m-%d")
        games.append({
            "game_type": "memory_pairs",
            "score": 85.0,
            "mistakes": 1,
            "reaction_time_ms": 1200.0,
            "timestamp": f"{day_date}T10:00:00",
        })
        games.append({
            "game_type": "odd_one_out",
            "score": 80.0,
            "reaction_time_ms": 1100.0,
            "timestamp": f"{day_date}T10:15:00",
        })
        checkins.append({"timestamp": f"{day_date}T08:00:00", "mood": 4})
        sessions.append({"started_at": f"{day_date}T10:00:00", "completed_at": f"{day_date}T10:20:00"})
        reminders.append({"scheduled_time": f"{day_date}T09:00:00", "is_acknowledged": True})

    trend = CognitiveTrendEngine.compute_7day_trend(
        patient_id="pat_trend_test",
        game_attempts=games,
        checkins=checkins,
        sessions=sessions,
        reminders=reminders,
        baseline=baseline,
        end_date=now,
    )

    assert trend["window_days"] == 7
    assert len(trend["daily_points"]) == 7
    assert "rolling_memory" in trend
    assert "rolling_attention" in trend
    assert "rolling_engagement" in trend
    assert "delta_memory_pct" in trend
    assert "delta_attention_pct" in trend

def test_early_warning_engine_and_consent_gating():
    # 1. Non-clinical disclaimer verification
    disclaimer = EarlyWarningEngine.MANDATORY_DISCLAIMER
    assert "decision-support" in disclaimer
    assert "not a medical diagnosis" in disclaimer.lower()

    # 2. Stable patient -> No alert should be generated
    stable_trend = {"delta_memory_pct": 2.0, "delta_attention_pct": 1.5, "delta_engagement_pct": 0.0}
    stable_eval = {"risk_score": 18.0, "risk_level": "STABLE"}

    alert_stable = EarlyWarningEngine.evaluate_and_generate_alert(
        patient_id="pat_1",
        patient_name="Kamala Devi",
        trend_data=stable_trend,
        risk_evaluation=stable_eval,
        consent_for_asha=True,
    )
    assert alert_stable is None

    # 3. High Risk patient with ASHA Consent = TRUE
    deteriorating_trend = {
        "delta_memory_pct": -18.5,
        "delta_attention_pct": -12.0,
        "delta_engagement_pct": -20.0,
    }
    high_risk_eval = {"risk_score": 68.0, "risk_level": "ATTENTION_REQUIRED"}

    alert_with_consent = EarlyWarningEngine.evaluate_and_generate_alert(
        patient_id="pat_1",
        patient_name="Kamala Devi",
        trend_data=deteriorating_trend,
        risk_evaluation=high_risk_eval,
        consent_for_asha=True,
    )
    assert alert_with_consent is not None
    assert alert_with_consent["severity"] == "HIGH"
    assert "asha_worker" in alert_with_consent["recipients"]
    assert "caregiver" in alert_with_consent["recipients"]

    # Verify no diagnostic terms are used in rationale
    reason = alert_with_consent["reason"].lower()
    assert "dementia diagnosed" not in reason
    assert "dementia detected" not in reason
    assert "decreased by 18.5%" in reason or "18.5" in reason

    # 4. High Risk patient with ASHA Consent = FALSE
    # Must gate and exclude ASHA worker
    alert_without_consent = EarlyWarningEngine.evaluate_and_generate_alert(
        patient_id="pat_1",
        patient_name="Kamala Devi",
        trend_data=deteriorating_trend,
        risk_evaluation=high_risk_eval,
        consent_for_asha=False,
    )
    assert alert_without_consent is not None
    assert "asha_worker" not in alert_without_consent["recipients"]
    assert alert_without_consent["recipients"] == ["caregiver"]
    assert alert_without_consent["consent_for_asha"] is False
