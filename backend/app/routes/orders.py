from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.schemas.order import OrderCreate, OrderOut, OrderStatus
from app.repositories import order as crud_order
from app.models.order import Order

router = APIRouter(prefix="/orders", tags=["orders"])

@router.post("", response_model=OrderOut, status_code=201)
def create_order(
    order_in: OrderCreate,
    db: Session = Depends(get_db),
    buyer = Depends(get_current_user)
):
    return crud_order.create_order(db, order_in, buyer.id)

@router.get("/seller/{seller_id}", response_model=list[OrderOut])
def list_orders(
    seller_id: int,
    db: Session = Depends(get_db),
    user=Depends(require_roles("seller", "admin")),
):
    return crud_order.list_orders_for_seller(db, seller_id)

@router.patch("/{order_id}/status", response_model=OrderOut)
def update_order_status(
    order_id: int,
    status: OrderStatus,
    db: Session = Depends(get_db),
    user=Depends(require_roles("seller", "admin")),
):
    order = db.get(Order, order_id)
    if not order:
        raise HTTPException(404, "Order not found")
    if order.crop.seller_id != user.id:
        raise HTTPException(403, "Forbidden: cannot update other seller's order")
    return crud_order.update_status(db, order, status)
