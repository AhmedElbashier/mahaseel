import pytest
from sqlalchemy.exc import IntegrityError

from app.models import Rating, User, Role, Crop


def _create_user(db, name, role):
    user = User(name=name, phone=name, role=role)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def test_unique_rating_per_crop(db):
    buyer = _create_user(db, "buyer", Role.buyer)
    seller = _create_user(db, "seller", Role.seller)
    crop = Crop(name="Wheat", type="grain", qty=1.0, price=10.0, seller_id=seller.id)
    db.add(crop)
    db.commit()
    db.refresh(crop)

    r1 = Rating(stars=5, buyer_id=buyer.id, seller_id=seller.id, crop_id=crop.id)
    db.add(r1)
    db.commit()

    r2 = Rating(stars=4, buyer_id=buyer.id, seller_id=seller.id, crop_id=crop.id)
    db.add(r2)
    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()


def test_unique_seller_rating_without_crop(db):
    buyer = _create_user(db, "b2", Role.buyer)
    seller = _create_user(db, "s2", Role.seller)

    r1 = Rating(stars=5, buyer_id=buyer.id, seller_id=seller.id, crop_id=None)
    db.add(r1)
    db.commit()

    r2 = Rating(stars=3, buyer_id=buyer.id, seller_id=seller.id, crop_id=None)
    db.add(r2)
    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()

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
