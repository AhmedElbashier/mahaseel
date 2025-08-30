# app/api/routes/ws.py
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from app.api.deps import get_current_user # parse token & auth for WS
from app.core.ws_manager import ws_manager


router = APIRouter()


@router.websocket("/ws/chat/{conversation_id}")
async def chat_ws(websocket: WebSocket, conversation_id: int, user = Depends(get_current_user)):
    room = f"conv:{conversation_id}"
    await ws_manager.connect(room, websocket)
    try:
        while True:
            data = await websocket.receive_json()
        # Expect {"type": "typing"|"message"|"read", ...}
            await ws_manager.broadcast(room, {"from": user.id, **data})
    except WebSocketDisconnect:
        ws_manager.disconnect(room, websocket)