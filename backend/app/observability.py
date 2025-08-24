import json
import logging
import time
from typing import Optional

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger("mahaseel")
# Configure once in your main; safe here if you don't configure elsewhere.
logging.basicConfig(level=logging.INFO, format="%(message)s")

SENSITIVE_KEYS = {"password", "token", "otp", "phone"}

def _redact_qp(qp: dict) -> dict:
    out = dict(qp or {})
    for k in list(out.keys()):
        if k.lower() in SENSITIVE_KEYS:
            out[k] = "***"
    return out

class RequestLogMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response: Optional[Response] = None
        status: int = 0
        try:
            response = await call_next(request)
            status = getattr(response, "status_code", 200)
            return response
        except Exception:
            status = 500
            logger.exception("unhandled exception while handling request")
            raise
        finally:
            duration_ms = (time.perf_counter() - start) * 1000.0
            log = {
                "request_id": request.headers.get("X-Request-ID"),
                "method": request.method,
                "path": request.url.path,
                "status": status,
                "duration_ms": round(duration_ms, 2),
                "query": _redact_qp(dict(request.query_params)),
            }
            logger.info(json.dumps(log, ensure_ascii=False))


#app = FastAPI()
#app.add_middleware(RequestLogMiddleware)
