from fastapi.testclient import TestClient
from app.models import User, Role
from app.models.crop import Crop


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
