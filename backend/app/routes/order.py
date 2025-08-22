from fastapi import APIRouter, Depends, HTTPException, Body, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.session import get_db
from app.models import Order, OrderStatus, Crop
from app.schemas.order import OrderCreate, OrderOut
from app.api.deps import get_current_user
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.core.ratelimit import limiter

router = APIRouter(prefix="/orders", tags=["orders"])

@limiter.limit("60/minute")
@router.post("", response_model=OrderOut, status_code=201)
def create_order(
    data: OrderCreate = Body(...),
    db: Session = Depends(get_db),
    user = Depends(get_current_user),  # you can enforce buyer role later
):
    crop = db.query(Crop).get(data.crop_id)
    if not crop:
        raise HTTPException(status_code=404, detail="crop not found")

    order = Order(
        qty=float(data.qty),
        note=data.note,
        status=OrderStatus[data.status.name],  # map schema enum to model enum
        crop_id=data.crop_id,
        buyer_id=data.buyer_id,
    )
    db.add(order); db.commit(); db.refresh(order)
    return order

@limiter.limit("60/minute")
@router.get("", response_model=List[OrderOut])
def list_orders(
    db: Session = Depends(get_db),
    crop_id: Optional[int] = Query(default=None),
    buyer_id: Optional[int] = Query(default=None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    q = db.query(Order)
    if crop_id: q = q.filter(Order.crop_id == crop_id)
    if buyer_id: q = q.filter(Order.buyer_id == buyer_id)
    return q.order_by(Order.id.desc()).offset(offset).limit(limit).all()

@limiter.limit("60/minute")
@router.get("/{order_id}", response_model=OrderOut)
def get_order(order_id: int, db: Session = Depends(get_db)):
    o = db.query(Order).get(order_id)
    if not o:
        raise HTTPException(status_code=404, detail="order not found")
    return o
