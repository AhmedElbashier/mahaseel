from sqlalchemy.orm import Session
from typing import List
from app.models.saved_search import SavedSearch

def list_saved(db: Session, user_id: int) -> List[SavedSearch]:
    return db.query(SavedSearch).filter(SavedSearch.user_id == user_id).order_by(SavedSearch.created_at.desc()).all()

def create_saved(db: Session, user_id: int, name: str, query_json: dict) -> SavedSearch:
    s = SavedSearch(user_id=user_id, name=name, query_json=query_json)
    db.add(s); db.commit(); db.refresh(s)
    return s

def delete_saved(db: Session, user_id: int, saved_id: int) -> bool:
    s = db.query(SavedSearch).filter(SavedSearch.id == saved_id, SavedSearch.user_id == user_id).first()
    if not s: return False
    db.delete(s); db.commit()
    return True
