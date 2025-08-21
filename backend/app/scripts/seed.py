from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models import User, Role, Crop

def run():
    db: Session = SessionLocal()
    try:
        if not db.query(User).filter(User.phone == "+249000000000").first():
            admin = User(name="Admin", phone="+249000000000", role=Role.admin)
            seller = User(name="Ali", phone="+249912345678", role=Role.seller)
            buyer  = User(name="Sara", phone="+249911112222", role=Role.buyer)
            db.add_all([admin, seller, buyer])
            db.flush()

            crop = Crop(
                name="فول سوداني",
                type="peanut",
                qty=500.0,
                price=25000.0,
                unit="kg",
                state="Khartoum",
                locality="Bahri",
                seller_id=seller.id,
                notes="محصول جديد"
            )
            db.add(crop)

        db.commit()
        print("Seed OK")
    except Exception as e:
        db.rollback()
        print("Seed failed:", e)
        raise
    finally:
        db.close()

if __name__ == "__main__":
    run()
