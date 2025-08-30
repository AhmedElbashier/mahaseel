# app/schemas/crop.py
from datetime import datetime
from pydantic import BaseModel, Field, condecimal
from typing import Optional

class LocationIn(BaseModel):
    lat: float
    lng: float
    state: Optional[str] = None
    locality: Optional[str] = None
    address: Optional[str] = None

class CropCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=80)
    type: Optional[str] = None
    qty: condecimal(gt=0)   # Decimal
    price: condecimal(gt=0) # Decimal
    unit: str = Field(..., min_length=1, max_length=16)
    location: LocationIn
    notes: Optional[str] = None

class CropOut(BaseModel):
    id: int
    name: str
    type: Optional[str] = None
    qty: float
    price: float
    unit: str
    seller_id: int
    seller_name: Optional[str] = None   # NEW
    seller_phone: Optional[str] = None  # NEW
    location: LocationIn
    notes: Optional[str] = None
    image_url: Optional[str] = None
    images: list[str] = []              # NEW
    created_at: datetime

    class Config:
        from_attributes = True
