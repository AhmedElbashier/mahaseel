from sqlalchemy.orm import Session
from decimal import Decimal
from typing import List
from app.models.wallet import WalletTransaction, PayoutMethod, TxnKind

def get_summary(db: Session, user_id: int):
    # naive version; you can push this to SQL for perf
    q = db.query(WalletTransaction).filter(WalletTransaction.user_id == user_id)
    credits = sum([t.amount for t in q.filter(WalletTransaction.kind == TxnKind.credit).all()], Decimal("0"))
    debits  = sum([t.amount for t in q.filter(WalletTransaction.kind == TxnKind.debit).all()], Decimal("0"))
    balance = credits - debits
    # TODO pending payouts if you track them
    return {"balance": balance, "pending_payouts": Decimal("0"), "total_earnings": credits}

def list_txns(db: Session, user_id: int, page: int, limit: int):
    base = db.query(WalletTransaction).filter(WalletTransaction.user_id == user_id)
    total = base.count()
    items = (base.order_by(WalletTransaction.created_at.desc())
                  .offset((page - 1) * limit).limit(limit).all())
    return total, items

def list_payout_methods(db: Session, user_id: int) -> List[PayoutMethod]:
    return db.query(PayoutMethod).filter(PayoutMethod.user_id == user_id).order_by(PayoutMethod.created_at.desc()).all()

def create_payout_method(db: Session, user_id: int, bank_name: str, account_name: str, iban: str):
    pm = PayoutMethod(user_id=user_id, bank_name=bank_name, account_name=account_name, iban=iban)
    db.add(pm); db.commit(); db.refresh(pm)
    return pm

def delete_payout_method(db: Session, user_id: int, pm_id: int):
    pm = db.query(PayoutMethod).filter(PayoutMethod.id == pm_id, PayoutMethod.user_id == user_id).first()
    if not pm: return False
    db.delete(pm); db.commit()
    return True
