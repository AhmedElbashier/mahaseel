# app/routers/media.py
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, Request
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.media import MediaOut
from app.services.media_service import (
    upload_image_to_s3,
    create_media_record,
    set_main_for_crop,
    get_media_url,
    delete_media_from_s3,
)
from app.models.crop import Crop
from app.core.ratelimit import limiter

router = APIRouter(prefix="/media", tags=["media"])

MAX_BYTES = 10 * 1024 * 1024  # 10MB max upload


@limiter.limit("60/minute")
@router.post("/upload", response_model=MediaOut)
async def upload_media(
    request: Request,
    crop_id: int = Form(...),
    is_main: bool = Form(False),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    # 1) Basic validations
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image")

    blob = await file.read()
    if len(blob) > MAX_BYTES:
        raise HTTPException(413, "Image too large (max 10MB)")

    # 2) Ensure crop exists
    crop = db.get(Crop, crop_id)

    if not crop:
        raise HTTPException(404, "Crop not found")

    # 3) Upload to storage
    filename, width, height = upload_image_to_s3(blob)

    # 4) Create DB row
    media = create_media_record(
        db,
        crop_id=crop_id,
        rel_path=filename,  # store relative name only
        width=width,
        height=height,
        is_main=is_main,
    )

    # 5) If main, unset other mains
    if is_main:
        set_main_for_crop(db, media)

    db.commit()
    db.refresh(media)

    # Build URL (client will GET this)
    return MediaOut(
        id=media.id,
        url=get_media_url(media.path),
        is_main=media.is_main,
        width=media.width,
        height=media.height,
        crop_id=media.crop_id,
    )


@limiter.limit("60/minute")
@router.post("/{media_id}/make-main")
def make_main(request: Request, media_id: int, db: Session = Depends(get_db)):
    from app.models.media import Media

    m = db.query(Media).get(media_id)
    if not m:
        raise HTTPException(404, "Not found")
    # reuse the helper that unsets the previous main
    from app.services.media_service import set_main_for_crop

    set_main_for_crop(db, m)
    db.commit()
    db.refresh(m)
    return {"id": m.id, "url": get_media_url(m.path), "is_main": m.is_main}


@limiter.limit("60/minute")
@router.get("/by-crop/{crop_id}")
def list_media_for_crop(
    request: Request,
    crop_id: int,
    db: Session = Depends(get_db),
):
    from app.models.media import Media

    rows = (
        db.query(Media)
        .filter(Media.crop_id == crop_id)
        .order_by(Media.is_main.desc(), Media.created_at.desc())
        .all()
    )
    return [
        {
            "id": m.id,
            "url": get_media_url(m.path),
            "is_main": m.is_main,
            "width": m.width,
            "height": m.height,
        }
        for m in rows
    ]


@limiter.limit("60/minute")
@router.delete("/{media_id}")
def delete_media(request: Request, media_id: int, db: Session = Depends(get_db)):
    from app.models.media import Media

    m = db.query(Media).get(media_id)
    if not m:
        raise HTTPException(404, "Not found")
    if m.is_main:
        raise HTTPException(
            400, "Cannot delete main image; set another one as main first"
        )

    # delete from storage (best-effort)
    delete_media_from_s3(m.path)

    db.delete(m)
    db.commit()
    return {"ok": True}
