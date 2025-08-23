import json, logging, time, uuid
from typing import Callable
from fastapi import FastAPI, Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger("mahaseel")
logging.basicConfig(level=logging.INFO, format="%(message)s")

def _redact(qp: dict) -> dict:
    # never log sensitive fields
    redacted = dict(qp or {})
    for k in list(redacted.keys()):
        if k.lower() in {"password","token","otp","phone"}:
            redacted[k] = "***"
    return redacted

class RequestLogMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable):
        start = time.perf_counter()
        req_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))

        # proceed
        response: Response
        try:
            response = await call_next(request)
        finally:
            dur_ms = round((time.perf_counter() - start) * 1000, 2)
            entry = {
                "request_id": req_id,
                "method": request.method,
                "path": request.url.path,
                "status": getattr(response, "status_code", None),
                "duration_ms": dur_ms,
                "query": _redact(dict(request.query_params)),
            }
            logger.info(json.dumps(entry))

        # expose the id to clients
        if response is not None:
            response.headers["X-Request-ID"] = req_id
        return response

app = FastAPI()
app.add_middleware(RequestLogMiddleware)
