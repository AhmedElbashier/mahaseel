from sqlalchemy.orm import Session
from app.models.order import Order, OrderStatus
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
    return (
        db.query(Order)
        .join(Order.crop)
        .filter(Order.crop.has(seller_id=seller_id))
        .all()
    )

def update_status(db: Session, order: Order, status: OrderStatus):
    order.status = status
    db.commit()
    db.refresh(order)
    return order
