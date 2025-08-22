# app/api/routes/crops.py
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import func
from sqlalchemy.orm import Session, selectinload
from typing import List, Optional

from app.schemas.crop import CropCreate, CropOut
from app.db.session import get_db
from app.models import Crop
from app.api.deps import get_current_user
from app.utils.serializers import serialize_crop
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.core.ratelimit import limiter

router = APIRouter(prefix="/crops", tags=["crops"])

@router.post("", response_model=CropOut, status_code=201)
def create_crop(
    data: CropCreate,
    db: Session = Depends(get_db),
    user = Depends(get_current_user)
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

@limiter.limit("60/minute")
@router.get("", response_model=List[CropOut])
def list_crops(
    request: Request,
    db: Session = Depends(get_db),
    state: Optional[str] = Query(default=None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    q = db.query(Crop).options(selectinload(Crop.media))
    if state:
        # case-insensitive; if you normalize on write you can use == instead
        q = q.filter(func.lower(Crop.state) == state.lower())
    rows = q.order_by(Crop.id.desc()).offset(offset).limit(limit).all()
    return [serialize_crop(c) for c in rows]

@limiter.limit("60/minute")
@router.get("/{crop_id}", response_model=CropOut,)
def get_crop(request: Request,crop_id: int, db: Session = Depends(get_db)):
    c = (
        db.query(Crop)
        .options(selectinload(Crop.media))
        .get(crop_id)
    )
    if not c:
        raise HTTPException(status_code=404, detail="crop not found")
    return serialize_crop(c)
