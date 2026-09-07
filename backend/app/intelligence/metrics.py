# SMRITI - Cognitive Domain Metric Calculators
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Dict, Any

def calculate_memory_metric(game_attempts: List[Dict[str, Any]], default_baseline: float = 70.0) -> float:
    """
    Computes a normalized Memory Domain Score (0-100) based on memory-oriented game attempts.
    Evaluates:
      - Raw accuracy percentage (weight: 0.60)
      - Mistake deduction (weight: 0.25)
      - Reaction time normalization (weight: 0.15)
    """
    memory_attempts = [
        g for g in game_attempts 
        if g.get("game_type") in ("memory_pairs", "photo_memory", "reminiscence_recall")
    ]
    if not memory_attempts:
        return default_baseline

    total_scores = []
    for g in memory_attempts:
        raw_score = float(g.get("score", 70.0))
        mistakes = int(g.get("mistakes", 0))
        reaction_ms = float(g.get("reaction_time_ms", 1500.0))

        # Mistake penalty: up to 25 pts deducted for excessive errors
        mistake_score = max(0.0, 100.0 - (mistakes * 10.0))

        # Speed score: optimal under 1200ms, decays down to 3000ms
        speed_score = max(0.0, min(100.0, (3000.0 - reaction_ms) / 18.0))

        attempt_composite = (0.60 * raw_score) + (0.25 * mistake_score) + (0.15 * speed_score)
        total_scores.append(attempt_composite)

    return round(sum(total_scores) / len(total_scores), 2)


def calculate_attention_metric(game_attempts: List[Dict[str, Any]], default_baseline: float = 70.0) -> float:
    """
    Computes a normalized Attention & Executive Function Score (0-100).
    Evaluates speed, accuracy, and task-switching consistency on odd-one-out and simon-says.
    """
    attention_attempts = [
        g for g in game_attempts 
        if g.get("game_type") in ("odd_one_out", "simon_says", "object_naming")
    ]
    if not attention_attempts:
        return default_baseline

    total_scores = []
    for g in attention_attempts:
        raw_score = float(g.get("score", 70.0))
        reaction_ms = float(g.get("reaction_time_ms", 1200.0))

        # Speed score for rapid response tasks
        speed_score = max(0.0, min(100.0, (2500.0 - reaction_ms) / 15.0))
        composite = (0.75 * raw_score) + (0.25 * speed_score)
        total_scores.append(composite)

    return round(sum(total_scores) / len(total_scores), 2)


def calculate_engagement_metric(
    sessions: List[Dict[str, Any]], 
    checkins: List[Dict[str, Any]], 
    reminders: List[Dict[str, Any]],
    expected_days: int = 7
) -> float:
    """
    Computes a normalized Engagement Score (0-100) based on:
      - Daily check-in participation rate (weight: 0.40)
      - CST session completion frequency (weight: 0.40)
      - Routine & reminder adherence (weight: 0.20)
    """
    # Check-in adherence
    unique_checkin_days = len({str(c.get("timestamp", ""))[:10] for c in checkins if c.get("timestamp")})
    checkin_score = min(100.0, (unique_checkin_days / max(1, expected_days)) * 100.0)

    # Session completion adherence
    completed_sessions = [s for s in sessions if s.get("completed_at")]
    session_score = min(100.0, (len(completed_sessions) / max(1, expected_days)) * 100.0)

    # Reminder adherence
    if reminders:
        acknowledged = [r for r in reminders if r.get("is_acknowledged")]
        reminder_score = (len(acknowledged) / len(reminders)) * 100.0
    else:
        reminder_score = 80.0

    engagement = (0.40 * checkin_score) + (0.40 * session_score) + (0.20 * reminder_score)
    return round(max(10.0, min(100.0, engagement)), 2)
