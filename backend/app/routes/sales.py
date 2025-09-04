from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional, List

from app.db.session import get_db
from app.api.deps import require_roles
from app.schemas.order import OrderOut  # uses OrderStatus from model inside
from app.models.order import Order, OrderStatus
from app.models.crop import Crop

router = APIRouter(prefix="/sales", tags=["sales"])

@router.get("/orders", response_model=List[OrderOut])
def list_sales_orders(
    db: Session = Depends(get_db),
    seller = Depends(require_roles("seller")),
    status: Optional[OrderStatus] = Query(None),
):
    q = (
        db.query(Order)
        .join(Crop, Crop.id == Order.crop_id)
        .filter(Crop.seller_id == seller.id)
    )
    if status is not None:
        q = q.filter(Order.status == status)
    rows = q.order_by(Order.created_at.desc()).all()
    return rows  # Pydantic will map ORM → OrderOut via from_attributes/orm_mode
