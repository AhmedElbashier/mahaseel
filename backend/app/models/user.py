from __future__ import annotations

import enum
from datetime import datetime
from typing import TYPE_CHECKING
from typing import Optional

from sqlalchemy import String, Integer, DateTime, func, Enum, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from .crop import Crop
    from .order import Order


class Role(enum.Enum):
    seller = "seller"
    buyer = "buyer"
    admin = "admin"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    phone: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    phone_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    role: Mapped[Role] = mapped_column(Enum(Role), default=Role.seller, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships (use forward refs as strings)
    crops: Mapped[list["Crop"]] = relationship(
        back_populates="seller", cascade="all, delete-orphan"
    )
    orders_made: Mapped[list["Order"]] = relationship(
        back_populates="buyer", foreign_keys="Order.buyer_id"
    )

    favorite_lists = relationship(
        "FavoriteList", cascade="all, delete-orphan", back_populates="user"
    )
    saved_searches = relationship(
        "SavedSearch", back_populates="user", cascade="all,delete-orphan"
    )
    wallet_transactions = relationship(
        "WalletTransaction", back_populates="user", cascade="all,delete-orphan"
    )
    payout_methods = relationship(
        "PayoutMethod", back_populates="user", cascade="all,delete-orphan"
    )
    # Note: removed relationships to undefined models (Ad, ChatMessage, CMSPage, SecurityLog,
    # Sale, PayoutRequest, Notification, APIKey) and relationships that referenced
    # non-existent counterparts on the target models (ratings_*, orders_received).
    password_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    two_fa_enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    two_fa_secret: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    last_login: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    last_ip: Mapped[Optional[str]] = mapped_column(String(45), nullable=True)  # IPv6 max length
    locale: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)  # e.g. 'en', 'fr'
    timezone: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)  # e.g. 'UTC', 'America/New_York'
    profile_picture: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)  # URL or file path
    bio: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    website: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)  # URL
    social_links: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)  # JSON string of links
    email: Mapped[Optional[str]] = mapped_column(String(100), unique=True, index=True, nullable=True)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_premium: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    premium_expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    receive_newsletter: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    receive_sms_alerts: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    receive_app_notifications: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    marketing_consent: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    terms_accepted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    terms_accepted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    privacy_accepted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    privacy_accepted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True) 
    deleted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    # Add other fields/relationships as needed
