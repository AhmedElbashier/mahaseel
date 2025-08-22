# app/utils/serializers.py
from decimal import Decimal
from typing import Any
from app.models.crop import Crop

def _to_float(x: Any):
    return float(x) if isinstance(x, Decimal) else x

def _media_url(m) -> str | None:
    if getattr(m, "url", None):
        return m.url
    if getattr(m, "path", None):
        return f"/static/{m.path}"
    return None

def serialize_crop(crop: Crop | tuple) -> dict:
    if isinstance(crop, tuple):
        crop = crop[0]

    media_list = getattr(crop, "media", None) or []
    main = next((m for m in media_list if getattr(m, "is_main", False)), None)

    return {
        "id": crop.id,
        "name": crop.name,
        "type": getattr(crop, "type", None),
        "qty": _to_float(crop.qty),
        "price": _to_float(crop.price),
        "unit": crop.unit,
        "seller_id": crop.seller_id,
        # Optional (only if you have seller relation/columns):
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
        "main_image_url": _media_url(main),
    }
