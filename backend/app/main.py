from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from app.core.config import settings
from app.core.logging_conf import configure_logging

configure_logging()
log = logging.getLogger("mahaseel")

app = FastAPI(title=settings.app_name, version="0.1.0", docs_url="/docs", redoc_url="/redoc")

# CORS
origins = settings.cors_origins or []
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if origins else ["*"],  # tighten later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/healthz", tags=["system"])
def healthz():
    log.info("healthz ping", extra={"env": settings.env})
    return {"status": "ok", "env": settings.env}
