# app/api/routes/crops.py
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from enum import Enum
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, selectinload, joinedload
from typing import List, Optional

from app.schemas.crop import CropCreate, CropOut
from app.db.session import get_db
from app.models import Crop
from app.api.deps import require_roles
from app.utils.serializers import serialize_crop
from app.core.ratelimit import limiter
from app.models.user import User
import re

router = APIRouter(prefix="/crops", tags=["crops"])

class CropSort(str, Enum):
    newest = "newest"
    price_asc = "price_asc"
    price_desc = "price_desc"

@router.post("", response_model=CropOut, status_code=201)
def create_crop(
    data: CropCreate,
    db: Session = Depends(get_db),
    user = Depends(require_roles("seller", "admin")),
):
    if not data.location:
        raise HTTPException(400, "location is required")

    # Normalize state casing at write-time
    norm_state = data.location.state.strip().title() if (data.location.state) else None

    crop = Crop(
        name=data.name,
        type=data.type,
        qty=float(data.qty),
        price=float(data.price),
        unit=data.unit,
        seller_id=user.id,
        lat=data.location.lat,
        lng=data.location.lng,
        state=norm_state,
        locality=data.location.locality,
        address=data.location.address,
        notes=data.notes,
    )
    db.add(crop)
    db.commit()
    db.refresh(crop)
    db.refresh(crop, attribute_names=["media"])  # eager-load media
    return serialize_crop(crop)

@router.get("", response_model=dict)
@limiter.limit("60/minute")
def list_crops(
    request: Request,
    db: Session = Depends(get_db),

    # filters
    state: Optional[str] = Query(default=None, description="State filter"),
    type_: Optional[str] = Query(default=None, alias="type", description="Crop type filter"),
    min_price: Optional[float] = Query(default=None, ge=0),
    max_price: Optional[float] = Query(default=None, ge=0),

    # NEW: free-text search
    q: Optional[str] = Query(default=None, description="Free-text search on name/type/state"),

    # sorting
    sort: CropSort = Query(default=CropSort.newest),

    # pagination
    limit: int = Query(50, ge=1, le=100),
    offset: Optional[int] = Query(None, ge=0),
    page: Optional[int] = Query(None, ge=1),
):
    # ...existing validation and page/offset code...

    # Normalize input the SAME way we normalized at write-time
    state_norm = state.strip().title() if state else None  # you already do this
    # --- NEW: normalize q (strip, lower, remove Arabic diacritics and unify letters)
    def _normalize_ar(s: str) -> str:
        # remove Arabic diacritics (tashkeel)
        s = re.sub(r"[\u064B-\u0652]", "", s)
        # unify Arabic forms to improve matching
        s = (s.replace("أ", "ا")
               .replace("إ", "ا")
               .replace("آ", "ا")
               .replace("ى", "ي")
               .replace("ؤ", "و")
               .replace("ئ", "ي")
               .replace("ة", "ه"))
        return s.strip().lower()

    q_norm = _normalize_ar(q) if q else None

    qset = (
        db.query(Crop)
        .options(
            joinedload(Crop.seller).load_only(User.id, User.name, User.phone),
            selectinload(Crop.media),
        )
    )

    # filters
    if type_:
        qset = qset.filter(Crop.type == type_)
    if state_norm:
        qset = qset.filter(Crop.state == state_norm)
    if min_price is not None:
        qset = qset.filter(Crop.price >= min_price)
    if max_price is not None:
        qset = qset.filter(Crop.price <= max_price)

    # --- NEW: search filter (ILIKE on normalized text)
    if q_norm:
        # We normalize the DB columns on the fly similarly (lower + simple char mapping).
        # NOTE: For performance, we’ll add indexes in Step 2.
        def norm_col(col):
            # lower(...) then chain replace(...) like our Python normalize
            return func.lower(
                func.replace(
                    func.replace(
                        func.replace(
                            func.replace(
                                func.replace(
                                    func.replace(col, "أ", "ا"), "إ", "ا"
                                ),
                                "آ", "ا"
                            ),
                            "ى", "ي"
                        ),
                        "ؤ", "و"
                    ),
                    "ئ", "ي"
                )
            )

        pat = f"%{q_norm}%"
        qset = qset.filter(
            or_(
                norm_col(Crop.name).ilike(pat),
                norm_col(Crop.type).ilike(pat),
                norm_col(Crop.state).ilike(pat),
            )
        )

    # total BEFORE pagination
    total = qset.count()

    # sorting (unchanged)
    if sort == CropSort.newest:
        qset = qset.order_by(Crop.created_at.desc(), Crop.id.desc())
    elif sort == CropSort.price_asc:
        qset = qset.order_by(Crop.price.asc(), Crop.id.desc())
    elif sort == CropSort.price_desc:
        qset = qset.order_by(Crop.price.desc(), Crop.id.desc())

    rows = qset.offset(offset).limit(limit).all()

    return {
        "items": [serialize_crop(c, request) for c in rows],
        "page": page,
        "limit": limit,
        "total": total,
    }


@router.get("/{crop_id}", response_model=dict)
@limiter.limit("60/minute")
def get_crop(request: Request, crop_id: int, db: Session = Depends(get_db)):
    c = (
        db.query(Crop)
        .options(selectinload(Crop.media), joinedload(Crop.seller))
        .filter(Crop.id == crop_id)
        .first()
    )
    if not c:
        raise HTTPException(status_code=404, detail="crop not found")
    return serialize_crop(c, request)
