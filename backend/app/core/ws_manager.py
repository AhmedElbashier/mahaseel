# app/core/ws_manager.py
from typing import Dict, Set
from fastapi import WebSocket

class WSManager:
    def __init__(self):
        self.rooms: Dict[str, Set[WebSocket]] = {}

    async def connect(self, room: str, ws: WebSocket):
        await ws.accept()
        self.rooms.setdefault(room, set()).add(ws)

    def disconnect(self, room: str, ws: WebSocket):
        if room in self.rooms and ws in self.rooms[room]:
            self.rooms[room].remove(ws)
            if not self.rooms[room]:
                self.rooms.pop(room, None)

    async def broadcast(self, room: str, data: dict):
        for ws in list(self.rooms.get(room, [])):
            await ws.send_json(data)

ws_manager = WSManager()