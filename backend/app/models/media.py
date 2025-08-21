from datetime import datetime
from sqlalchemy import (
    String, Integer, Boolean, ForeignKey, DateTime, func, Index
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.crop import Crop
from app.db.base import Base


class Media(Base):
    __tablename__ = "media"

    id: Mapped[int]= mapped_column(Integer,primary_key=True)
    path: Mapped[str] = mapped_column(String(512))
    is_main: Mapped[bool] = mapped_column(Boolean,default=False,index=True)
    width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    height: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at : Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    crop_id: Mapped[int] = mapped_column(ForeignKey("crops.id", ondelete="CASCADE"),index=True)
    crop: Mapped[Crop] = relationship(back_populates="media")


    #Optional
    __table_args__ = (
        Index(
            "uq_media_one_per_crop",
            "crop_id",
            unique=True,
            postgresql_where=(is_main==True)
        ),
    )

    def __repr__(self) -> str:
        return f"Media id = {self.id}, crop_id={self.crop_id} main={self.is_main}"
