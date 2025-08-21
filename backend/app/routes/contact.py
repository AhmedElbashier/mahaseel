from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from urllib.parse import quote

from app.db.session import get_db
from app.models import User, Role

router = APIRouter(prefix="/contact", tags=["contact"])


@router.get("/{seller_id}/whatsapp")
def whatsapp_link(
    seller_id: int,
    text: str = Query("", description="Message to pre-fill"),
    db: Session = Depends(get_db),
):
    seller = db.query(User).get(seller_id)
    if not seller or seller.role != Role.seller:
        raise HTTPException(status_code=404, detail="seller not found")
    url = f"https://wa.me/{seller.phone}?text={quote(text)}"
    return {"url": url}
