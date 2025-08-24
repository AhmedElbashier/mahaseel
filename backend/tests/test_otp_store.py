import threading
import time

from app.core import otp_store


def test_otp_expires(monkeypatch):
    otp_store._store.clear()
    monkeypatch.setattr(otp_store, "_TTL", 1)
    otp_store.put("123", "9999")
    assert otp_store.get("123") == "9999"
    time.sleep(1.1)
    assert otp_store.get("123") is None


def test_concurrent_access():
    otp_store._store.clear()
    errors: list[Exception] = []

    def worker() -> None:
        try:
            for _ in range(100):
                otp_store.put("123", "4567")
                otp_store.get("123")
                otp_store.pop("123")
        except Exception as exc:  # pragma: no cover - debugging
            errors.append(exc)

    threads = [threading.Thread(target=worker) for _ in range(10)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert not errors
    assert otp_store.get("123") is None
