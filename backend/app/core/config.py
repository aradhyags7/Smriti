"""Application configuration settings using Pydantic Settings."""

from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Global configuration settings for SMRITI backend."""
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    PROJECT_NAME: str = "SMRITI Backend"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    APP_NAME: str = "SMRITI"
    APP_PORT: int = 8000

    DATABASE_URL: str = "postgresql://ashish-shahi:ashishshahi@localhost:5432/smriti_db"

    SECRET_KEY: str = "change_this_to_a_secure_random_key_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    # Google OAuth 2.0 Web Client ID for ID token cryptographic verification
    GOOGLE_SERVER_CLIENT_ID: Optional[str] = None

    MAX_SYNC_BATCH_SIZE: int = 500
    RISK_THRESHOLD_ATTENTION: int = 60
    RISK_THRESHOLD_MONITOR: int = 40


settings = Settings()
