# backend/app/routes/admin.py
import os
from fastapi import APIRouter, Header, HTTPException
from app.scripts import seed as seed_script

router = APIRouter(prefix="/admin", tags=["admin"])

@router.post("/seed")
def run_seed(x_seed_token: str | None = Header(default=None)):
    expected = os.getenv("SEED_TOKEN")
    if not expected or x_seed_token != expected:
        raise HTTPException(status_code=401, detail="unauthorized")
    seed_script.run()
    return {"status": "ok"}
