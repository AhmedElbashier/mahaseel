# app/routers/auth_social.py
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from pydantic import BaseModel
import random

from app.core.config import settings
from app.core.security import create_access_token, decode_token
from app.core import otp_store

# pick the correct DB session import for your project:
from app.db.session import get_db  # ← change to your actual path if different

from app.models.user import User, Role
from app.models.social_account import SocialAccount, SocialProvider
from app.services.google_oauth import verify_google_id_token
from app.services.facebook_oauth import verify_facebook_access_token

router = APIRouter(prefix="/auth", tags=["auth"])
bearer = HTTPBearer(auto_error=False)

def gen_otp() -> str:
    return f"{random.randint(0, 999999):06d}"

# ---- small helpers ----
def issue_temp(user: User) -> str:
    # limited scope: only link-phone + verify-otp allowed
    return create_access_token(subject=user.id, role=user.role.value, extra={"scope": "link_phone"})

def issue_full(user: User) -> str:
    # full app access
    return create_access_token(subject=user.id, role=user.role.value, extra={"scope": "user"})

def require_scope(creds: HTTPAuthorizationCredentials | None, needed: str) -> dict:
    if not creds:
        raise HTTPException(status_code=401, detail="missing_token")
    payload = decode_token(creds.credentials)
    if payload.get("scope") != needed:
        raise HTTPException(status_code=403, detail="insufficient_scope")
    return payload
def normalize_phone(s: str) -> str:
    # minimal normalization: trim spaces; you can expand later to full E.164
    return s.strip().replace(" ", "")

# ---- DTOs ----
class SocialLoginIn(BaseModel):
    token: str

class LinkPhoneIn(BaseModel):
    phone: str

class VerifyOtpIn(BaseModel):
    phone: str
    code: str

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"

# ---- Google ----
@router.post("/social/google", response_model=TokenOut)
def social_google(body: SocialLoginIn, db: Session = Depends(get_db)):
    info = verify_google_id_token(body.token, settings.google_client_id)
    sub = info["sub"]
    email = info.get("email")
    name = (info.get("name") or "User").strip() or "User"
    avatar = info.get("picture")

    acct = db.query(SocialAccount).filter_by(
        provider=SocialProvider.google, provider_user_id=sub
    ).first()

    if acct:
        user = db.query(User).get(acct.user_id)
    else:
        user = User(name=name, phone=None, phone_verified=False, role=Role.seller)
        db.add(user); db.flush()
        acct = SocialAccount(
            user_id=user.id, provider=SocialProvider.google, provider_user_id=sub,
            email=email, display_name=name, avatar_url=avatar
        )
        db.add(acct)
    db.commit()
    return {"access_token": issue_temp(user)}

# ---- Facebook ----
@router.post("/social/facebook", response_model=TokenOut)
async def social_facebook(body: SocialLoginIn, db: Session = Depends(get_db)):
    info = await verify_facebook_access_token(body.token, settings.fb_app_id, settings.fb_app_secret)
    sub = info["id"]
    email = info.get("email")
    name = (info.get("name") or "User").strip() or "User"
    avatar = (info.get("picture") or {}).get("data", {}).get("url")

    acct = db.query(SocialAccount).filter_by(
        provider=SocialProvider.facebook, provider_user_id=sub
    ).first()

    if acct:
        user = db.query(User).get(acct.user_id)
    else:
        user = User(name=name, phone=None, phone_verified=False, role=Role.seller)
        db.add(user); db.flush()
        acct = SocialAccount(
            user_id=user.id, provider=SocialProvider.facebook, provider_user_id=sub,
            email=email, display_name=name, avatar_url=avatar
        )
        db.add(acct)
    db.commit()
    return {"access_token": issue_temp(user)}



@router.post("/link-phone")
def link_phone(body: LinkPhoneIn,
               db: Session = Depends(get_db),
               creds: HTTPAuthorizationCredentials = Depends(bearer)):
    payload = require_scope(creds, "link_phone")
    user_id = int(payload["sub"])

    phone = normalize_phone(body.phone)

    existing = db.query(User).filter(User.phone == phone).first()
    if existing:
        if existing.id != user_id:
            # someone else owns this phone → stop
            raise HTTPException(status_code=409, detail="phone_in_use")

        # same user already has this phone
        if getattr(existing, "phone_verified", False):
            # nothing to do — already verified; issue full token
            return {"message": "already_verified", "access_token": issue_full(existing)}

        # not verified yet → resend OTP
        code = gen_otp()
        otp_store.put(phone, code)
        return {"message": "otp_resent_dev", "code": code}

    # phone not used by anyone → start OTP
    code = gen_otp()
    otp_store.put(phone, code)
    return {"message": "otp_sent_dev", "code": code}

@router.post("/verify-otp", response_model=TokenOut)
def verify_otp(body: VerifyOtpIn,
               db: Session = Depends(get_db),
               creds: HTTPAuthorizationCredentials = Depends(bearer)):
    # the temp token must have scope=link_phone
    payload = require_scope(creds, "link_phone")
    user_id = int(payload["sub"])

    phone = normalize_phone(body.phone)

    # 1) validate OTP
    saved = otp_store.get(phone)
    if not saved or saved != body.code:
        raise HTTPException(status_code=400, detail="invalid_or_expired_otp")

    # 2) load current (temp) user
    current = db.query(User).get(user_id)
    if not current:
        raise HTTPException(status_code=404, detail="user_not_found")

    # 3) does this phone already belong to someone?
    owner = db.query(User).filter(User.phone == phone).first()

    if owner and owner.id != user_id:
        # ✅ MERGE: phone belongs to another user (owner). Since the caller proved ownership via OTP,
        # move social accounts from the temp user -> real owner, then delete the temp user.
        db.query(SocialAccount).filter(
            SocialAccount.user_id == user_id
        ).update(
            {SocialAccount.user_id: owner.id},
            synchronize_session=False
        )
        # delete the temp user row (make sure no other data is attached to it)
        db.delete(current)
        db.commit()
        otp_store.pop(phone)
        return {"access_token": issue_full(owner)}

    # 4) same user (idempotent) or phone unused → finalize on current user
    if owner and owner.id == user_id and getattr(current, "phone_verified", False):
        # already verified earlier; just upgrade token
        otp_store.pop(phone)
        return {"access_token": issue_full(current)}

    current.phone = phone
    if hasattr(current, "phone_verified"):
        current.phone_verified = True
    db.add(current)
    db.commit()

    otp_store.pop(phone)
    return {"access_token": issue_full(current)}
