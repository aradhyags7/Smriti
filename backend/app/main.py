"""Main entrypoint for the SMRITI FastAPI backend."""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.auth import router as auth_router
from app.api.games import router as games_router
from app.api.patients import router as patients_router
from app.api.caregivers import router as caregivers_router
from app.api.asha import router as asha_router
from app.api.sync import router as sync_router
from app.api.reminders import router as reminders_router
from app.core.config import settings
from app.core.database import Base, engine
import app.models  # Ensure all SQLAlchemy models are registered

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield

# This is the exact "app" variable Uvicorn is looking for
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Offline-first cognitive care backend for NER",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Wire up API v1 routers
app.include_router(auth_router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(patients_router, prefix="/api/v1/patients", tags=["Patients"])
app.include_router(caregivers_router, prefix="/api/v1/caregivers", tags=["Caregivers"])
app.include_router(asha_router, prefix="/api/v1/asha", tags=["ASHA"])
app.include_router(games_router, prefix="/api/v1/games", tags=["Games"])
app.include_router(sync_router, prefix="/api/v1/sync", tags=["Sync"])
app.include_router(reminders_router, prefix="/api/v1/reminders", tags=["Reminders"])


@app.get("/", tags=["Health"])
def read_root():
    """Root health check endpoint."""
    return {"status": "online", "message": "SMRITI Backend is running"}
