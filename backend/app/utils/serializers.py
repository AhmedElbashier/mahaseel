# app/utils/serializers.py
from decimal import Decimal
from typing import Any, Iterable, Optional
from fastapi import Request

from app.models.crop import Crop
from app.services.media_service import get_media_url


def _to_float(x: Any):
    return float(x) if isinstance(x, Decimal) else x


def abs_url(request: Optional[Request], path: str) -> str:
    if not request:
        return path
    base = str(request.base_url).rstrip("/")
    return f"{base}{path if path.startswith('/') else '/' + path}"


def _media_url_rel(m) -> Optional[str]:
    if getattr(m, "url", None):
        return m.url
    if getattr(m, "path", None):
        return get_media_url(m.path)
    return None


def _media_url_abs(request: Optional[Request], m) -> Optional[str]:
    rel = _media_url_rel(m)
    return abs_url(request, rel) if rel else None


def _images_array(request: Optional[Request], media_list: Iterable) -> list[str]:
    out: list[str] = []
    for m in media_list:
        u = _media_url_abs(request, m)
        if u:
            out.append(u)
    return out


# app/utils/serializers.py
def serialize_crop(crop: Crop | tuple, request: Optional[Request] = None) -> dict:
    if isinstance(crop, tuple):
        crop = crop[0]
    media_list = getattr(crop, "media", None) or []
    main = next((m for m in media_list if getattr(m, "is_main", False)), None)
    images = _images_array(request, media_list)

    return {
        "id": crop.id,
        "name": crop.name,
        "type": getattr(crop, "type", None),
        "qty": _to_float(crop.qty),
        "price": _to_float(crop.price),
        "unit": crop.unit,
        "seller_id": crop.seller_id,
        "seller_name": getattr(getattr(crop, "seller", None), "name", None),
        "seller_phone": getattr(getattr(crop, "seller", None), "phone", None),
        "location": {
            "lat": getattr(crop, "lat", None),
            "lng": getattr(crop, "lng", None),
            "state": getattr(crop, "state", None),
            "locality": getattr(crop, "locality", None),
            "address": getattr(crop, "address", None),
        },
        "notes": getattr(crop, "notes", None),
        "image_url": _media_url_abs(request, main) if main else None,
        "images": images,
        "created_at": crop.created_at,  # <-- add this
    }
