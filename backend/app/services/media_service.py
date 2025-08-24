# app/services/media_service.py
from io import BytesIO
import tempfile
import os, uuid
from typing import IO
from PIL import Image, ImageOps, UnidentifiedImageError 
from sqlalchemy.orm import Session
from app.models.media import Media
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "/uploads") 
def save_image_to_disk(base_dir: str, file_bytes: bytes) -> tuple[str, int, int]:
    """
    Decode, EXIF-orient, downscale (<=1200px side), encode to JPEG,
    and atomically place into base_dir. Returns (filename, width, height).
    """
    os.makedirs(base_dir, exist_ok=True)
    try:
        img = Image.open(BytesIO(file_bytes))
        img.load()  # fully decode to fail-fast on corrupt data
    except (UnidentifiedImageError, OSError) as e:
        raise ValueError("invalid image") from e

    # Normalize orientation from EXIF if present
    try:
        img = ImageOps.exif_transpose(img)
    except Exception:
        pass

    # Convert to RGB for JPEG
    if img.mode not in ("RGB", "L"):
        img = img.convert("RGB")

    # Downscale keeping aspect (longest side <= 1200)
    img.thumbnail((1200, 1200), Image.LANCZOS)
    width, height = img.size

    # Write to temp then atomically move
    filename = f"{uuid.uuid4().hex}.jpg"
    final_path = os.path.join(base_dir, filename)
    with tempfile.NamedTemporaryFile(delete=False, dir=base_dir, suffix=".part") as tmp:
        tmp_path = tmp.name
        img.save(tmp_path, format="JPEG", quality=85, optimize=True)
    os.replace(tmp_path, final_path)

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
    db.query(Media).filter(
        Media.crop_id == media.crop_id,
        Media.id != media.id,
        Media.is_main.is_(True),
    ).update({Media.is_main: False}, synchronize_session=False)
    media.is_main = True
    db.flush()
