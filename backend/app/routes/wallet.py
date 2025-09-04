from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.schemas.wallet import WalletSummary, WalletTxnOut, PayoutMethodCreate, PayoutMethodOut
from app.schemas.common import Paginated
from app.repositories.wallet import get_summary, list_txns, list_payout_methods, create_payout_method, delete_payout_method

router = APIRouter(prefix="/wallet", tags=["wallet"])

@router.get("/summary", response_model=WalletSummary)
def wallet_summary(db: Session = Depends(get_db), user=Depends(get_current_user)):
    s = get_summary(db, user.id)
    return WalletSummary(**s)

@router.get("/transactions", response_model=Paginated[WalletTxnOut])
def wallet_transactions(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100)
):
    total, rows = list_txns(db, user.id, page, limit)
    items = [WalletTxnOut(
        id=r.id, amount=r.amount, kind=r.kind.value, ref=r.ref, created_at=r.created_at.isoformat()
    ) for r in rows]
    return {"items": items, "page": page, "limit": limit, "total": total}

@router.get("/payout-methods", response_model=List[PayoutMethodOut])
def payout_methods(db: Session = Depends(get_db), seller=Depends(require_roles("seller"))):
    rows = list_payout_methods(db, seller.id)
    return [PayoutMethodOut(
        id=r.id, bank_name=r.bank_name, account_name=r.account_name, iban=r.iban,
        is_default=r.is_default, created_at=r.created_at.isoformat()
    ) for r in rows]

@router.post("/payout-methods", response_model=PayoutMethodOut, status_code=status.HTTP_201_CREATED)
def add_payout_method(payload: PayoutMethodCreate, db: Session = Depends(get_db), seller=Depends(require_roles("seller"))):
    r = create_payout_method(db, seller.id, payload.bank_name, payload.account_name, payload.iban)
    return PayoutMethodOut(
        id=r.id, bank_name=r.bank_name, account_name=r.account_name, iban=r.iban,
        is_default=r.is_default, created_at=r.created_at.isoformat()
    )

@router.delete("/payout-methods/{pm_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_payout_method(pm_id: int, db: Session = Depends(get_db), seller=Depends(require_roles("seller"))):
    ok = delete_payout_method(db, seller.id, pm_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Not found")
    return
