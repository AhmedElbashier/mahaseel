from pydantic import BaseModel, Field

class RegisterReq(BaseModel):
    phone: str = Field(min_length=6, max_length=32)
    name: str

class LoginReq(BaseModel):
    phone: str

class VerifyReq(BaseModel):
    phone: str
    otp: str = Field(min_length=4, max_length=6)

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
