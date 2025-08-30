from fastapi import APIRouter, HTTPException, Depends, Request
from sqlalchemy.orm import Session
from random import randint

from app.schemas.auth import RegisterReq, LoginReq, VerifyReq, TokenOut
from app.db.session import get_db
from app.models import User, Role
from app.core.security import create_access_token, create_refresh_token, decode_token
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
    otp_store.put(db, user.phone, otp)
    return {"dev_otp": otp, "message": "DEV ONLY. Use /auth/verify within 5 minutes."}


@router.post("/verify", response_model=TokenOut)
@limiter.limit("5/minute")
def verify(request: Request, data: VerifyReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == data.phone).first()
    if not user:
        raise HTTPException(status_code=404, detail="user not found")

    # lockout check
    if otp_store.is_locked(db, user.phone):
        raise HTTPException(status_code=429, detail="otp_locked_try_later")

    code = otp_store.get(db, user.phone)
    if not code or code != data.otp:
        state = otp_store.record_failed_attempt(db, user.phone)
        if state.get("locked_until"):
            raise HTTPException(status_code=429, detail="otp_locked_try_later")
        raise HTTPException(status_code=400, detail="invalid_or_expired_otp")

    # success
    otp_store.pop(db, user.phone)
    otp_store.reset_attempts(db, user.phone)
    access = create_access_token(user.id, user.role.value, {"phone": user.phone})
    refresh = create_refresh_token(user.id, user.role.value, {"phone": user.phone})
    return TokenOut(access_token=access, refresh_token=refresh)

@router.post("/refresh", response_model=TokenOut)
def refresh_token(body: dict, db: Session = Depends(get_db)):
    # accept both explicit schema or raw dict
    token = body.get("refresh_token") if isinstance(body, dict) else None
    if not token:
        raise HTTPException(status_code=400, detail="missing_refresh_token")
    try:
        payload = decode_token(token)
    except Exception:
        raise HTTPException(status_code=401, detail="invalid_token")
    if payload.get("typ") != "refresh":
        raise HTTPException(status_code=400, detail="wrong_token_type")
    sub = payload.get("sub")
    role = payload.get("role")
    phone = payload.get("phone")
    # ensure user still exists
    user = db.query(User).filter(User.id == int(sub)).first()
    if not user:
        raise HTTPException(status_code=404, detail="user_not_found")
    access = create_access_token(sub, role, {"phone": phone})
    return TokenOut(access_token=access)
