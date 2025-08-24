from fastapi.testclient import TestClient
from app.models import User, Role
from app.models.crop import Crop


def test_create_rating_success(client: TestClient, auth_headers, db):
    seller = User(name="Seller", phone="2222222222", role=Role.seller)
    db.add(seller); db.commit(); db.refresh(seller)

    payload = {"seller_id": seller.id, "stars": 4}
    res = client.post("/ratings", json=payload, headers=auth_headers)
    assert res.status_code == 201
    data = res.json()
    assert data["stars"] == 4
    assert data["seller_id"] == seller.id
    assert data["buyer_id"]


def test_create_rating_duplicate(client: TestClient, auth_headers, db):
    seller = User(name="Seller2", phone="3333333333", role=Role.seller)
    db.add(seller); db.commit(); db.refresh(seller)

    crop = Crop(name="Apple", type="fruit", qty=1, price=1, unit="kg", seller_id=seller.id)
    db.add(crop); db.commit(); db.refresh(crop)

    payload = {"seller_id": seller.id, "crop_id": crop.id, "stars": 5}
    first = client.post("/ratings", json=payload, headers=auth_headers)
    assert first.status_code == 201

    second = client.post("/ratings", json=payload, headers=auth_headers)
    assert second.status_code == 400
