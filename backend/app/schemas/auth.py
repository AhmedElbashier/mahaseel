from pydantic import BaseModel, Field, validator


def _normalize_phone(phone: str) -> str:
    """Normalize phone numbers to E.164-like format.

    - Strips whitespace.
    - Ensures numbers include a country code prefix (defaults to +249).
    """
    phone = phone.strip().replace(" ", "")
    if not phone.startswith("+"):
        phone = "+249" + phone
    return phone

class RegisterReq(BaseModel):
    phone: str = Field(min_length=6, max_length=32)
    name: str

    _normalize = validator("phone", allow_reuse=True)(_normalize_phone)

class LoginReq(BaseModel):
    phone: str

    _normalize = validator("phone", allow_reuse=True)(_normalize_phone)

class VerifyReq(BaseModel):
    phone: str
    otp: str = Field(min_length=4, max_length=6)

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
