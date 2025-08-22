from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

import logging

import os


from app.core.cors import add_cors
from app.core.errors import add_error_handlers
from app.core.ratelimit import add_rate_limiting


from app.core.config import settings
from app.core.logging_conf import configure_logging
from app.routes.auth import router as auth_router
from app.routes.crops import router as crops_router
from app.routes.media import router as media_router
from app.routes.contact import router as contact_router

from app.api.deps import get_current_user

configure_logging()
log = logging.getLogger("mahaseel")

app = FastAPI(
    title=settings.app_name, version="0.1.0", docs_url="/docs", redoc_url="/redoc"
)
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "../uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/static", StaticFiles(directory=UPLOAD_DIR), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=(settings.cors_origins or ["*"]),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/_routes", tags=["system"])
def list_routes():
    return [getattr(r, "path", None) for r in app.routes]


@app.get("/healthz", tags=["system"])
def healthz():
    log.info("healthz ping", extra={"env": settings.env})
    return {"status": "ok", "env": settings.env}

# hardening
add_cors(app)
add_rate_limiting(app)
add_error_handlers(app)

# routes
app.include_router(auth_router)
app.include_router(crops_router)
app.include_router(media_router)
app.include_router(contact_router)


@app.get("/me", tags=["auth"])
def me(user=Depends(get_current_user)):
    return {
        "id": user.id,
        "name": user.name,
        "phone": user.phone,
        "role": user.role.value,
    }
