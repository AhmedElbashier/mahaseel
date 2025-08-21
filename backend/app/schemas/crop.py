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
    qty: condecimal(gt=0)  # numeric, >0
    price: condecimal(gt=0)
    unit: str = Field(..., min_length=1, max_length=16)  # e.g. kg, ton, sack
    location: LocationIn
    notes: Optional[str] = None

class CropOut(BaseModel):
    id: int
    name: str
    type: Optional[str]
    qty: float
    price: float
    unit: str
    seller_id: int
    location: LocationIn
    notes: Optional[str]

    class Config:
        from_attributes = True
