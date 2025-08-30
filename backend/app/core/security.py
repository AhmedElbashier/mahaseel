from typing import Any, Optional

from app.core.token_service import token_service


def create_access_token(
    subject: str | int, role: str, extra: Optional[dict[str, Any]] = None
) -> str:
    return token_service.create_access_token(subject, role, extra)


def create_refresh_token(
    subject: str | int, role: str, extra: Optional[dict[str, Any]] = None
) -> str:
    return token_service.create_refresh_token(subject, role, extra)


def decode_token(token: str) -> dict[str, Any]:
    return token_service.decode(token)


def revoke_token(token: str) -> None:
    token_service.revoke(token)
