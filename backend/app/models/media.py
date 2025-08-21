from sqlalchemy import String, Integer, Boolean, ForeignKey, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
from datetime import datetime

class Media(Base):
    __tablename__ = "media"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    path: Mapped[str] = mapped_column(String(255))  # local path or URL
    is_main: Mapped[bool] = mapped_column(Boolean, default=False)
    width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    height: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped["datetime"] = mapped_column(DateTime(timezone=True), server_default=func.now())

    crop_id: Mapped[int] = mapped_column(ForeignKey("crops.id", ondelete="CASCADE"), index=True)
    crop: Mapped["Crop"] = relationship(back_populates="media")
