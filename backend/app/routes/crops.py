# app/api/routes/crops.py
from fastapi import APIRouter, Depends, HTTPException, Query, Request, Form, File, UploadFile, Body
from enum import Enum
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, selectinload, joinedload
from typing import List, Optional

from app.schemas.crop import CropCreate, CropOut, LocationIn
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
        request: Request,                      # <— add this
    # 1) Try JSON first (Content-Type: application/json)
    data: Optional[CropCreate] = Body(default=None),

    # 2) Or accept multipart/form-data fallbacks (when images are sent)
    name: Optional[str] = Form(default=None),
    type: Optional[str] = Form(default=None),
    qty: Optional[float] = Form(default=None),
    price: Optional[float] = Form(default=None),
    unit: Optional[str] = Form(default=None),
    notes: Optional[str] = Form(default=None),

    # location.* comes flattened from the client
    location_lat: Optional[float] = Form(default=None, alias="location.lat"),
    location_lng: Optional[float] = Form(default=None, alias="location.lng"),
    location_state: Optional[str] = Form(default=None, alias="location.state"),
    location_locality: Optional[str] = Form(default=None, alias="location.locality"),
    location_address: Optional[str] = Form(default=None, alias="location.address"),

    images: List[UploadFile] = File(default_factory=list),

    db: Session = Depends(get_db),
    user = Depends(require_roles("seller", "admin")),
):
    # If JSON wasn't provided, rebuild CropCreate from Form fields
    if data is None:
        required = [name, qty, price, unit, location_lat, location_lng]
        if any(v is None for v in required):
            raise HTTPException(422, "Missing required form fields for crop creation")

        data = CropCreate(
            name=name,
            type=type,
            qty=qty,
            price=price,
            unit=unit,
            notes=notes,
            location=LocationIn(
                lat=location_lat, lng=location_lng,
                state=location_state, locality=location_locality, address=location_address
            ),
        )

    if not data.location:
        raise HTTPException(400, "location is required")

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
    db.refresh(crop, attribute_names=["media"])

    # TODO: save `images` to Media if you want to handle uploads here

    return serialize_crop(crop, request)   # <— pass request


# app/api/routes/crops.py (add below the JSON create)
from fastapi import UploadFile, File, Form
from pathlib import Path
from app.models.media import Media  # assumes you have this model

UPLOAD_DIR = Path("static/uploads")

@router.post("/upload", response_model=CropOut, status_code=201)
async def create_crop_upload(
    request: Request,
    name: str = Form(...),
    type: Optional[str] = Form(None),
    qty: float = Form(...),
    price: float = Form(...),
    unit: str = Form(...),
    notes: Optional[str] = Form(None),
    location_lat: float = Form(..., alias="location.lat"),
    location_lng: float = Form(..., alias="location.lng"),
    location_state: Optional[str] = Form(None, alias="location.state"),
    location_locality: Optional[str] = Form(None, alias="location.locality"),
    location_address: Optional[str] = Form(None, alias="location.address"),
    images: list[UploadFile] = File(default_factory=list),
    db: Session = Depends(get_db),
    user = Depends(require_roles("seller", "admin")),
):
    if not location_lat or not location_lng:
        raise HTTPException(400, "location is required")

    # normalize state same as JSON path
    norm_state = location_state.strip().title() if location_state else None

    crop = Crop(
        name=name,
        type=type,
        qty=float(qty),
        price=float(price),
        unit=unit,
        seller_id=user.id,
        lat=location_lat,
        lng=location_lng,
        state=norm_state,
        locality=location_locality,
        address=location_address,
        notes=notes,
    )
    db.add(crop)
    db.flush()  # get crop.id before saving media

    # ensure upload dir exists
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    # simple limits (defense-in-depth)
    if len(images) > 5:
        raise HTTPException(400, "You can upload up to 5 images")

    saved_any = False
    for idx, f in enumerate(images):
        if not f.filename:
            continue
        # very light content-type guard
        if not (f.content_type or "").startswith(("image/",)):
            continue

        # give it a deterministic unique path
        suffix = Path(f.filename).suffix.lower() or ".jpg"
        file_name = f"{crop.id}_{idx}{suffix}"
        disk_path = UPLOAD_DIR / file_name

        # stream to disk
        with disk_path.open("wb") as out:
            while chunk := await f.read(1024 * 1024):
                out.write(chunk)

        # persist Media row (store relative path; serializer builds URLs)
        m = Media(
            crop_id=crop.id,
            path=f"uploads/{file_name}",
            is_main=(idx == 0),
        )
        db.add(m)
        saved_any = True

    db.commit()
    db.refresh(crop)
    db.refresh(crop, attribute_names=["media", "seller"])

    return serialize_crop(crop, request)


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
