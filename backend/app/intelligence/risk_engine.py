# SMRITI - Risk Engine
# Owner: Aradhya (AI + Database + Sync)

from typing import Dict, Any

class RiskEngine:
    """
    Computes composite score and early-warning risk classification.
    Adheres strictly to the project-defined weighting and non-clinical risk classification.
    """

    WEIGHT_MEMORY = 0.40
    WEIGHT_ATTENTION = 0.35
    WEIGHT_ENGAGEMENT = 0.25

    THRESHOLD_STABLE = 30.0
    THRESHOLD_MONITOR = 60.0

    @classmethod
    def calculate_composite_score(cls, memory: float, attention: float, engagement: float) -> float:
        composite = (
            (cls.WEIGHT_MEMORY * memory) +
            (cls.WEIGHT_ATTENTION * attention) +
            (cls.WEIGHT_ENGAGEMENT * engagement)
        )
        return round(max(0.0, min(100.0, composite)), 2)

    @classmethod
    def calculate_risk_score(cls, composite_score: float) -> float:
        risk = 100.0 - composite_score
        return round(max(0.0, min(100.0, risk)), 2)

    @classmethod
    def classify_risk(cls, risk_score: float) -> str:
        """
        Risk Classification:
          - Risk < 30      -> STABLE
          - Risk 30 to 60  -> MONITOR
          - Risk > 60      -> ATTENTION_REQUIRED
        """
        if risk_score < cls.THRESHOLD_STABLE:
            return "STABLE"
        elif risk_score <= cls.THRESHOLD_MONITOR:
            return "MONITOR"
        else:
            return "ATTENTION_REQUIRED"

    @classmethod
    def evaluate(cls, memory: float, attention: float, engagement: float) -> Dict[str, Any]:
        composite = cls.calculate_composite_score(memory, attention, engagement)
        risk = cls.calculate_risk_score(composite)
        classification = cls.classify_risk(risk)

        return {
            "memory_score": memory,
            "attention_score": attention,
            "engagement_score": engagement,
            "composite_score": composite,
            "risk_score": risk,
            "risk_level": classification,
        }
