from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class FavoriteListBase(BaseModel):
    name: str = Field(min_length=1, max_length=120)

class FavoriteListCreate(FavoriteListBase):
    pass

class FavoriteListUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=120)

class FavoriteListOut(FavoriteListBase):
    id: int
    is_default: bool
    created_at: datetime
    class Config:
        from_attributes = True

class FavoriteItemCreate(BaseModel):
    crop_id: int
    list_id: Optional[int] = None  # if None → use default list

class FavoriteItemOut(BaseModel):
    id: int
    crop_id: int
    list_id: int
    created_at: datetime
    class Config:
        from_attributes = True

class FavoriteSummaryItem(BaseModel):
    list_id: int
    name: str
    is_default: bool
    count: int

class Paginated(BaseModel):
    page: int
    limit: int
    total: int
