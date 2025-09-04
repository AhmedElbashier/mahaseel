from sqlalchemy.orm import Session
from app.models.order import Order, OrderStatus
from app.models.crop import Crop
from app.schemas.order import OrderCreate


def create_order(db: Session, order_in: OrderCreate, buyer_id: int):
    order = Order(
        qty=order_in.qty,
        note=order_in.note,
        crop_id=order_in.crop_id,
        buyer_id=buyer_id,
        status=OrderStatus.new,
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    return order


def list_orders_for_seller(db: Session, seller_id: int):
    # filter by the actual FK on Crop
    return (
        db.query(Order)
        .join(Crop, Crop.id == Order.crop_id)
        .filter(Crop.seller_id == seller_id)
        .order_by(Order.created_at.desc())
        .all()
    )


def update_status(db: Session, order: Order, status: OrderStatus):
    order.status = status
    db.commit()
    db.refresh(order)
    return order

