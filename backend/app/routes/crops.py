# app/api/routes/crops.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.schemas.schemas_crop import CropCreate, CropOut
from app.db.session import get_db
from app.models import Crop
from app.api.deps import get_current_user

router = APIRouter(prefix="/crops", tags=["crops"])

def serialize_crop(c: Crop) -> dict:
    return {
        "id": c.id,
        "name": c.name,
        "type": c.type,
        "qty": c.qty,
        "price": c.price,
        "unit": c.unit,
        "seller_id": c.seller_id,
        "location": {
            "lat": c.lat,
            "lng": c.lng,
            "state": c.state,
            "locality": c.locality,
            "address": c.address,
        },
        "notes": c.notes,
    }

@router.post("", response_model=CropOut, status_code=201)
def create_crop(data: CropCreate, db: Session = Depends(get_db), user = Depends(get_current_user)):
    crop = Crop(
        name=data.name,
        type=data.type,
        qty=float(data.qty),
        price=float(data.price),
        unit=data.unit,
        seller_id=user.id,
        lat=data.location.lat,
        lng=data.location.lng,
        state=data.location.state,
        locality=data.location.locality,
        address=data.location.address,
        notes=data.notes,
    )
    db.add(crop); db.commit(); db.refresh(crop)
    return serialize_crop(crop)

@router.get("", response_model=List[CropOut])
def list_crops(
    db: Session = Depends(get_db),
    state: Optional[str] = Query(default=None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    q = db.query(Crop)
    if state:
        q = q.filter(Crop.state == state)
    rows = q.order_by(Crop.id.desc()).offset(offset).limit(limit).all()
    return [serialize_crop(c) for c in rows]

@router.get("/{crop_id}", response_model=CropOut)
def get_crop(crop_id: int, db: Session = Depends(get_db)):
    c = db.query(Crop).get(crop_id)
    if not c:
        raise HTTPException(status_code=404, detail="crop not found")
    return serialize_crop(c)
