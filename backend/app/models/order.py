from sqlalchemy import Integer, Float, ForeignKey, Enum, DateTime, func, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
import enum
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from datetime import datetime
    from .crop import Crop
    from .user import User


class OrderStatus(enum.Enum):
    new = "new"
    chatting = "chatting"
    agreed = "agreed"
    closed = "closed"


class Order(Base):
    __tablename__ = "orders"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    qty: Mapped[float] = mapped_column(Float)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus), default=OrderStatus.new, nullable=False
    )
    created_at: Mapped["datetime"] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped["datetime"] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    crop_id: Mapped[int] = mapped_column(
        ForeignKey("crops.id", ondelete="CASCADE"), index=True
    )
    buyer_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )

    crop: Mapped["Crop"] = relationship(back_populates="orders")
    buyer: Mapped["User"] = relationship(back_populates="orders_made")
