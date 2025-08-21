from time import time
from typing import Dict, Tuple

# phone -> (otp, expiry_ts)
_store: Dict[str, Tuple[str, float]] = {}
_TTL = 5 * 60  # seconds

def put(phone: str, otp: str) -> None:
    _store[phone] = (otp, time() + _TTL)

def get(phone: str) -> str | None:
    item = _store.get(phone)
    if not item:
        return None
    otp, exp = item
    if time() > exp:
        _store.pop(phone, None)
        return None
    return otp

def pop(phone: str) -> str | None:
    item = _store.pop(phone, None)
    return item[0] if item else None
