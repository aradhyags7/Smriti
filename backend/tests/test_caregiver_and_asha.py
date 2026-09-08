import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.main import app
from app.core.security import get_password_hash, create_access_token
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


def test_caregiver_connect_and_list_patients(client, test_db):
    # Create caregiver user
    cg_user = User(
        id="cg-user-1",
        full_name="Aradhya Caregiver",
        email="caregiver@test.com",
        phone_number="+919876543201",
        hashed_password=get_password_hash("pass123"),
        role="caregiver",
    )
    test_db.add(cg_user)

    # Create patient user
    pt_user = User(
        id="pt-user-1",
        full_name="Shravan Patient",
        email="patient@test.com",
        phone_number="+919876543202",
        hashed_password=get_password_hash("pass123"),
        role="patient",
    )
    test_db.add(pt_user)
    test_db.commit()

    # Caregiver token
    token = create_access_token({"sub": cg_user.email})
    headers = {"Authorization": f"Bearer {token}"}

    # Available patients should list the patient
    resp = client.get("/api/v1/caregivers/available-patients", headers=headers)
    assert resp.status_code == 200
    available = resp.json()
    assert len(available) == 1
    assert available[0]["full_name"] == "Shravan Patient"
    assert available[0]["is_connected"] is False

    # Connect patient
    resp = client.post(
        "/api/v1/caregivers/connect-patient",
        headers=headers,
        json={"patient_id": available[0]["patient_id"], "relationship": "Father"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["full_name"] == "Shravan Patient"
    assert data["relationship"] == "Father"

    # My patients should now contain this patient
    resp = client.get("/api/v1/caregivers/my-patients", headers=headers)
    assert resp.status_code == 200
    my_pts = resp.json()
    assert len(my_pts) == 1
    assert my_pts[0]["full_name"] == "Shravan Patient"


def test_asha_assign_and_care_circle(client, test_db):
    # Create ASHA user
    asha_user = User(
        id="asha-user-1",
        full_name="Devi ASHA",
        email="asha@test.com",
        phone_number="+919876543203",
        hashed_password=get_password_hash("pass123"),
        role="asha",
    )
    test_db.add(asha_user)

    # Create patient user
    pt_user = User(
        id="pt-user-2",
        full_name="Elder Patient",
        email="elder@test.com",
        phone_number="+919876543204",
        hashed_password=get_password_hash("pass123"),
        role="patient",
    )
    test_db.add(pt_user)
    test_db.commit()

    # ASHA token
    asha_token = create_access_token({"sub": asha_user.email})
    asha_headers = {"Authorization": f"Bearer {asha_token}"}

    # Community patients
    resp = client.get("/api/v1/asha/community-patients", headers=asha_headers)
    assert resp.status_code == 200
    pts = resp.json()
    assert len(pts) == 1
    p_id = pts[0]["patient_id"]

    # Assign patient
    resp = client.post(
        "/api/v1/asha/assign-patient",
        headers=asha_headers,
        json={"patient_id": p_id, "village_notes": "Needs weekly BP check"},
    )
    assert resp.status_code == 200
    assert resp.json()["full_name"] == "Elder Patient"

    # Patient checks Care Circle
    pt_token = create_access_token({"sub": pt_user.email})
    pt_headers = {"Authorization": f"Bearer {pt_token}"}
    resp = client.get("/api/v1/asha/care-circle", headers=pt_headers)
    assert resp.status_code == 200
    circle = resp.json()
    assert circle["asha_worker"]["name"] == "Devi ASHA"


def test_caregiver_analytics_activity_alerts_reminiscence(client, test_db):
    # Setup caregiver & patient
    cg_user = User(
        id="cg-user-3",
        full_name="Caregiver Three",
        email="cg3@test.com",
        hashed_password=get_password_hash("pass123"),
        role="caregiver",
    )
    test_db.add(cg_user)

    pt_user = User(
        id="pt-user-3",
        full_name="Grandpa Shravan",
        email="shravan3@test.com",
        hashed_password=get_password_hash("pass123"),
        role="patient",
    )
    test_db.add(pt_user)
    test_db.commit()

    token = create_access_token({"sub": cg_user.email})
    headers = {"Authorization": f"Bearer {token}"}

    # Connect
    resp = client.get("/api/v1/caregivers/available-patients", headers=headers)
    assert resp.status_code == 200
    pt_id = resp.json()[0]["patient_id"]

    client.post(
        "/api/v1/caregivers/connect-patient",
        headers=headers,
        json={"patient_id": pt_id, "relationship": "Grandfather"},
    )

    # 1. Test Analytics
    resp = client.get(f"/api/v1/caregivers/patient/{pt_id}/analytics?days=14", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["patient_name"] == "Grandpa Shravan"
    assert "risk_level" in data
    assert "current_memory" in data
    assert "trend" in data

    # 2. Test Activity Feed
    resp = client.get(f"/api/v1/caregivers/patient/{pt_id}/activity-feed", headers=headers)
    assert resp.status_code == 200
    feed = resp.json()
    assert "date" in feed
    assert "games" in feed

    # 3. Test Alerts
    resp = client.get(f"/api/v1/caregivers/patient/{pt_id}/alerts", headers=headers)
    assert resp.status_code == 200
    alerts = resp.json()
    assert isinstance(alerts, list)

    # 4. Test Reminiscence Vault Create, List & Delete
    resp = client.post(
        f"/api/v1/caregivers/patient/{pt_id}/reminiscence",
        headers=headers,
        json={
            "title": "Family Trip to Kaziranga",
            "caption": "Grandpa with grandchildren in 2021",
            "media_type": "PHOTO",
            "media_url": "assets/images/games/reminiscence_memory.jpg",
            "relationship_tag": "Family",
        },
    )
    assert resp.status_code in (200, 201)
    memory = resp.json()
    assert memory["title"] == "Family Trip to Kaziranga"
    assert memory["relationship_tag"] == "Family"
    memory_id = memory["id"]

    # List reminiscences
    resp = client.get(f"/api/v1/caregivers/patient/{pt_id}/reminiscence", headers=headers)
    assert resp.status_code == 200
    mems = resp.json()
    assert len(mems) == 1
    assert mems[0]["id"] == memory_id

    # Delete reminiscence
    resp = client.delete(f"/api/v1/caregivers/reminiscence/{memory_id}", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "success"

    # List again -> 0
    resp = client.get(f"/api/v1/caregivers/patient/{pt_id}/reminiscence", headers=headers)
    assert resp.status_code == 200
    assert not any(m["id"] == memory_id for m in resp.json())
