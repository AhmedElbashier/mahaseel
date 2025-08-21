from pydantic import BaseModel

class MediaOut(BaseModel):
    id: int
    url: str
    is_main: bool
    width: int | None
    height: int | None
    crop_id: int

    class Config:
        from_attributes = True
