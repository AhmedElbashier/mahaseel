from fastapi.testclient import TestClient
from app.core.security import decode_token


def test_register_login_verify_flow(client: TestClient):
    payload = {"name": "Alice", "phone": "1112223333"}
    r = client.post("/auth/register", json=payload)
    assert r.status_code == 201

    login = client.post("/auth/login", json={"phone": payload["phone"]})
    assert login.status_code == 200
    otp = login.json()["dev_otp"]

    verify = client.post("/auth/verify", json={"phone": payload["phone"], "otp": otp})
    assert verify.status_code == 200
    token = verify.json()["access_token"]
    claims = decode_token(token)
    assert claims["role"] == "seller"
    assert claims["phone"] == payload["phone"]


def test_register_duplicate_phone(client: TestClient):
    payload = {"name": "Bob", "phone": "2223334444"}
    assert client.post("/auth/register", json=payload).status_code == 201
    r = client.post("/auth/register", json=payload)
    assert r.status_code == 409
