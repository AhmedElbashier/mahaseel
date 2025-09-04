from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.api.deps import get_current_user
from app.models import Crop
from app.schemas.crop import CropOut  # reuse your existing schema

router = APIRouter(prefix="/me/ads", tags=["ads"])

@router.get("", response_model=List[CropOut])
def my_ads(db: Session = Depends(get_db), user=Depends(get_current_user)):
    rows = (
        db.query(Crop)
        .filter(Crop.seller_id == user.id)
        .order_by(Crop.created_at.desc())
        .all()
    )
    return [CropOut.model_validate(r) for r in rows]  # or manual mapping if you don't use pydantic v2
