import enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict, condecimal

class OrderStatusEnum(str, enum.Enum):
    new = "new"
    chatting = "chatting"
    agreed = "agreed"
    closed = "closed"

class OrderCreate(BaseModel):
    qty: condecimal(gt=0) = Field(..., description="Requested quantity")
    note: Optional[str] = None
    status: OrderStatusEnum = Field(default=OrderStatusEnum.new)
    crop_id: int
    buyer_id: int

    model_config = ConfigDict(json_schema_extra={
        "examples": [
            {
                "qty": 25,
                "note": "أريد التفاوض على السعر",
                "status": "new",
                "crop_id": 1,
                "buyer_id": 7
            }
        ]
    })

class OrderOut(BaseModel):
    id: int
    qty: float
    note: Optional[str]
    status: OrderStatusEnum
    crop_id: int
    buyer_id: Optional[int]

    model_config = ConfigDict(from_attributes=True, json_schema_extra={
        "examples": [
            {
                "id": 3,
                "qty": 25.0,
                "note": "أريد التفاوض على السعر",
                "status": "chatting",
                "crop_id": 1,
                "buyer_id": 7
            }
        ]
    })
