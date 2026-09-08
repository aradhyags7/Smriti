"""API Routers Package."""

from app.api.auth import router as auth_router
from app.api.games import router as games_router
from app.api.patients import router as patients_router
from app.api.sync import router as sync_router

__all__ = [
    "auth_router",
    "games_router",
    "patients_router",
    "sync_router",
]
