from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

def error_payload(code: int, err_type: str, message: str):
    return {"error": {"code": code, "type": err_type, "message": message}}

async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    # Handles raise HTTPException(status_code=..., detail="...")
    return JSONResponse(
        status_code=exc.status_code,
        content=error_payload(exc.status_code, "HTTPException", str(exc.detail)),
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # Pydantic validation errors (422)
    return JSONResponse(
        status_code=422,
        content=error_payload(422, "ValidationError", exc.errors().__repr__()),
    )

async def not_found_handler(request: Request, exc: StarletteHTTPException):
    # Explicit 404 (fastapi already routes 404 here)
    return JSONResponse(
        status_code=404,
        content=error_payload(404, "NotFound", "Resource not found"),
    )

async def unhandled_exception_handler(request: Request, exc: Exception):
    # Last-resort 500
    return JSONResponse(
        status_code=500,
        content=error_payload(500, "InternalServerError", "Something went wrong"),
    )

def add_error_handlers(app):
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    # Starlette routes 404 via HTTPException; above handler covers it.
    app.add_exception_handler(Exception, unhandled_exception_handler)
