# app/models/social_account.py
from __future__ import annotations
from sqlalchemy import String, Integer, DateTime, func, ForeignKey, UniqueConstraint, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
import enum

class SocialProvider(enum.Enum):
    google = "google"
    facebook = "facebook"

class SocialAccount(Base):
    __tablename__ = "social_accounts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    provider: Mapped[SocialProvider] = mapped_column(Enum(SocialProvider), nullable=False)
    provider_user_id: Mapped[str] = mapped_column(String(128), nullable=False)
    email: Mapped[str | None] = mapped_column(String(255))
    display_name: Mapped[str | None] = mapped_column(String(255))
    avatar_url: Mapped[str | None] = mapped_column(String(1024))
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship(backref="social_accounts")

    __table_args__ = (UniqueConstraint("provider", "provider_user_id", name="uq_social_provider_user"),)
