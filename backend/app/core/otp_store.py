from time import time
from threading import Lock
from typing import Dict, Tuple

# phone -> (otp, expiry_ts)
_store: Dict[str, Tuple[str, float]] = {}
_lock = Lock()
_TTL = 5 * 60  # seconds

def put(phone: str, otp: str) -> None:
    with _lock:
        _store[phone] = (otp, time() + _TTL)

def get(phone: str) -> str | None:
    with _lock:
        item = _store.get(phone)
        if not item:
            return None
        otp, exp = item
        if time() > exp:
            _store.pop(phone, None)
            return None
        return otp

def pop(phone: str) -> str | None:
    with _lock:
        item = _store.pop(phone, None)
    return item[0] if item else None
