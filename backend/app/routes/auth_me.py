# app/routers/auth_me.py
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.security import decode_token
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["auth"])
bearer = HTTPBearer(auto_error=False)

@router.get("/me")
def me(creds: HTTPAuthorizationCredentials = Depends(bearer),
       db: Session = Depends(get_db)):
    if not creds:
        raise HTTPException(status_code=401, detail="missing_token")
    payload = decode_token(creds.credentials)
    user_id = int(payload["sub"])
    user = db.query(User).get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="user_not_found")
    return {
        "id": user.id,
        "name": user.name,
        "phone": user.phone,
        "phone_verified": getattr(user, "phone_verified", True),
        "scope": payload.get("scope", "user"),
        "role": payload.get("role"),
    }
