# SMRITI - Consent-Aware Early-Warning Engine
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime
from typing import Dict, Any, Optional, List

class EarlyWarningEngine:
    """
    Determines whether a meaningful deterioration pattern warrants an early-warning alert.
    Strictly applies:
      1. Non-clinical terminology (never outputs dementia diagnosis claims).
      2. Patient consent gating before routing alerts to rural ASHA workers.
    """

    MANDATORY_DISCLAIMER = (
        "The prototype cognitive-performance risk score is a decision-support and early-warning "
        "indicator, and is not a medical diagnosis. Consult a qualified medical practitioner."
    )

    @classmethod
    def generate_explanation(cls, trend_data: Dict[str, Any], risk_evaluation: Dict[str, Any]) -> str:
        risk_level = risk_evaluation.get("risk_level", "STABLE")
        delta_mem = trend_data.get("delta_memory_pct", 0.0)
        delta_att = trend_data.get("delta_attention_pct", 0.0)
        delta_eng = trend_data.get("delta_engagement_pct", 0.0)

        if risk_level == "STABLE":
            return (
                f"Cognitive performance remains stable. Memory trend changed by {delta_mem:+0.1f}% "
                f"and attention by {delta_att:+0.1f}% over the last 7 days."
            )

        reasons = []
        if delta_mem < -10.0:
            reasons.append(f"Memory performance decreased by {abs(delta_mem):0.1f}% over the last 7 days")
        elif delta_mem < 0.0:
            reasons.append(f"Mild memory score decrease of {abs(delta_mem):0.1f}%")

        if delta_att < -10.0:
            reasons.append(f"Attention and response speed decreased by {abs(delta_att):0.1f}%")

        if delta_eng < -15.0:
            reasons.append(f"Daily routine engagement dropped by {abs(delta_eng):0.1f}%")

        if not reasons:
            reasons.append("Multi-domain performance variability observed across weekly sessions")

        explanation_text = ". ".join(reasons) + "."

        if risk_level == "ATTENTION_REQUIRED":
            return f"{explanation_text} Recommendation: Caregiver review and routine clinical evaluation recommended."
        else:
            return f"{explanation_text} Recommendation: Continued monitoring over the next 7-day window."

    @classmethod
    def evaluate_and_generate_alert(
        cls,
        patient_id: str,
        patient_name: str,
        trend_data: Dict[str, Any],
        risk_evaluation: Dict[str, Any],
        consent_for_asha: bool,
    ) -> Optional[Dict[str, Any]]:
        risk_level = risk_evaluation.get("risk_level", "STABLE")
        risk_score = risk_evaluation.get("risk_score", 0.0)

        # Alerts are generated when risk exceeds STABLE threshold
        if risk_level == "STABLE":
            return None

        explanation = cls.generate_explanation(trend_data, risk_evaluation)

        # Consent Gate: Only dispatch to ASHA if explicit consent granted
        recipients: List[str] = ["caregiver"]
        if consent_for_asha:
            recipients.append("asha_worker")

        return {
            "patient_id": patient_id,
            "patient_name": patient_name,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "severity": "HIGH" if risk_level == "ATTENTION_REQUIRED" else "MEDIUM",
            "reason": explanation,
            "recipients": recipients,
            "consent_for_asha": consent_for_asha,
            "disclaimer": cls.MANDATORY_DISCLAIMER,
            "timestamp": datetime.utcnow().isoformat(),
        }
