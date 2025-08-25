# app/services/google_oauth.py
from google.oauth2 import id_token
from google.auth.transport import requests

def verify_google_id_token(id_tok: str, audience: str) -> dict:
    """
    Validates a Google ID token and returns its claims.
    Raises ValueError on invalid token.
    """
    info = id_token.verify_oauth2_token(id_tok, requests.Request(), audience)
    return info  # contains sub, email, name, picture (if available)
