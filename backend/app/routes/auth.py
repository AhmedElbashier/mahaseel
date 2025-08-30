from fastapi import APIRouter, HTTPException, Depends, Request
from sqlalchemy.orm import Session
from random import randint

from app.schemas.auth import RegisterReq, LoginReq, VerifyReq, TokenOut
from app.db.session import get_db
from app.models import User, Role
from app.core.security import create_access_token
from app.core import otp_store
from app.core.ratelimit import limiter

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", status_code=201)
def register(data: RegisterReq, db: Session = Depends(get_db)):
    if db.query(User).filter(User.phone == data.phone).first():
        raise HTTPException(status_code=409, detail="phone already registered")
    user = User(name=data.name, phone=data.phone, role=Role.seller)
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"id": user.id}

@router.post("/login")
@limiter.limit("5/minute")
def login(request: Request, data: LoginReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == data.phone).first()
    if not user:
        raise HTTPException(status_code=404, detail="user not found")
    otp = f"{randint(1000, 9999)}"
    otp_store.put(db, user.phone, otp)              # ✅ pass db
    return {"dev_otp": otp, "message": "DEV ONLY. Use /auth/verify within 5 minutes."}

@router.post("/verify", response_model=TokenOut)
@limiter.limit("5/minute")
def verify(request: Request, data: VerifyReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == data.phone).first()
    if not user:
        raise HTTPException(status_code=404, detail="user not found")
    code = otp_store.get(db, user.phone)            # ✅ pass db
    if not code or code != data.otp:
        raise HTTPException(status_code=400, detail="invalid or expired otp")
    otp_store.pop(db, user.phone)                   # ✅ pass db
    token = create_access_token(user.id, user.role.value, {"phone": user.phone})
    return TokenOut(access_token=token)
