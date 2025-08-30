from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import relationship
from app.db.base import Base

class FavoriteList(Base):
    __tablename__ = "favorite_lists"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(120), nullable=False)
    is_default = Column(Boolean, nullable=False, server_default="0")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    user = relationship("User", back_populates="favorite_lists")
    items = relationship("FavoriteItem", cascade="all, delete-orphan", back_populates="list")

    __table_args__ = (UniqueConstraint("user_id", "name", name="uq_favorite_list_user_name"),)

class FavoriteItem(Base):
    __tablename__ = "favorite_items"
    id = Column(Integer, primary_key=True)
    list_id = Column(Integer, ForeignKey("favorite_lists.id", ondelete="CASCADE"), nullable=False, index=True)
    crop_id = Column(Integer, ForeignKey("crops.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    list = relationship("FavoriteList", back_populates="items")
    crop = relationship("Crop")

    __table_args__ = (UniqueConstraint("list_id", "crop_id", name="uq_favorite_item_list_crop"),)
