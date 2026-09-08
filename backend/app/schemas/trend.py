"""
Trend schemas for the SMRITI platform.

Time-series data points used by the caregiver dashboard and ASHA
triage to visualise patient cognitive and wellbeing trajectories.
"""

from datetime import date, datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

from .cognitive import TrendDirection


# ---------------------------------------------------------------------------
# Single Data Point
# ---------------------------------------------------------------------------

class TrendDataPoint(BaseModel):
    """One data point on a time-series trend chart."""
    record_date: date = Field(..., description="Calendar date for this data point.")
    value: float = Field(..., description="Metric value on this date.")
    sample_count: int = Field(
        ...,
        ge=0,
        description="Number of observations aggregated into this point.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Trend Series
# ---------------------------------------------------------------------------

class TrendSeries(BaseModel):
    """Named time-series for a specific metric."""
    metric_name: str = Field(
        ...,
        description="Name of the metric (e.g. 'average_score', 'mood_score').",
    )
    unit: str = Field(
        ...,
        description="Unit of measurement (e.g. 'points', 'hours', 'ms').",
    )
    direction: TrendDirection = Field(
        ...,
        description="Overall direction across the series.",
    )
    data_points: List[TrendDataPoint] = Field(
        default_factory=list,
        description="Ordered data points (oldest first).",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Patient Trend Response
# ---------------------------------------------------------------------------

class PatientTrendResponse(BaseModel):
    """Multi-metric trend package for a single patient."""
    patient_id: str = Field(..., description="Patient UUID.")
    period_start: date = Field(..., description="Start of trend window.")
    period_end: date = Field(..., description="End of trend window.")
    trends: List[TrendSeries] = Field(
        default_factory=list,
        description="List of trend series for different metrics.",
    )
    generated_at: datetime = Field(
        ...,
        description="Timestamp when trends were computed.",
    )

    model_config = ConfigDict(from_attributes=True)
