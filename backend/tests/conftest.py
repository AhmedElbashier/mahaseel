import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.db.base import Base
from app import models  # noqa: F401
from app.models import User, Role
from app.models.media import Media
from app.main import app
from app.db.session import get_db
from app.core import otp_store
from app.core.security import create_access_token

@pytest.fixture
def db():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    Media.__table__.indexes.clear()  # drop partial index for SQLite
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            pass
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
    otp_store._store.clear()

@pytest.fixture
def auth_headers(client):
    phone = "1234567890"
    client.post("/auth/register", json={"name": "Tester", "phone": phone})
    login = client.post("/auth/login", json={"phone": phone})
    otp = login.json()["dev_otp"]
    verify = client.post("/auth/verify", json={"phone": phone, "otp": otp})
    token = verify.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def buyer_headers(db):
    user = User(name="Buyer", phone="0000000000", role=Role.buyer)
    db.add(user); db.commit(); db.refresh(user)
    token = create_access_token(user.id, user.role.value)
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def admin_headers(db):
    user = User(name="Admin", phone="1111111111", role=Role.admin)
    db.add(user); db.commit(); db.refresh(user)
    token = create_access_token(user.id, user.role.value)
    return {"Authorization": f"Bearer {token}"}
