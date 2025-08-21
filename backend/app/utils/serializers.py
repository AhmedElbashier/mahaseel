# app/utils/serializers.py
from decimal import Decimal
from app.models.crop import Crop

def _to_float(x):
    return float(x) if isinstance(x, Decimal) else x

def serialize_crop(crop: Crop) -> dict:
    # pick main image if any
    main = next((m for m in (crop.media or []) if getattr(m, "is_main", False)), None)
    url = f"/static/{main.path}" if main else None

    return {
        "id": crop.id,
        "name": crop.name,
        "type": getattr(crop, "type", None),
        "qty": _to_float(crop.qty),
        "price": _to_float(crop.price),
        "unit": crop.unit,
        "seller_id": crop.seller_id,
        "location": {
            "lat": crop.lat,
            "lng": crop.lng,
            "state": crop.state,
            "locality": crop.locality,
            "address": crop.address,
        },
        "notes": crop.notes,
        "main_image_url": url,
    }
