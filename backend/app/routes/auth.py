from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from random import randint

from app.schemas.auth import RegisterReq, LoginReq, VerifyReq, TokenOut
from app.db.session import get_db
from app.models import User, Role
from app.core.security import create_access_token
from app.core import otp_store

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/ping")
def ping():
    return {"ok": True}


@router.post("/register", status_code=201)
def register(data: RegisterReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == data.phone).first()
    if user:
        raise HTTPException(status_code=409, detail="phone already registered")
    user = User(name=data.name, phone=data.phone, role=Role.seller)
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"id": user.id, "phone": user.phone, "name": user.name}


@router.post("/login")
def login(data: LoginReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == data.phone).first()
    if not user:
        raise HTTPException(status_code=404, detail="user not found")
    otp = f"{randint(1000, 9999)}"
    otp_store.put(user.phone, otp)
    return {"dev_otp": otp, "message": "DEV ONLY. Use /auth/verify within 5 minutes."}


@router.post("/verify", response_model=TokenOut)
def verify(data: VerifyReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == data.phone).first()
    if not user:
        raise HTTPException(status_code=404, detail="user not found")
    otp = otp_store.get(user.phone)
    if not otp or otp != data.otp:
        raise HTTPException(status_code=400, detail="invalid or expired otp")
    otp_store.pop(user.phone)
    token = create_access_token(user.id, user.role.value, {"phone": user.phone})
    return TokenOut(access_token=token)
