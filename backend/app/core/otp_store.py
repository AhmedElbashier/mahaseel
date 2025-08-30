from datetime import datetime, timedelta
from sqlalchemy.orm import Session

TTL_MINUTES = 5

def put(db: Session, phone: str, code: str) -> None:
    from app.models import OTP   # lazy import to avoid cycles
    expires_at = datetime.utcnow() + timedelta(minutes=TTL_MINUTES)
    row = db.query(OTP).filter(OTP.phone == phone).first()
    if row:
        row.code = code
        row.expires_at = expires_at
    else:
        db.add(OTP(phone=phone, code=code, expires_at=expires_at))
    db.commit()

def get(db: Session, phone: str) -> str | None:
    from app.models import OTP
    row = db.query(OTP).filter(OTP.phone == phone).first()
    if not row:
        return None
    if row.expires_at < datetime.utcnow():
        db.delete(row)
        db.commit()
        return None
    return row.code

def pop(db: Session, phone: str) -> None:
    from app.models import OTP
    row = db.query(OTP).filter(OTP.phone == phone).first()
    if row:
        db.delete(row)
        db.commit()
