from sqlalchemy import Column, Integer, Numeric, String, DateTime, ForeignKey, Enum, Boolean, func
from sqlalchemy.orm import relationship
from app.db.base import Base
import enum

class TxnKind(str, enum.Enum):
    credit = "credit"   # money coming in
    debit = "debit"     # money going out (payouts, fees)

class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)      # positive
    kind = Column(Enum(TxnKind), nullable=False)
    ref = Column(String(64), nullable=True)              # order code, payout id, etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="wallet_transactions")

class PayoutMethod(Base):
    __tablename__ = "payout_methods"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    bank_name = Column(String(120), nullable=False)
    account_name = Column(String(120), nullable=False)
    iban = Column(String(64), nullable=False)
    is_default = Column(Boolean, server_default="false", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="payout_methods")
