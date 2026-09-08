"""Tests for Google OAuth 2.0 authentication integration in SMRITI."""

from unittest.mock import patch
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.main import app
from app.core.config import settings
from app.core.security import get_password_hash
from app.models import User, Patient, Caregiver, AshaWorker

SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def test_db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(test_db):
    def override_get_db():
        try:
            yield test_db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


def test_google_login_fails_if_server_client_id_unconfigured(client):
    """Google auth must fail with HTTP 500 if GOOGLE_SERVER_CLIENT_ID is not set."""
    with patch.object(settings, "GOOGLE_SERVER_CLIENT_ID", None):
        resp = client.post(
            "/api/v1/auth/google",
            json={"id_token": "any_sample_token"},
        )
        assert resp.status_code == 500
        assert "GOOGLE_SERVER_CLIENT_ID must be set" in resp.json()["detail"]


def test_google_login_rejects_invalid_token(client):
    """Google auth must reject malformed tokens with HTTP 401."""
    with patch.object(settings, "GOOGLE_SERVER_CLIENT_ID", "mock-client-id.apps.googleusercontent.com"):
        resp = client.post(
            "/api/v1/auth/google",
            json={"id_token": "malformed.invalid.token"},
        )
        assert resp.status_code == 401
        assert "Invalid Google ID token" in resp.json()["detail"]


def test_google_login_creates_new_user_and_patient_profile(client, test_db):
    """Successful verification provisions new user and patient record, returning SMRITI JWT."""
    mock_google_payload = {
        "sub": "google-sub-998877",
        "email": "elder.patient@gmail.com",
        "name": "Elder Shravan",
        "picture": "https://lh3.googleusercontent.com/photo",
    }

    with patch.object(settings, "GOOGLE_SERVER_CLIENT_ID", "mock-client-id.apps.googleusercontent.com"), \
         patch("app.api.auth.verify_google_id_token", return_value=mock_google_payload):
        resp = client.post(
            "/api/v1/auth/google",
            json={"id_token": "mock-valid-id-token", "role": "patient"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert data["email"] == "elder.patient@gmail.com"
        assert data["role"] == "patient"
        assert data["full_name"] == "Elder Shravan"

        # Verify DB state
        user = test_db.query(User).filter(User.google_subject == "google-sub-998877").first()
        assert user is not None
        assert user.auth_provider == "GOOGLE"
        assert user.hashed_password is None
        assert user.role == "patient"

        # Strictly role-based profile: Patient exists, Caregiver/Asha do NOT
        patient = test_db.query(Patient).filter(Patient.user_id == user.id).first()
        assert patient is not None
        assert test_db.query(Caregiver).filter(Caregiver.user_id == user.id).first() is None
        assert test_db.query(AshaWorker).filter(AshaWorker.user_id == user.id).first() is None


def test_google_login_idempotent_no_duplicate_users(client, test_db):
    """Repeated sign-in with same Google sub returns the same user without creating duplicates."""
    mock_google_payload = {
        "sub": "google-sub-repeat-11",
        "email": "repeat.user@gmail.com",
        "name": "Repeat User",
    }

    with patch.object(settings, "GOOGLE_SERVER_CLIENT_ID", "mock-client-id.apps.googleusercontent.com"), \
         patch("app.api.auth.verify_google_id_token", return_value=mock_google_payload):
        # 1. First login
        resp1 = client.post("/api/v1/auth/google", json={"id_token": "mock-token-1111"})
        assert resp1.status_code == 200
        user_id_1 = resp1.json()["user_id"]

        # 2. Second login
        resp2 = client.post("/api/v1/auth/google", json={"id_token": "mock-token-2222"})
        assert resp2.status_code == 200
        user_id_2 = resp2.json()["user_id"]

        assert user_id_1 == user_id_2
        # Only one user in DB
        users = test_db.query(User).filter(User.google_subject == "google-sub-repeat-11").all()
        assert len(users) == 1


def test_google_login_account_collision_returns_409(client, test_db):
    """If email belongs to an existing LOCAL user, returns HTTP 409 without silent merge or duplication."""
    # Pre-existing local email/password user
    local_user = User(
        id="local-user-1",
        full_name="Local Account Owner",
        email="existing.local@gmail.com",
        hashed_password=get_password_hash("securepass123"),
        auth_provider="LOCAL",
        role="patient",
    )
    test_db.add(local_user)
    test_db.commit()

    # Google login attempting same email with different Google sub
    mock_google_payload = {
        "sub": "google-sub-different-22",
        "email": "existing.local@gmail.com",
        "name": "Google Login Attempt",
    }

    with patch.object(settings, "GOOGLE_SERVER_CLIENT_ID", "mock-client-id.apps.googleusercontent.com"), \
         patch("app.api.auth.verify_google_id_token", return_value=mock_google_payload):
        resp = client.post("/api/v1/auth/google", json={"id_token": "mock-token-3333"})
        assert resp.status_code == 409
        assert "already exists with password authentication" in resp.json()["detail"]

        # Verify no duplicate user was created
        all_with_email = test_db.query(User).filter(User.email == "existing.local@gmail.com").all()
        assert len(all_with_email) == 1
        assert all_with_email[0].auth_provider == "LOCAL"


def test_existing_email_password_login_continues_to_work(client, test_db):
    """Existing email/password login is completely unaffected."""
    local_user = User(
        id="local-user-2",
        full_name="Standard User",
        email="standard@test.com",
        hashed_password=get_password_hash("password123"),
        auth_provider="LOCAL",
        role="patient",
    )
    test_db.add(local_user)
    test_db.commit()

    resp = client.post(
        "/api/v1/auth/login",
        json={"email": "standard@test.com", "password": "password123"},
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()
    assert resp.json()["email"] == "standard@test.com"
