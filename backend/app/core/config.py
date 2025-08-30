# backend/app/core/config.py
from __future__ import annotations
import os
from datetime import timedelta
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import AnyHttpUrl, Field, field_validator


def _normalize_db_url(url: str) -> str:
    if not url:
        return url
    url = url.strip()
    # keep if already using postgresql+psycopg://
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+psycopg://", 1)
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+psycopg://", 1)
    return url


class Settings(BaseSettings):
    app_name: str = "mahaseel"
    env: str = "dev"
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    jwt_secret: str = Field(..., env="JWT_SECRET")
    jwt_algorithm: str = "HS256"
    jwt_access_minutes: int = 15
    jwt_refresh_days: int = 7

    google_client_id: str = ""
    fb_app_id: str = ""
    fb_app_secret: str = ""

    # Local default (host-run)
    database_url: str = "postgresql+psycopg://mahaseel:mahaseel@localhost:5432/mahaseel"

    # Accept either a list or a comma-separated string from env
    cors_origins: List[AnyHttpUrl] | List[str] | str = [
        "https://app.example.com",
        "https://admin.example.com",
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=False,
        extra="ignore",
        env_ignore_empty=True,
    )

    @field_validator("cors_origins", mode="before")
    @classmethod
    def split_cors(cls, v):
        if isinstance(v, str):
            return [s.strip() for s in v.split(",") if s.strip()]
        return v

    @property
    def is_dev(self) -> bool:
        return self.env.lower() == "dev"

    @property
    def access_expires(self) -> timedelta:
        return timedelta(minutes=self.jwt_access_minutes)

    @property
    def refresh_expires(self) -> timedelta:
        return timedelta(days=self.jwt_refresh_days)

    @property
    def effective_database_url(self) -> str:
        """
        Priority:
          1) DATABASE_URL (Render/Railway standard)
          2) DATABASE_URL_DOCKER (your compose/k8s override)
          3) self.database_url (local default)
        """
        raw = (
            os.getenv("DATABASE_URL")
            or os.getenv("DATABASE_URL_DOCKER")
            or self.database_url
        )
        return raw

    @property
    def sqlalchemy_url(self) -> str:
        """The normalized URL you should hand to SQLAlchemy/Alembic."""
        return _normalize_db_url(self.effective_database_url)

    def validate_for_runtime(self) -> None:
        if not self.jwt_secret:
            raise RuntimeError("JWT secret is not configured")


settings = Settings()
