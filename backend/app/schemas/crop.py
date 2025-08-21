# app/schemas/crop.py
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
    type: Optional[str]
    qty: float          # expose float to clients
    price: float
    unit: str
    seller_id: int
    location: LocationIn
    notes: Optional[str] = None
    main_image_url: Optional[str] = None

    class Config:
        from_attributes = True
