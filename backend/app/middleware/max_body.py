# app/middleware/max_body.py
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import PlainTextResponse

class MaxBodySizeMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, max_body_size: int = 10 * 1024 * 1024):  # 10MB
        super().__init__(app)
        self.max_body_size = max_body_size

    async def dispatch(self, request: Request, call_next):
        if int(request.headers.get("content-length", "0") or 0) > self.max_body_size:
            return PlainTextResponse("Payload too large", status_code=413)
        return await call_next(request)
