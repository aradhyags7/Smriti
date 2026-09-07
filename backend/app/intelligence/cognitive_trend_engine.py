# SMRITI - 7-Day Rolling Cognitive Trend Engine
# Owner: Aradhya (AI + Database + Sync)

from datetime import datetime, timedelta
from typing import List, Dict, Any
from .metrics import calculate_memory_metric, calculate_attention_metric, calculate_engagement_metric

class CognitiveTrendEngine:
    """
    Analyzes longitudinal cognitive performance over a 7-day rolling window.
    Tracks patterns over time rather than reacting to a single bad attempt.
    """

    @staticmethod
    def compute_7day_trend(
        patient_id: str,
        game_attempts: List[Dict[str, Any]],
        checkins: List[Dict[str, Any]],
        sessions: List[Dict[str, Any]],
        reminders: List[Dict[str, Any]],
        baseline: Dict[str, float],
        end_date: datetime = None
    ) -> Dict[str, Any]:
        end_date = end_date or datetime.utcnow()
        start_date = end_date - timedelta(days=6)

        daily_points = []
        for i in range(7):
            day_target = start_date + timedelta(days=i)
            day_str = day_target.strftime("%Y-%m-%d")

            day_games = [g for g in game_attempts if str(g.get("timestamp", ""))[:10] == day_str]
            day_checkins = [c for c in checkins if str(c.get("timestamp", ""))[:10] == day_str]
            day_sessions = [s for s in sessions if str(s.get("started_at", ""))[:10] == day_str]
            day_reminders = [r for r in reminders if str(r.get("scheduled_time", ""))[:10] == day_str]

            day_mem = calculate_memory_metric(day_games, default_baseline=baseline.get("baseline_memory", 70.0))
            day_att = calculate_attention_metric(day_games, default_baseline=baseline.get("baseline_attention", 70.0))
            day_eng = calculate_engagement_metric(day_sessions, day_checkins, day_reminders, expected_days=1)

            daily_points.append({
                "date": day_str,
                "day_label": day_target.strftime("%a"),
                "memory_score": day_mem,
                "attention_score": day_att,
                "engagement_score": day_eng,
            })

        rolling_memory = round(sum(d["memory_score"] for d in daily_points) / 7.0, 2)
        rolling_attention = round(sum(d["attention_score"] for d in daily_points) / 7.0, 2)
        rolling_engagement = round(sum(d["engagement_score"] for d in daily_points) / 7.0, 2)

        b_mem = baseline.get("baseline_memory", 70.0)
        b_att = baseline.get("baseline_attention", 70.0)
        b_eng = baseline.get("baseline_engagement", 70.0)

        delta_mem_pct = round(((rolling_memory - b_mem) / b_mem) * 100.0, 1) if b_mem > 0 else 0.0
        delta_att_pct = round(((rolling_attention - b_att) / b_att) * 100.0, 1) if b_att > 0 else 0.0
        delta_eng_pct = round(((rolling_engagement - b_eng) / b_eng) * 100.0, 1) if b_eng > 0 else 0.0

        return {
            "patient_id": patient_id,
            "window_days": 7,
            "rolling_memory": rolling_memory,
            "rolling_attention": rolling_attention,
            "rolling_engagement": rolling_engagement,
            "baseline": {
                "memory": b_mem,
                "attention": b_att,
                "engagement": b_eng,
            },
            "delta_memory_pct": delta_mem_pct,
            "delta_attention_pct": delta_att_pct,
            "delta_engagement_pct": delta_eng_pct,
            "daily_points": daily_points,
        }
