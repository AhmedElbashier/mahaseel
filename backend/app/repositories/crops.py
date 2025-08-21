# app/repositories/crops.py
from sqlalchemy.orm import Session, aliased
from app.models.crop import Crop
from app.models.media import Media

def get_crop_with_main(db: Session, crop_id: int):
    M = aliased(Media)
    # left join to main image (partial unique index guarantees 0..1)
    q = (
        db.query(Crop, M)
        .outerjoin(M, (M.crop_id == Crop.id) & (M.is_main == True))
        .filter(Crop.id == crop_id)
    )
    row = q.first()
    return row  # (Crop, Media|None)

def list_crops_with_main(db: Session, skip=0, limit=20):
    M = aliased(Media)
    q = (
        db.query(Crop, M)
        .outerjoin(M, (M.crop_id == Crop.id) & (M.is_main == True))
        .offset(skip).limit(limit)
    )
    return q.all()  # list[(Crop, Media|None)]
