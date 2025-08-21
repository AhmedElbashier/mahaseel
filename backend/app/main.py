from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
import logging

from app.core.config import settings
from app.core.logging_conf import configure_logging
from app.api.routes.auth import router as auth_router
from app.api.deps import get_current_user

configure_logging()
log = logging.getLogger("mahaseel")

app = FastAPI(title=settings.app_name, version="0.1.0", docs_url="/docs", redoc_url="/redoc")

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

app.include_router(auth_router)

@app.get("/me", tags=["auth"])
def me(user = Depends(get_current_user)):
    return {"id": user.id, "name": user.name, "phone": user.phone, "role": user.role.value}
