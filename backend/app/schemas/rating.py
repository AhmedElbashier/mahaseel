from pydantic import BaseModel, conint
from typing import Optional

class RatingCreate(BaseModel):
    stars: conint(ge=1, le=5)
    seller_id: int            # include seller id in the payload (simplest)
    crop_id: Optional[int] = None

class RatingOut(BaseModel):
    id: int
    stars: int
    seller_id: int
    buyer_id: int
    crop_id: Optional[int] = None

    class Config:
        from_attributes = True
