from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.db.session import get_db
from app.api.deps import get_current_user
from app.schemas.rating import RatingCreate, RatingOut
from app.repositories import rating as crud_rating  # <-- correct import

router = APIRouter(prefix="/ratings", tags=["ratings"])

@router.post("", response_model=RatingOut, status_code=201)
def create_rating(
    rating_in: RatingCreate,
    db: Session = Depends(get_db),
    buyer = Depends(get_current_user),
):
    try:
        return crud_rating.create_rating(db, rating_in, buyer.id)
    except IntegrityError:
        # unique constraint violation: already rated
        raise HTTPException(status_code=400, detail="You already rated this seller/crop")

@router.get("/seller/{seller_id}")
def get_seller_ratings(seller_id: int, db: Session = Depends(get_db)):
    row = crud_rating.get_seller_average(db, seller_id)
    return {
        "avg": round(float(row.avg or 0), 1),
        "count": int(row.count or 0),
    }
