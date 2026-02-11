from pydantic import BaseModel, EmailStr
from datetime import datetime

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str
    

class UserLogin(BaseModel):
    username: str
    password: str


class OTPVerify(BaseModel):
    email: EmailStr
    otp: str


class UserResponse(BaseModel):
    id: int
    username: str
    email: EmailStr
    is_verified: bool

    class Config:
        orm_mode = True


# ================= ALERT SCHEMAS =================
class AlertBase(BaseModel):
    disaster_type: str
    severity: str
    description: str
    lat: float
    lon: float


class AlertCreate(AlertBase):
    pass


class AlertResponse(AlertBase):
    id: int
    timestamp: datetime

    class Config:
        orm_mode = True
