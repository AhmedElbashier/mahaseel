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

