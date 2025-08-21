# app/services/media_service.py
import os, uuid
from typing import IO
from PIL import Image
from sqlalchemy.orm import Session
from app.models.media import Media

def save_image_to_disk(base_dir: str, file_bytes: bytes) -> tuple[str, int, int]:
    """Saves, converts to JPEG, downscales, returns (filename, width, height)."""
    filename = f"{uuid.uuid4().hex}.jpg"
    abs_path = os.path.join(base_dir, filename)

    # Write raw bytes first (could be png, heic, etc.)
    with open(abs_path, "wb") as f:
        f.write(file_bytes)

    # Open with Pillow, convert -> RGB JPEG, resize max 1200px
    with Image.open(abs_path) as img:
        img = img.convert("RGB")  # ensure JPEG compatible
        img.thumbnail((1200, 1200))
        width, height = img.size
        img.save(abs_path, format="JPEG", optimize=True, quality=85)

    return filename, width, height


def create_media_record(db: Session, *, crop_id: int, rel_path: str, width: int, height: int, is_main: bool=False) -> Media:
    m = Media(
        crop_id=crop_id,
        path=rel_path,  # e.g., just the filename; you’ll prefix with /static/ at response time
        width=width,
        height=height,
        is_main=is_main,
    )
    db.add(m)
    db.flush()  # assign id
    return m


def set_main_for_crop(db: Session, media: Media) -> None:
    """Set this media as main and unset other main for the same crop."""
    db.query(Media).filter(
        Media.crop_id == media.crop_id,
        Media.id != media.id,
        Media.is_main == True
    ).update({Media.is_main: False})
    media.is_main = True
    db.flush()
