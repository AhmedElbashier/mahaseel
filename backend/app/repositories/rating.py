from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError

from app.models.rating import Rating
from app.schemas.rating import RatingCreate

def create_rating(db: Session, rating_in: RatingCreate, buyer_id: int):
    rating = Rating(
        stars=rating_in.stars,
        crop_id=rating_in.crop_id,
        buyer_id=buyer_id,
        seller_id=rating_in.seller_id,
    )
    db.add(rating)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise
    db.refresh(rating)
    return rating

def get_seller_average(db: Session, seller_id: int):
    row = db.query(
        func.avg(Rating.stars).label("avg"),
        func.count(Rating.id).label("count"),
    ).filter(Rating.seller_id == seller_id).first()
    return row  # row.avg (nullable), row.count
