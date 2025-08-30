# app/api/routes/chat.py
from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.orm import Session,aliased
from sqlalchemy.exc import IntegrityError
from typing import List, Optional
from sqlalchemy import desc, and_

from app.db.session import get_db
from app.api.deps import get_current_user  # your auth
from app.models.chat import Conversation, ConversationParticipant, Message
from app.schemas.chat import ConversationOut, SendMessageIn, MessageOut, CreateConversationIn
from sqlalchemy import desc, func, and_, or_
from pydantic import BaseModel

router = APIRouter(prefix="/chat", tags=["chat"])

class SendMessageIn(BaseModel):
    body: str

@router.get("/conversations", response_model=List[ConversationOut])
def list_conversations(
    scope: str = Query("all", pattern="^(all|buying|selling)$"),
    db: Session = Depends(get_db),
    user = Depends(get_current_user),
):
    me_id = int(user.id)

    # Base query: conversations where I am a participant
    CP = aliased(ConversationParticipant)
    q = (
        db.query(Conversation)
        .join(CP, CP.conversation_id == Conversation.id)
        .filter(CP.user_id == me_id)
        .order_by(desc(Conversation.updated_at))
    )

    # Optional “scope” filter using my role in that conversation
    if scope == "buying":
        q = q.filter(CP.role == "buyer")
    elif scope == "selling":
        q = q.filter(CP.role == "seller")

    # Build response with last message + (optional) unread count (0 for now)
    convs = q.all()
    out: List[ConversationOut] = []
    for c in convs:
        last_msg = (
            db.query(Message)
            .filter(Message.conversation_id == c.id)
            .order_by(desc(Message.created_at))
            .first()
        )
        out.append(
            ConversationOut(
                id=c.id,
                listing_id=c.listing_id,
                last_message=MessageOut.model_validate(last_msg) if last_msg else None,
                unread_count=0,  # implement unread later if you want
            )
        )
    return out



@router.post("/conversations", response_model=ConversationOut, status_code=201)
def create_conversation(
    data: CreateConversationIn,
    db: Session = Depends(get_db),
    user = Depends(get_current_user),
):
    me_id = int(user.id)
    other_id = int(data.other_user_id)

    # 1) Self-chat is not allowed inside the same conversation
    if other_id == me_id:
        raise HTTPException(status_code=400, detail="cannot start a conversation with yourself")

    # 2) Look for an existing conversation for (listing_id, me, other)
    CP1 = aliased(ConversationParticipant)
    CP2 = aliased(ConversationParticipant)

    q = (
        db.query(Conversation)
        .join(CP1, and_(CP1.conversation_id == Conversation.id, CP1.user_id == me_id))
        .join(CP2, and_(CP2.conversation_id == Conversation.id, CP2.user_id == other_id))
        .filter(Conversation.listing_id == data.listing_id)
        .order_by(desc(Conversation.updated_at))
    )
    existing = q.first()
    if existing:
        last_msg = (
            db.query(Message)
            .filter(Message.conversation_id == existing.id)
            .order_by(desc(Message.created_at))
            .first()
        )
        return ConversationOut(
            id=existing.id,
            listing_id=existing.listing_id,
            last_message=MessageOut.model_validate(last_msg) if last_msg else None,
            unread_count=0,
        )

    # 3) Create new conversation with normalized pair (optional but recommended)
    u_lo, u_hi = (me_id, other_id) if me_id < other_id else (other_id, me_id)
    c = Conversation(listing_id=data.listing_id, u_lo=u_lo, u_hi=u_hi)
    db.add(c)
    db.flush()  # get c.id

    # 4) Upsert participants (idempotent helper)
    def ensure_participant(conv_id: int, uid: int, role: str):
        exists = (
            db.query(ConversationParticipant)
            .filter_by(conversation_id=conv_id, user_id=uid)
            .first()
        )
        if not exists:
            db.add(
                ConversationParticipant(
                    conversation_id=conv_id,
                    user_id=uid,
                    role=role,
                )
            )

    # The current user's role is data.role; the other gets the opposite
    ensure_participant(c.id, me_id, data.role)
    ensure_participant(c.id, other_id, "seller" if data.role == "buyer" else "buyer")

    try:
        db.commit()
    except IntegrityError:
        # If another request created the same convo in parallel, fetch it.
        db.rollback()
        existing = (
            db.query(Conversation)
            .join(CP1, and_(CP1.conversation_id == Conversation.id, CP1.user_id == me_id))
            .join(CP2, and_(CP2.conversation_id == Conversation.id, CP2.user_id == other_id))
            .filter(Conversation.listing_id == data.listing_id)
            .order_by(desc(Conversation.updated_at))
            .first()
        )
        if not existing:
            raise
        last_msg = (
            db.query(Message)
            .filter(Message.conversation_id == existing.id)
            .order_by(desc(Message.created_at))
            .first()
        )
        return ConversationOut(
            id=existing.id,
            listing_id=existing.listing_id,
            last_message=MessageOut.model_validate(last_msg) if last_msg else None,
            unread_count=0,
        )

    db.refresh(c)
    return ConversationOut(
        id=c.id,
        listing_id=c.listing_id,
        last_message=None,
        unread_count=0,
    )

@router.post("/conversations/{cid}/messages", response_model=MessageOut, status_code=201)
def send_message(
    cid: int = Path(..., ge=1),
    data: SendMessageIn = ...,
    db: Session = Depends(get_db),
    user = Depends(get_current_user),
):
    # 1) ensure the conversation exists
    convo = db.query(Conversation).filter(Conversation.id == cid).first()
    if not convo:
        raise HTTPException(status_code=404, detail="conversation not found")

    # 2) ensure the user is a participant
    is_participant = db.query(ConversationParticipant).filter_by(
        conversation_id=cid, user_id=int(user.id)
    ).first()
    if not is_participant:
        raise HTTPException(status_code=403, detail="not a participant")

    # 3) create message
    msg = Message(conversation_id=cid, sender_id=int(user.id), body=data.body.strip())
    db.add(msg)

    # bump last-updated
    convo.updated_at = func.now()

    db.commit()
    db.refresh(msg)
    return MessageOut.model_validate(msg)


@router.get("/conversations/{cid}/messages", response_model=List[MessageOut])
def list_messages(
    cid: int = Path(..., ge=1),
    limit: int = Query(30, ge=1, le=200),
    before_id: Optional[int] = Query(None, ge=1),
    db: Session = Depends(get_db),
    user = Depends(get_current_user),
):
    me_id = int(user.id)

    # Ensure conversation exists & I am a participant
    convo = db.query(Conversation).filter(Conversation.id == cid).first()
    if not convo:
        raise HTTPException(status_code=404, detail="conversation not found")

    is_participant = db.query(ConversationParticipant).filter_by(
        conversation_id=cid, user_id=me_id
    ).first()
    if not is_participant:
        raise HTTPException(status_code=403, detail="not a participant")

    q = db.query(Message).filter(Message.conversation_id == cid)

    if before_id:
        # paginate older messages
        q = q.filter(Message.id < before_id)

    # Load newest-first, then reverse to chronological for UI
    rows = (
        q.order_by(desc(Message.id))
         .limit(limit)
         .all()
    )
    rows = list(reversed(rows))
    return [MessageOut.model_validate(m) for m in rows]
