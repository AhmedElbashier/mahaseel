# backend/scripts/seed.py
from __future__ import annotations
import random
from typing import Iterable
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models import User, Role, Crop  # adjust if your paths are different

# --- Configurable sample sets -------------------------------------------------

SELLERS = [
    {"name": "مزارع 1", "phone": "+249900000001"},
    {"name": "مزارع 2", "phone": "+249900000002"},
    {"name": "مزارع 3", "phone": "+249900000003"},
    {"name": "مزارع 4", "phone": "+249900000004"},
    {"name": "مزارع 5", "phone": "+249900000005"},
]

BUYERS = [
    {"name": "مشتري 1", "phone": "+249910000001"},
    {"name": "مشتري 2", "phone": "+249910000002"},
    {"name": "مشتري 3", "phone": "+249910000003"},
]

CROPS = [
    # name, type, unit
    ("سمسم", "حبيبات", "طن"),
    ("فول سوداني", "حبيبات", "طن"),
    ("ذرة", "حبيبات", "طن"),
    ("قمح", "حبيبات", "طن"),
    ("بصل", "خضروات", "كجم"),
    ("طماطم", "خضروات", "كجم"),
    ("سمسم أبيض", "حبيبات", "طن"),
    ("ويكة", "مجفف", "كجم"),
    ("صمغ عربي", "منتج غابي", "كجم"),
    ("ذرة شامية", "حبيبات", "طن"),
]

# A few Sudan locations (state, locality, lat, lng) — rough demo coords
PLACES = [
    ("الخرطوم", "بحري", 15.640, 32.540),
    ("الخرطوم", "أمدرمان", 15.650, 32.470),
    ("الجزيرة", "ود مدني", 14.400, 33.520),
    ("سنار", "سنار", 13.550, 33.630),
]

# Optional placeholder images (ignored if your model doesn’t have a field)
IMG_PLACEHOLDERS = [
    "https://images.unsplash.com/photo-1501004318641-b39e6451bec6",
    "https://images.unsplash.com/photo-1447175008436-054170c2e979",
    "https://images.unsplash.com/photo-1506806732259-39c2d0268443",
]


# --- Helpers ------------------------------------------------------------------

def _get_by_phone(db: Session, phone: str) -> User | None:
    return db.execute(select(User).where(User.phone == phone)).scalar_one_or_none()

def _upsert_user(db: Session, name: str, phone: str, role: Role) -> User:
    u = _get_by_phone(db, phone)
    if u:
        # update minimal fields if changed
        changed = False
        if u.name != name:
            u.name = name
            changed = True
        if u.role != role:
            u.role = role
            changed = True
        if changed:
            db.add(u); db.commit(); db.refresh(u)
        return u

    u = User(name=name, phone=phone, role=role)
    db.add(u); db.commit(); db.refresh(u)
    return u

def _rand_near(base: float, spread: float = 0.25) -> float:
    """Return base +/- spread% wiggle."""
    return base + (base * spread) * (random.random() - 0.5) * 2

def _seed_users(db: Session) -> tuple[list[User], list[User]]:
    # Ensure one admin baseline (your original)
    _upsert_user(db, "Admin", "+249000000000", Role.admin)

    sellers: list[User] = []
    for rec in SELLERS:
        sellers.append(_upsert_user(db, rec["name"], rec["phone"], Role.seller))

    buyers: list[User] = []
    for rec in BUYERS:
        buyers.append(_upsert_user(db, rec["name"], rec["phone"], Role.buyer))

    return sellers, buyers

def _existing_crop_keys(db: Session) -> set[tuple[str, int]]:
    """
    Return a set of keys identifying existing crops to keep idempotency.
    Key = (name, seller_id). Adjust if you prefer stricter uniqueness.
    """
    rows = db.execute(select(Crop.name, Crop.seller_id)).all()
    return {(r[0], r[1]) for r in rows}

def _create_crops(db: Session, sellers: Iterable[User]) -> int:
    existing = _existing_crop_keys(db)
    sellers = list(sellers)
    created = 0

    for name, ctype, unit in CROPS:
        seller = random.choice(sellers)
        key = (name, seller.id)
        if key in existing:
            continue

        state, locality, base_lat, base_lng = random.choice(PLACES)
        qty = round(_rand_near(8.0, 0.80), 2)        # ~8 tons ± 80%
        price = round(_rand_near(35000.0, 0.60), 2)  # e.g. SDG price ± 60%
        lat = base_lat + random.uniform(-0.08, 0.08)
        lng = base_lng + random.uniform(-0.08, 0.08)

        crop = Crop(
            name=name,
            type=ctype,
            qty=qty,
            price=price,
            unit=unit,
            seller_id=seller.id,
            state=state,
            locality=locality,
            address="سوق المحاصيل",
            lat=lat,
            lng=lng,
            notes="بيانات تجريبية (staging)",
        )

        # Optional: if your model has a field like `main_image_url`
        if hasattr(Crop, "main_image_url"):
            setattr(crop, "main_image_url", random.choice(IMG_PLACEHOLDERS))

        db.add(crop)
        created += 1

    if created:
        db.commit()
    return created


# --- Public entrypoint --------------------------------------------------------

def run() -> None:
    """
    Idempotent seeding:
      - creates/updates admin + 5 sellers + 3 buyers
      - creates up to 10 crops (skips if same name for same seller already exists)
    Safe to run multiple times.
    """
    random.seed(22)  # deterministic-ish for staging
    db: Session = SessionLocal()
    try:
        sellers, _buyers = _seed_users(db)
        created = _create_crops(db, sellers)
        print(f"Seed OK (created {created} new crops)")
    except Exception as e:
        db.rollback()
        print("Seed failed:", e)
        raise
    finally:
        db.close()


if __name__ == "__main__":
    run()
