# app/schemas/crop.py
from pydantic import BaseModel
from typing import Optional

class CropBase(BaseModel):
    name: str
    qty: float
    price: float
    unit: str
    # ... your other fields like location, notes, etc.

class CropOut(CropBase):
    id: int
    main_image_url: Optional[str] = None   # 👈 add this

    class Config:
        from_attributes = True
