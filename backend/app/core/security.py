from typing import Any, Optional

from app.core.token_service import token_service
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


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


def get_password_hash(password: str) -> str:
    """Hash a plain password using bcrypt."""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against a bcrypt hash."""
    if not hashed_password:
        return False
    return pwd_context.verify(plain_password, hashed_password)
