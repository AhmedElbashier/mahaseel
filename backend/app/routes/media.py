# app/routers/media.py
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.schemas_media import MediaOut
from app.services.media_service import save_image_to_disk, create_media_record, set_main_for_crop
from app.models.crop import Crop
import os

router = APIRouter(prefix="/media", tags=["media"])

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "..", "uploads")  # same place you mounted
MAX_BYTES = 10 * 1024 * 1024  # 10MB max upload


@router.post("/upload", response_model=MediaOut)
async def upload_media(
    crop_id: int,
    is_main: bool = False,
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # 1) Basic validations
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image")

    blob = await file.read()
    if len(blob) > MAX_BYTES:
        raise HTTPException(413, "Image too large (max 10MB)")

    # 2) Ensure crop exists
    crop = db.query(Crop).get(crop_id)
    if not crop:
        raise HTTPException(404, "Crop not found")

    # 3) Save + downscale
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    filename, width, height = save_image_to_disk(UPLOAD_DIR, blob)

    # 4) Create DB row
    media = create_media_record(
        db,
        crop_id=crop_id,
        rel_path=filename,  # store relative name only
        width=width,
        height=height,
        is_main=is_main
    )

    # 5) If main, unset other mains
    if is_main:
        set_main_for_crop(db, media)

    db.commit()
    db.refresh(media)

    # Build URL (client will GET this)
    return MediaOut(
        id=media.id,
        url=f"/static/{media.path}",
        is_main=media.is_main,
        width=media.width,
        height=media.height,
        crop_id=media.crop_id,
    )

@router.post("/{media_id}/make-main", response_model=MediaOut)
def make_main(media_id: int, db: Session = Depends(get_db)):
    from app.models.media import Media

    media = db.query(Media).get(media_id)
    if not media:
        raise HTTPException(404, "Media not found")

    set_main_for_crop(db, media)
    db.commit()
    db.refresh(media)

    return MediaOut(
        id=media.id,
        url=f"/static/{media.path}",
        is_main=media.is_main,
        width=media.width,
        height=media.height,
        crop_id=media.crop_id,
    )

