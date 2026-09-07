# SMRITI Pytest Fixtures - In-Memory SQLite Database
# Owner: Aradhya (AI + Database + Sync)

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.core.database import Base
# Import all models to register with Base.metadata
import app.models  # noqa: F401

@pytest.fixture(scope="function")
def db_session():
    """
    Creates a fresh, isolated in-memory SQLite database for each test.
    """
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool
    )
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()
