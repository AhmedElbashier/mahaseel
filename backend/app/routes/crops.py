# app/api/routes/crops.py
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic_core import Url
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
from app.models.media import Media
from app.models.user import User

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
    page: Optional[int] = Query(None, ge=1),
):  
    # filters
    state: Optional[str] = Query(default=None, description="State filter"),
    type_: Optional[str] = Query(default=None, alias="type", description="Crop type filter"),
    min_price: Optional[float] = Query(default=None, ge=0),
    max_price: Optional[float] = Query(default=None, ge=0),

    # sorting
    sort: CropSort = Query(default=CropSort.newest),

    # validate price range
    if (min_price is not None) and (max_price is not None) and (min_price > max_price):
        raise HTTPException(status_code=400, detail="min_price cannot be greater than max_price")
    # compute offset from page if provided (page starts at 1)
    if offset is None and page is not None:
        offset = (page - 1) * limit
    if offset is None:
        offset = 0
    # Normalize input the SAME way we normalized at write-time
    state_norm = state.strip().title() if state else None

    q = (
        db.query(Crop)
        .options(
            joinedload(Crop.seller).load_only(User.id, User.name, User.phone),
            selectinload(Crop.media),
        )
    )

    # 4) filters
    if type_:
        q = q.filter(Crop.type == type_)
    if state_norm:
        q = q.filter(Crop.state == state_norm)
    if min_price is not None:
        q = q.filter(Crop.price >= min_price)
    if max_price is not None:
        q = q.filter(Crop.price <= max_price)

    # 5) total BEFORE pagination
    total = q.count()

    # 6) sorting
    if sort == CropSort.newest:
        q = q.order_by(Crop.created_at.desc(), Crop.id.desc())
    elif sort == CropSort.price_asc:
        q = q.order_by(Crop.price.asc(), Crop.id.desc())
    elif sort == CropSort.price_desc:
        q = q.order_by(Crop.price.desc(), Crop.id.desc())

    # 7) pagination
    offset = (page - 1) * limit
    rows = q.offset(offset).limit(limit).all()

    rows = q.order_by(Crop.created_at.desc(), Crop.id.desc()).offset(offset).limit(limit).all()
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