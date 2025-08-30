from __future__ import annotations
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer
from app.db.base import Base

class OTP(Base):
    __tablename__ = "otps"
    phone = Column(String(32), primary_key=True, index=True, nullable=False)
    code = Column(String(8), nullable=False)
    expires_at = Column(DateTime, nullable=False, index=True)
    # Lockout + attempt tracking
    failed_attempts = Column(Integer, nullable=False, default=0)
    locked_until = Column(DateTime, nullable=True, index=True)
