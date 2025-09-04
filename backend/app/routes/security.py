from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.api.deps import get_current_user
from app.core.security import verify_password, get_password_hash  # adapt to your helpers
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["security"])

class ChangePasswordIn(BaseModel):
    old_password: str = Field(..., min_length=6)
    new_password: str = Field(..., min_length=6)

@router.post("/change-password", status_code=status.HTTP_204_NO_CONTENT)
def change_password(payload: ChangePasswordIn, db: Session = Depends(get_db), user=Depends(get_current_user)):
    db_user: User = db.get(User, user.id)
    if not db_user:
        raise HTTPException(status_code=404, detail="user_not_found")
    if not verify_password(payload.old_password, getattr(db_user, "password_hash", None)):
        raise HTTPException(status_code=400, detail="invalid_old_password")
    db_user.password_hash = get_password_hash(payload.new_password)
    db.add(db_user); db.commit()
    return
