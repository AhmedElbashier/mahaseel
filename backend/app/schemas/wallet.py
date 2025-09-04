from pydantic import BaseModel, Field
from typing import List, Optional
from decimal import Decimal

class WalletSummary(BaseModel):
    balance: Decimal
    pending_payouts: Decimal
    total_earnings: Decimal

class WalletTxnOut(BaseModel):
    id: int
    amount: Decimal
    kind: str
    ref: Optional[str] = None
    created_at: str

class PayoutMethodCreate(BaseModel):
    bank_name: str = Field(..., min_length=2)
    account_name: str = Field(..., min_length=2)
    iban: str = Field(..., min_length=8)

class PayoutMethodOut(BaseModel):
    id: int
    bank_name: str
    account_name: str
    iban: str
    is_default: bool
    created_at: str
