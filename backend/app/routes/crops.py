# app/api/routes/crops.py
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import func
from sqlalchemy.orm import Session, selectinload,joinedload
from typing import List, Optional

from app.schemas.crop import CropCreate, CropOut
from app.db.session import get_db
from app.models import Crop
from app.api.deps import require_roles
from app.utils.serializers import serialize_crop
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.core.ratelimit import limiter
from backend.app.models.media import Media
from backend.app.models.user import User

router = APIRouter(prefix="/crops", tags=["crops"])

@router.post("", response_model=CropOut, status_code=201)
def create_crop(
    data: CropCreate,
    db: Session = Depends(get_db),
    user = Depends(require_roles("seller", "admin")),
):
    if not data.location:
        raise HTTPException(400, "location is required")

    # Normalize state casing at write-time (optional but helps indexing)
    norm_state = data.location.state.strip() if data.location.state else None
    if norm_state:
        norm_state = norm_state.title()

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
    db.add(crop); db.commit(); db.refresh(crop)
    # eager-load media for consistent response shape
    db.refresh(crop, attribute_names=["media"])
    return serialize_crop(crop)

@router.get("", response_model=List[dict])
@limiter.limit("60/minute")
def list_crops(
    request: Request,
    db: Session = Depends(get_db),
    state: Optional[str] = Query(default=None),
    type_: Optional[str] = Query(default=None, alias="type"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    # Normalize input the SAME way we normalized at write-time
    state_norm = state.strip().title() if state else None

    q = (
        db.query(Crop)
        .options(
            joinedload(Crop.seller).load_only("id", "name", "phone"),
            selectinload(Crop.media).load_only("id", "url", "is_main"),
        )
    )

    if state_norm:
        q = q.filter(Crop.state == state_norm)
    if type_:
        q = q.filter(Crop.type == type_)

    rows = (
        q.order_by(Crop.created_at.desc(), Crop.id.desc())  # created_at for index, id as tiebreaker
         .offset(offset)
         .limit(limit)
         .all()
    )
    return [serialize_crop(c) for c in rows]


@router.get("/{crop_id}", response_model=dict)
@limiter.limit("60/minute")
def get_crop(
    request: Request,
    crop_id: int,
    db: Session = Depends(get_db),
):
    c = (
        db.query(Crop)
        .options(
            selectinload(Crop.media),
            joinedload(Crop.seller),
        )
        .filter(Crop.id == crop_id)
        .first()
    )
    if not c:
        raise HTTPException(status_code=404, detail="crop not found")
    return serialize_crop(c)
