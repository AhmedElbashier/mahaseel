import enum
from datetime import datetime
from pydantic import BaseModel
from typing import Optional

class OrderStatus(str, enum.Enum):
    new = "new"
    chatting = "chatting"
    agreed = "agreed"
    closed = "closed"

class OrderCreate(BaseModel):
    crop_id: int
    qty: float
    note: Optional[str] = None

class OrderOut(BaseModel):
    id: int
    qty: float
    note: Optional[str]
    status: OrderStatus
    crop_id: int
    buyer_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
