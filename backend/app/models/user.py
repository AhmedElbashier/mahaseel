from sqlalchemy import String, Integer, DateTime, func, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
import enum
from datetime import datetime  # ✅

class Role(enum.Enum):
    seller = "seller"
    buyer = "buyer"
    admin = "admin"

class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    phone: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    role: Mapped[Role] = mapped_column(Enum(Role), default=Role.seller, nullable=False)
    created_at: Mapped["datetime"] = mapped_column(DateTime(timezone=True), server_default=func.now())

    crops: Mapped[list["Crop"]] = relationship(back_populates="seller", cascade="all, delete-orphan")
    orders_made: Mapped[list["Order"]] = relationship(
        back_populates="buyer", foreign_keys="Order.buyer_id"
    )
