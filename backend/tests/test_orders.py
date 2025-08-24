import pytest
from fastapi.testclient import TestClient
from app.models import User, Role
from app.core.security import create_access_token


def _sample_crop(state="State1"):
    return {
        "name": "Tomatoes",
        "type": "veg",
        "qty": 100,
        "price": 50,
        "unit": "kg",
        "location": {
            "lat": 1.0,
            "lng": 2.0,
            "state": state,
            "locality": "Loc",
            "address": "Addr",
        },
        "notes": "Fresh",
    }


def _create_crop(client: TestClient, headers):
    r = client.post("/crops", json=_sample_crop(), headers=headers)
    assert r.status_code == 201
    return r.json()["id"]


def _create_order(client: TestClient, crop_id: int, headers):
    r = client.post(
        "/orders",
        json={"crop_id": crop_id, "qty": 5, "note": "note"},
        headers=headers,
    )
    assert r.status_code == 201
    return r.json()["id"]


@pytest.fixture
def other_seller_headers(db):
    user = User(name="Other Seller", phone="2222222222", role=Role.seller)
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(user.id, user.role.value)
    return {"Authorization": f"Bearer {token}"}


def test_update_status_authorized(client: TestClient, auth_headers, buyer_headers):
    crop_id = _create_crop(client, auth_headers)
    order_id = _create_order(client, crop_id, buyer_headers)
    r = client.patch(
        f"/orders/{order_id}/status",
        params={"status": "chatting"},
        headers=auth_headers,
    )
    assert r.status_code == 200
    assert r.json()["status"] == "chatting"


def test_update_status_unauthorized_role(client: TestClient, auth_headers, buyer_headers):
    crop_id = _create_crop(client, auth_headers)
    order_id = _create_order(client, crop_id, buyer_headers)
    r = client.patch(
        f"/orders/{order_id}/status",
        params={"status": "chatting"},
        headers=buyer_headers,
    )
    assert r.status_code == 403


def test_update_status_unauthorized_seller(
    client: TestClient, auth_headers, buyer_headers, other_seller_headers
):
    crop_id = _create_crop(client, auth_headers)
    order_id = _create_order(client, crop_id, buyer_headers)
    r = client.patch(
        f"/orders/{order_id}/status",
        params={"status": "chatting"},
        headers=other_seller_headers,
    )
    assert r.status_code == 403
