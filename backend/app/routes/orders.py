from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import Optional, List

from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.schemas.order import OrderCreate, OrderOut, OrderStatusUpdate
from app.repositories import order as crud_order
from app.models.order import Order

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post("", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    order_in: OrderCreate,
    db: Session = Depends(get_db),
    buyer = Depends(get_current_user)
):
    return crud_order.create_order(db, order_in, buyer.id)


@router.get("/seller", response_model=List[OrderOut])
def list_orders_for_seller(
    db: Session = Depends(get_db),
    user = Depends(require_roles("seller", "admin")),
    seller_id: Optional[int] = Query(None, description="Admin can override the seller id"),
):
    sid = seller_id or user.id
    return crud_order.list_orders_for_seller(db, sid)


@router.patch("/{order_id}/status", response_model=OrderOut)
def update_order_status(
    order_id: int,
    payload: OrderStatusUpdate,
    db: Session = Depends(get_db),
    user = Depends(require_roles("seller", "admin")),
):
    order = db.get(Order, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # ensure the current seller owns the crop (admin bypasses)
    if getattr(user, "role", None) is not None and user.role.value != "admin" and getattr(order.crop, "seller_id", None) != user.id:
        raise HTTPException(status_code=403, detail="Forbidden: cannot update other seller's order")

    return crud_order.update_status(db, order, payload.status)

