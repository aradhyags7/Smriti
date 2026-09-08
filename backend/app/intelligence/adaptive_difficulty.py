# SMRITI - Adaptive Difficulty Engine
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Dict, Any

class AdaptiveDifficultyEngine:
    """
    Adjusts game difficulty dynamically based on patient's longitudinal performance.
    Avoids random difficulty changes to prevent cognitive fatigue and frustration.
    """

    LEVELS = ["EASY", "MEDIUM", "HARD"]

    @classmethod
    def calculate_next_difficulty(
        cls,
        recent_attempts: List[Dict[str, Any]],
        current_difficulty: str = "EASY"
    ) -> str:
        if not recent_attempts:
            return current_difficulty

        # Evaluate last 3 attempts for this game
        last_3 = recent_attempts[:3]
        avg_score = sum(float(a.get("score", 70.0)) for a in last_3) / len(last_3)
        avg_mistakes = sum(int(a.get("mistakes", 0)) for a in last_3) / len(last_3)

        curr_idx = cls.LEVELS.index(current_difficulty) if current_difficulty in cls.LEVELS else 0

        # High performance: increase difficulty if not at maximum
        if avg_score >= 85.0 and avg_mistakes <= 1 and curr_idx < len(cls.LEVELS) - 1:
            return cls.LEVELS[curr_idx + 1]

        # Low performance or excessive mistakes: reduce difficulty to prevent frustration
        elif (avg_score < 60.0 or avg_mistakes >= 4) and curr_idx > 0:
            return cls.LEVELS[curr_idx - 1]

        # Medium performance: maintain current difficulty
        return cls.LEVELS[curr_idx]
