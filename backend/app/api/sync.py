"""Offline-first synchronization API routes."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models import User
from app.schemas.sync import SyncPayloadRequest, SyncPayloadResponse
from app.services.sync_service import process_offline_sync

router = APIRouter()


@router.post(
    "/",
    response_model=SyncPayloadResponse,
    status_code=status.HTTP_200_OK,
    summary="Process offline sync batch",
)
def offline_sync(
    payload: SyncPayloadRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Ingest and sync queued cognitive assessment records from offline clients (requires authentication)."""
    return process_offline_sync(db=db, payload=payload)
