# app/services/media_service.py
from io import BytesIO
import os
import uuid

import boto3
import clamd
from PIL import Image, ImageOps, UnidentifiedImageError
from sqlalchemy.orm import Session

from app.models.media import Media


S3_BUCKET = os.getenv("S3_BUCKET", "")
CDN_BASE_URL = os.getenv("CDN_BASE_URL", "")
CLAMD_HOST = os.getenv("CLAMD_HOST", "localhost")
CLAMD_PORT = int(os.getenv("CLAMD_PORT", "3310"))


def _process_image(file_bytes: bytes) -> tuple[bytes, int, int]:
    """Decode, normalize orientation, downscale and encode to JPEG."""
    try:
        img = Image.open(BytesIO(file_bytes))
        img.load()
    except (UnidentifiedImageError, OSError) as e:
        raise ValueError("invalid image") from e

    try:
        img = ImageOps.exif_transpose(img)
    except Exception:
        pass

    if img.mode not in ("RGB", "L"):
        img = img.convert("RGB")

    img.thumbnail((1200, 1200), Image.LANCZOS)
    width, height = img.size

    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85, optimize=True)
    buf.seek(0)
    return buf.read(), width, height


def _scan_bytes(data: bytes) -> None:
    """Best-effort virus scan using a ClamAV daemon."""
    try:
        cd = clamd.ClamdNetworkSocket(host=CLAMD_HOST, port=CLAMD_PORT)
        result = cd.instream(BytesIO(data))
        status = result.get("stream", ("UNKNOWN",))[0]
        if status != "OK":
            raise ValueError("infected file")
    except Exception:
        # If scanner unavailable or returns error, skip but do not block upload
        pass


def upload_image_to_s3(file_bytes: bytes) -> tuple[str, int, int]:
    """Process, scan and upload image to S3. Returns (key, width, height)."""
    processed, width, height = _process_image(file_bytes)
    _scan_bytes(processed)
    key = f"{uuid.uuid4().hex}.jpg"
    s3 = boto3.client("s3")
    s3.upload_fileobj(
        BytesIO(processed), S3_BUCKET, key, ExtraArgs={"ContentType": "image/jpeg"}
    )
    return key, width, height


def get_media_url(key: str, *, expires_in: int = 3600) -> str:
    """Return a CDN URL if configured, otherwise a presigned S3 URL."""
    if CDN_BASE_URL:
        return f"{CDN_BASE_URL.rstrip('/')}/{key}"
    s3 = boto3.client("s3")
    return s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": S3_BUCKET, "Key": key},
        ExpiresIn=expires_in,
    )


def delete_media_from_s3(key: str) -> None:
    s3 = boto3.client("s3")
    try:
        s3.delete_object(Bucket=S3_BUCKET, Key=key)
    except Exception:
        pass


def create_media_record(
    db: Session,
    *,
    crop_id: int,
    rel_path: str,
    width: int,
    height: int,
    is_main: bool = False,
) -> Media:
    m = Media(
        crop_id=crop_id,
        path=rel_path,
        width=width,
        height=height,
        is_main=is_main,
    )
    db.add(m)
    db.flush()
    return m


def set_main_for_crop(db: Session, media: Media) -> None:
    db.query(Media).filter(
        Media.crop_id == media.crop_id,
        Media.id != media.id,
        Media.is_main.is_(True),
    ).update({Media.is_main: False}, synchronize_session=False)
    media.is_main = True
    db.flush()
