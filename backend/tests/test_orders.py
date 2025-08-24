from fastapi.testclient import TestClient
from app.models import User, Role
from app.models.crop import Crop
from app.core.security import create_access_token

def _make_crop(db, seller: User):
    crop = Crop(
        name="Apples",
        type="fruit",
        qty=10,
        price=3,
        unit="kg",
        seller_id=seller.id,
    )
    db.add(crop); db.commit(); db.refresh(crop)
    return crop


def test_create_order_success(client: TestClient, auth_headers, db):
    seller = User(name="CropSeller", phone="4444444444", role=Role.seller)
    db.add(seller); db.commit(); db.refresh(seller)
    crop = _make_crop(db, seller)

    res = client.post("/orders", json={"crop_id": crop.id, "qty": 2}, headers=auth_headers)
    assert res.status_code == 201
    data = res.json()
    assert data["qty"] == 2
    assert data["crop_id"] == crop.id
    assert data["buyer_id"]


def test_create_order_requires_auth(client: TestClient, db):
    seller = User(name="NoAuthSeller", phone="5555555555", role=Role.seller)
    db.add(seller); db.commit(); db.refresh(seller)
    crop = _make_crop(db, seller)

    res = client.post("/orders", json={"crop_id": crop.id, "qty": 1})
    assert res.status_code == 403

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
