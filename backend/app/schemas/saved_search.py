from pydantic import BaseModel
from typing import Any, Dict

class SavedSearchCreate(BaseModel):
    name: str
    query_json: Dict[str, Any]

class SavedSearchOut(BaseModel):
    id: int
    name: str
    query_json: Dict[str, Any]
    created_at: str
