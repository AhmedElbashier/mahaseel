import pytest
from urllib.parse import quote

from app.models import User, Crop, Role


@pytest.fixture
def seller(db):
    seller = User(name="Seller", phone="1234567890", role=Role.seller)
    db.add(seller)
    db.commit()
    db.refresh(seller)
    return seller


@pytest.fixture
def crop(db, seller):
    crop = Crop(
        name="Tomatoes",
        type="veg",
        qty=10.0,
        price=20.0,
        seller_id=seller.id,
    )
    db.add(crop)
    db.commit()
    db.refresh(crop)
    return crop


def test_whatsapp_link(client, seller, crop):
    message = "Hello"
    res = client.get(f"/contact/{seller.id}/whatsapp", params={"text": message})
    assert res.status_code == 200
    data = res.json()
    assert data["url"] == f"https://wa.me/{seller.phone}?text={quote(message)}"
