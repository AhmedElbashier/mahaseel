# app/schemas/chat.py
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class MessageOut(BaseModel):
    id: int
    conversation_id: int
    sender_id: int
    body: str
    created_at: datetime

    class Config:
        from_attributes = True

class ConversationOut(BaseModel):
    id: int
    listing_id: Optional[int]
    last_message: Optional[MessageOut] = None
    unread_count: int

    class Config:
        from_attributes = True

class SendMessageIn(BaseModel):
    conversation_id: int
    body: str

class CreateConversationIn(BaseModel):
    other_user_id: int
    listing_id: Optional[int] = None
    role: str  # "buyer" or "seller" for the current user