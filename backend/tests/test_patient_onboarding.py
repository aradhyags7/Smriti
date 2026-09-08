import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.main import app
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
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def test_patient_onboarding_and_visibility_for_caregiver_and_asha(client, test_db):
    # 1. Register a new patient
    pat_email = "onboard_pat_test@smriti.com"

    signup_res = client.post(
        "/api/v1/auth/signup",
        json={
            "full_name": "Radha Devi",
            "email": pat_email,
            "password": "password123",
            "role": "patient",
            "phone_number": "+919876500111",
        },
    )
    assert signup_res.status_code == 201
    pat_user_id = signup_res.json()["id"]

    # Log in as patient
    login_res = client.post(
        "/api/v1/auth/login",
        json={"email": pat_email, "password": "password123"},
    )
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]
    assert login_res.json()["is_onboarded"] is False
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Check profile before onboarding
    me_res = client.get("/api/v1/patients/me", headers=headers)
    assert me_res.status_code == 200
    me_data = me_res.json()
    assert me_data["is_onboarded"] is False
    assert me_data["full_name"] == "Radha Devi"

    # 3. Submit one-time onboarding
    onboarding_payload = {
        "age": 75,
        "gender": "female",
        "dementia_type": "Alzheimer’s disease",
    }
    post_res = client.post("/api/v1/patients/onboarding", json=onboarding_payload, headers=headers)
    assert post_res.status_code == 200
    onboarded_data = post_res.json()
    assert onboarded_data["is_onboarded"] is True
    assert onboarded_data["age"] == 75
    assert onboarded_data["gender"] == "female"
    assert onboarded_data["dementia_type"] == "Alzheimer’s disease"

    # 4. Confirm subsequent login returns is_onboarded == True
    login_res2 = client.post(
        "/api/v1/auth/login",
        json={"email": pat_email, "password": "password123"},
    )
    assert login_res2.status_code == 200
    assert login_res2.json()["is_onboarded"] is True

    # 5. Caregiver views patient: caregiver sees age, gender, and dementia_type
    cg_email = "onboard_cg_test@smriti.com"

    cg_signup = client.post(
        "/api/v1/auth/signup",
        json={
            "full_name": "Sunita Devi",
            "email": cg_email,
            "password": "password123",
            "role": "caregiver",
            "phone_number": "+919876500222",
        },
    )
    assert cg_signup.status_code == 201
    cg_login = client.post("/api/v1/auth/login", json={"email": cg_email, "password": "password123"})
    cg_token = cg_login.json()["access_token"]
    cg_headers = {"Authorization": f"Bearer {cg_token}"}

    # Connect patient to caregiver
    conn_res = client.post(
        "/api/v1/caregivers/connect-patient",
        json={"patient_email": pat_email, "relationship": "Mother"},
        headers=cg_headers,
    )
    assert conn_res.status_code == 200
    conn_data = conn_res.json()
    assert conn_data["age"] == 75
    assert conn_data["gender"] == "female"
    assert conn_data["dementia_type"] == "Alzheimer’s disease"

    # Caregiver list my-patients
    my_pts = client.get("/api/v1/caregivers/my-patients", headers=cg_headers)
    assert my_pts.status_code == 200
    pts_list = my_pts.json()
    matched = [p for p in pts_list if p["email"] == pat_email]
    assert len(matched) == 1
    assert matched[0]["age"] == 75
    assert matched[0]["gender"] == "female"
    assert matched[0]["dementia_type"] == "Alzheimer’s disease"

    # 6. ASHA worker views patient: ASHA sees age, gender, and dementia_type
    asha_email = "onboard_asha_test@smriti.com"

    asha_signup = client.post(
        "/api/v1/auth/signup",
        json={
            "full_name": "Priyanka Kalita",
            "email": asha_email,
            "password": "password123",
            "role": "asha",
            "phone_number": "+919876500333",
        },
    )
    assert asha_signup.status_code == 201
    asha_login = client.post("/api/v1/auth/login", json={"email": asha_email, "password": "password123"})
    asha_token = asha_login.json()["access_token"]
    asha_headers = {"Authorization": f"Bearer {asha_token}"}

    # Assign patient to ASHA
    assign_res = client.post(
        "/api/v1/asha/assign-patient",
        json={"patient_id": onboarded_data["id"], "village_notes": "First assessment needed"},
        headers=asha_headers,
    )
    assert assign_res.status_code == 200
    assign_data = assign_res.json()
    assert assign_data["age"] == 75
    assert assign_data["gender"] == "female"
    assert assign_data["dementia_type"] == "Alzheimer’s disease"

    # ASHA list my-patients
    asha_pts = client.get("/api/v1/asha/my-patients", headers=asha_headers)
    assert asha_pts.status_code == 200
    asha_list = asha_pts.json()
    matched_asha = [p for p in asha_list if p["patient_id"] == onboarded_data["id"]]
    assert len(matched_asha) == 1
    assert matched_asha[0]["age"] == 75
    assert matched_asha[0]["gender"] == "female"
    assert matched_asha[0]["dementia_type"] == "Alzheimer’s disease"
