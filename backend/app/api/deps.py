from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError

from app.core.security import decode_token
from app.db.session import get_db
from app.models import User

bearer = HTTPBearer(auto_error=True)

def get_current_user(
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    try:
        payload = decode_token(cred.credentials)
        sub = payload.get("sub")
        if not sub:
            raise HTTPException(status_code=401, detail="invalid token")
        user = db.get(User, int(sub))
        if not user:
            raise HTTPException(status_code=401, detail="user not found")
        return user
    except JWTError:
        raise HTTPException(status_code=401, detail="invalid token")
