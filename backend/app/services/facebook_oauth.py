# app/services/facebook_oauth.py
import httpx

FB_GRAPH = "https://graph.facebook.com"

async def verify_facebook_access_token(user_access_token: str, app_id: str, app_secret: str) -> dict:
    """
    Validates a Facebook access token and returns basic profile.
    Raises ValueError on invalid token.
    """
    app_token = f"{app_id}|{app_secret}"
    async with httpx.AsyncClient(timeout=10) as client:
        dbg = await client.get(f"{FB_GRAPH}/debug_token", params={
            "input_token": user_access_token,
            "access_token": app_token
        })
        data = dbg.json()
        if not data.get("data", {}).get("is_valid"):
            raise ValueError("invalid facebook token")

        prof = await client.get(f"{FB_GRAPH}/me", params={
            "fields": "id,name,email,picture",
            "access_token": user_access_token
        })
        return prof.json()  # {'id':..., 'name':..., 'email':..., 'picture': {...}}
