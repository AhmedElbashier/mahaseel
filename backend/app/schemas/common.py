from pydantic import BaseModel
from typing import Generic, TypeVar, List

T = TypeVar("T")

class Paginated(BaseModel, Generic[T]):
    items: List[T]
    page: int
    limit: int
    total: int
