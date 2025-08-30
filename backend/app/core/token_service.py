from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Optional
from uuid import uuid4

from jose import jwt

from app.core.config import settings


class TokenService:
    """Service for creating and managing JWT tokens."""

    def __init__(self) -> None:
        # maps jti -> expiration datetime
        self._revoked: dict[str, datetime] = {}

    # ------------------------------------------------------------------
    # internal helpers
    def _purge(self) -> None:
        """Remove expired entries from the revocation list."""
        now = datetime.now(tz=timezone.utc)
        expired = [jti for jti, exp in self._revoked.items() if exp <= now]
        for jti in expired:
            del self._revoked[jti]

    def _create_token(
        self,
        subject: str | int,
        role: str,
        expires_delta,
        typ: str,
        extra: Optional[dict[str, Any]] = None,
    ) -> str:
        now = datetime.now(tz=timezone.utc)
        jti = str(uuid4())
        payload: dict[str, Any] = {
            "sub": str(subject),
            "iat": int(now.timestamp()),
            "exp": int((now + expires_delta).timestamp()),
            "typ": typ,
            "jti": jti,
            "role": role,
        }
        if extra:
            payload.update(extra)
        return jwt.encode(
            payload, settings.jwt_secret, algorithm=settings.jwt_algorithm
        )

    # ------------------------------------------------------------------
    # public API
    def create_access_token(
        self, subject: str | int, role: str, extra: Optional[dict[str, Any]] = None
    ) -> str:
        return self._create_token(
            subject, role, settings.access_expires, "access", extra
        )

    def create_refresh_token(
        self, subject: str | int, role: str, extra: Optional[dict[str, Any]] = None
    ) -> str:
        return self._create_token(
            subject, role, settings.refresh_expires, "refresh", extra
        )

    def decode(self, token: str) -> dict[str, Any]:
        payload = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
        jti = payload.get("jti")
        if jti and self.is_revoked(jti):
            raise RuntimeError("Token has been revoked")
        return payload

    def revoke(self, token: str) -> None:
        payload = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
        jti = payload.get("jti")
        if not jti:
            return
        exp = datetime.fromtimestamp(payload["exp"], tz=timezone.utc)
        self._revoked[jti] = exp
        self._purge()

    def is_revoked(self, jti: str) -> bool:
        self._purge()
        return jti in self._revoked


# Shared singleton instance
token_service = TokenService()
