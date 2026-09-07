# SMRITI - Day 0 Baseline Calibration Engine
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Dict, Any

class BaselineEngine:
    """
    Establishes deterministic reference baseline vectors for patients on Day 0 onboarding.
    Future performance is compared against this reference baseline.
    """

    @staticmethod
    def calculate_day_zero_baseline(onboarding_game_attempts: List[Dict[str, Any]]) -> Dict[str, float]:
        """
        Calculates baseline vectors from initial calibration activities:
          - Photo Memory (reference memory baseline)
          - Simon Says / Odd One Out (reference attention baseline)
          - Object Naming / Voice prompt (reference response baseline)
        """
        memory_scores = [
            float(g.get("score", 70.0)) for g in onboarding_game_attempts 
            if g.get("game_type") in ("photo_memory", "memory_pairs")
        ]
        attention_scores = [
            float(g.get("score", 70.0)) for g in onboarding_game_attempts 
            if g.get("game_type") in ("simon_says", "odd_one_out")
        ]
        response_scores = [
            float(g.get("score", 70.0)) for g in onboarding_game_attempts 
            if g.get("game_type") in ("object_naming", "voice_calibration")
        ]

        baseline_memory = round(sum(memory_scores) / len(memory_scores), 2) if memory_scores else 72.0
        baseline_attention = round(sum(attention_scores) / len(attention_scores), 2) if attention_scores else 70.0
        baseline_engagement = 80.0 if onboarding_game_attempts else 70.0

        return {
            "baseline_memory": baseline_memory,
            "baseline_attention": baseline_attention,
            "baseline_engagement": baseline_engagement,
        }
