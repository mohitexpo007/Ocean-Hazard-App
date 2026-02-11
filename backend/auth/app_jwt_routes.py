from fastapi import APIRouter
from pydantic import BaseModel
import os, time
from uuid import uuid4
import jwt  # PyJWT

router = APIRouter()

APP_JWT_SECRET = os.getenv("APP_JWT_SECRET", "change-me-please")  # set a strong secret in env
APP_JWT_ALG = "HS256"
APP_JWT_TTL = 60 * 60 * 24 * 7  # 7 days

class IssueJwtIn(BaseModel):
    user_id: str | None = None  # optional; you can omit from the client

@router.post("/auth/anon-jwt")
def issue_anon_jwt(body: IssueJwtIn):
    now = int(time.time())
    sub = body.user_id or str(uuid4())
    payload = {
        "sub": sub,
        "iat": now,
        "exp": now + APP_JWT_TTL,
        "role": "anon",
    }
    token = jwt.encode(payload, APP_JWT_SECRET, algorithm=APP_JWT_ALG)
    print(f"🔐 Issued app JWT for sub={sub}")
    return {"jwt": token}
from fastapi import APIRouter
from pydantic import BaseModel
import os, time
from uuid import uuid4
import jwt  # PyJWT

router = APIRouter()

APP_JWT_SECRET = os.getenv("APP_JWT_SECRET", "change-me-please")  # set a strong secret in env
APP_JWT_ALG = "HS256"
APP_JWT_TTL = 60 * 60 * 24 * 7  # 7 days

class IssueJwtIn(BaseModel):
    user_id: str | None = None  # optional; you can omit from the client

@router.post("/auth/anon-jwt")
def issue_anon_jwt(body: IssueJwtIn):
    now = int(time.time())
    sub = body.user_id or str(uuid4())
    payload = {
        "sub": sub,
        "iat": now,
        "exp": now + APP_JWT_TTL,
        "role": "anon",
    }
    token = jwt.encode(payload, APP_JWT_SECRET, algorithm=APP_JWT_ALG)
    print(f"🔐 Issued app JWT for sub={sub}")
    return {"jwt": token}
