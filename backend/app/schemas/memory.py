"""
Memory / Reminiscence item schemas for the SMRITI platform.

Supports the reminiscence therapy feature where caregivers upload
photos, audio clips, or text stories that the patient can review.
"""

from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class MemoryItemType(str, Enum):
    """Media type of a reminiscence item."""
    PHOTO = "photo"
    AUDIO = "audio"
    TEXT = "text"


# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------

class ReminiscenceItemCreate(BaseModel):
    """Upload a new reminiscence memory item."""
    patient_id: str = Field(
        ...,
        description="UUID of the patient this memory belongs to.",
    )
    uploaded_by: str = Field(
        ...,
        description="UUID of the caregiver uploading the item.",
    )
    item_type: MemoryItemType = Field(
        ...,
        description="Type of media (photo, audio, text).",
    )
    title: str = Field(
        ...,
        min_length=1,
        max_length=200,
        description="Short descriptive title (e.g. 'Wedding Day 1985').",
    )
    description: Optional[str] = Field(
        default=None,
        max_length=2000,
        description="Narrative or context for the memory item.",
    )
    media_url: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Cloud storage URL for photo/audio files.",
    )
    text_content: Optional[str] = Field(
        default=None,
        max_length=5000,
        description="Inline text content (for type=text).",
    )
    tags: Optional[List[str]] = Field(
        default=None,
        description="Searchable tags (e.g. ['family', 'festival']).",
    )
    event_date: Optional[datetime] = Field(
        default=None,
        description="Approximate date of the original event.",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

class ReminiscenceItemResponse(BaseModel):
    """Full reminiscence item returned by the API."""
    id: str = Field(..., description="Server-assigned item UUID.")
    patient_id: str = Field(..., description="Patient UUID.")
    uploaded_by: str = Field(..., description="Uploader UUID.")
    item_type: MemoryItemType = Field(..., description="Media type.")
    title: str = Field(..., description="Item title.")
    description: Optional[str] = Field(default=None, description="Narrative text.")
    media_url: Optional[str] = Field(default=None, description="Media file URL.")
    text_content: Optional[str] = Field(default=None, description="Inline text.")
    tags: Optional[List[str]] = Field(default=None, description="Tags.")
    event_date: Optional[datetime] = Field(default=None, description="Event date.")
    view_count: int = Field(
        default=0,
        ge=0,
        description="Number of times the patient has viewed this item.",
    )
    last_viewed_at: Optional[datetime] = Field(
        default=None,
        description="Last time the patient viewed this item.",
    )
    created_at: datetime = Field(..., description="Upload timestamp.")
    updated_at: datetime = Field(..., description="Last update timestamp.")

    model_config = ConfigDict(from_attributes=True)
