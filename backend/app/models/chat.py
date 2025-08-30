# app/models/chat.py
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text, Enum, Boolean,Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(Integer, primary_key=True, index=True)
    listing_id = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # NEW: normalized pair to enforce uniqueness per listing
    u_lo = Column(Integer, nullable=True, index=True)
    u_hi = Column(Integer, nullable=True, index=True)

    participants = relationship("ConversationParticipant", back_populates="conversation", cascade="all, delete-orphan")
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")

# Optional: also declare a uniqueness index at ORM level (Alembic will create it)
Index("uq_conversation_listing_pair", Conversation.listing_id, Conversation.u_lo, Conversation.u_hi, unique=True)

class ConversationParticipant(Base):
    __tablename__ = "conversation_participants"
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    role = Column(String(10), nullable=False)  # "buyer" | "seller"
    last_read_message_id = Column(Integer, nullable=True)

    conversation = relationship("Conversation", back_populates="participants")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False, index=True)
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    body = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    conversation = relationship("Conversation", back_populates="messages")