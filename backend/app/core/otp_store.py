# app/core/otp_store.py
from time import time
from threading import Lock
from typing import Dict, Tuple, Optional

# default TTL for OTPs (seconds)
_TTL = 5 * 60

# phone -> (otp, expiry_ts)
_store: Dict[str, Tuple[str, float]] = {}
_lock = Lock()

def put(phone: str, otp: str, ttl: int = _TTL) -> None:
    with _lock:
        _store[phone] = (otp, time() + ttl)

def get(phone: str) -> Optional[str]:
    with _lock:
        item = _store.get(phone)
        if not item:
            return None
        otp, exp = item
        if time() > exp:
            _store.pop(phone, None)
            return None
        return otp

def pop(phone: str) -> Optional[str]:
    with _lock:
        item = _store.pop(phone, None)
    return item[0] if item else None
