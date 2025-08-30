from datetime import datetime, timedelta
from sqlalchemy.orm import Session

TTL_MINUTES = 5
LOCK_THRESHOLD = 5           # failed attempts before lockout
LOCK_MINUTES = 15            # lockout duration

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
    # if locked, treat as unavailable
    if row.locked_until and row.locked_until > datetime.utcnow():
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

def record_failed_attempt(db: Session, phone: str) -> dict:
    """Increment failed attempts; lock if threshold reached. Returns state dict."""
    from app.models import OTP
    row = db.query(OTP).filter(OTP.phone == phone).first()
    if not row:
        # create a placeholder row with immediate expiry so we can track attempts
        expires_at = datetime.utcnow() + timedelta(minutes=TTL_MINUTES)
        row = OTP(phone=phone, code="", expires_at=expires_at, failed_attempts=0)
        db.add(row)
        db.flush()

    now = datetime.utcnow()
    # If lock expired, reset counters
    if row.locked_until and row.locked_until <= now:
        row.locked_until = None
        row.failed_attempts = 0

    row.failed_attempts = (row.failed_attempts or 0) + 1
    if row.failed_attempts >= LOCK_THRESHOLD:
        row.locked_until = now + timedelta(minutes=LOCK_MINUTES)
        row.failed_attempts = 0  # reset after locking to count next window
    db.commit()
    return {
        "locked_until": row.locked_until,
        "failed_attempts": row.failed_attempts,
    }

def is_locked(db: Session, phone: str) -> bool:
    from app.models import OTP
    row = db.query(OTP).filter(OTP.phone == phone).first()
    if not row or not row.locked_until:
        return False
    return row.locked_until > datetime.utcnow()

def reset_attempts(db: Session, phone: str) -> None:
    from app.models import OTP
    row = db.query(OTP).filter(OTP.phone == phone).first()
    if row:
        row.failed_attempts = 0
        row.locked_until = None
        db.commit()
