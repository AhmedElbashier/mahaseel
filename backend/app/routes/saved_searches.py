from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.api.deps import get_current_user
from app.schemas.saved_search import SavedSearchCreate, SavedSearchOut
from app.repositories.saved_search import list_saved, create_saved, delete_saved

router = APIRouter(prefix="/me/saved-searches", tags=["saved-searches"])

@router.get("", response_model=List[SavedSearchOut])
def get_saved(db: Session = Depends(get_db), user=Depends(get_current_user)):
    rows = list_saved(db, user.id)
    return [SavedSearchOut(id=r.id, name=r.name, query_json=r.query_json, created_at=r.created_at.isoformat()) for r in rows]

@router.post("", response_model=SavedSearchOut, status_code=status.HTTP_201_CREATED)
def add_saved(payload: SavedSearchCreate, db: Session = Depends(get_db), user=Depends(get_current_user)):
    r = create_saved(db, user.id, payload.name, payload.query_json)
    return SavedSearchOut(id=r.id, name=r.name, query_json=r.query_json, created_at=r.created_at.isoformat())

@router.delete("/{saved_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_saved(saved_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    if not delete_saved(db, user.id, saved_id):
        raise HTTPException(status_code=404, detail="Not found")
    return
