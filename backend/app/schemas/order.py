# app/schemas/order.py
from datetime import datetime
from typing import Optional
from pydantic import BaseModel
try:
    # pydantic v2
    from pydantic import ConfigDict
    _V2 = True
except Exception:
    _V2 = False

# 👇 import the enum from the model to keep a single source of truth
from app.models.order import OrderStatus

class OrderCreate(BaseModel):
    crop_id: int
    qty: float
    note: Optional[str] = None

class OrderOut(BaseModel):
    id: int
    qty: float
    note: Optional[str] = None
    status: OrderStatus
    crop_id: int
    buyer_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    if _V2:
        model_config = ConfigDict(from_attributes=True)
    else:
        class Config:
            orm_mode = True

# ✅ tiny body model for PATCH /orders/{id}/status
class OrderStatusUpdate(BaseModel):
    status: OrderStatus
