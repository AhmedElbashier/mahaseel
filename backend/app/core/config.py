# backend/app/core/config.py
from __future__ import annotations
import os
from datetime import timedelta
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import AnyHttpUrl, field_validator

class Settings(BaseSettings):
    app_name: str = "mahaseel"
    env: str = "dev"
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    jwt_secret: str = "CHANGE_ME_DEV_ONLY"
    jwt_algorithm: str = "HS256"
    jwt_access_minutes: int = 60

    # Host run default (localhost)
    database_url: str = "postgresql+psycopg://mahaseel:mahaseel@localhost:5432/mahaseel"

    # Accept either a list or a comma-separated string from env
    cors_origins: List[AnyHttpUrl] | List[str] | str = []

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=False,
        extra="ignore",         # <-- ignore PGHOST, etc.
        env_ignore_empty=True,  # <-- treat empty strings as "unset"
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
    def effective_database_url(self) -> str:
        # Prefer docker DSN in containers, else localhost for host runs
        return os.getenv("DATABASE_URL_DOCKER", self.database_url)

    def validate_for_runtime(self) -> None:
        if not self.is_dev and self.jwt_secret == "CHANGE_ME_DEV_ONLY":
            raise RuntimeError("Unsafe JWT secret in non-dev environment")

settings = Settings()
