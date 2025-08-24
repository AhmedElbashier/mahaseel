from sqlalchemy import Column, ForeignKey, Integer, UniqueConstraint, Index, text
from app.db.base import Base

class Rating(Base):
    __tablename__ = "ratings"

    id = Column(Integer, primary_key=True, index=True)
    stars = Column(Integer, nullable=False)  # 1–5
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    crop_id = Column(Integer, ForeignKey("crops.id"), nullable=True)

    __table_args__ = (
        UniqueConstraint("buyer_id", "seller_id", "crop_id", name="uix_rating"),
        Index(
            "uix_rating_seller",
            "buyer_id",
            "seller_id",
            unique=True,
            postgresql_where=text("crop_id IS NULL"),
            sqlite_where=text("crop_id IS NULL"),
        ),
    )
