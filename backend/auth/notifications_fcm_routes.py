from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy.orm import Session
from backend import database, models

import firebase_admin
from firebase_admin import credentials, messaging
import os

router = APIRouter()

# ---- Initialize Firebase Admin once ----
if not firebase_admin._apps:
    cred_path = os.getenv("FIREBASE_CREDENTIALS_FILE", "backend/keys/firebase-service-account.json")
    if not os.path.exists(cred_path):
        raise RuntimeError(f"Firebase service account file not found at: {cred_path}")
    firebase_admin.initialize_app(credentials.Certificate(cred_path))

# -------- Pydantic Schemas ----------
class RegisterTokenIn(BaseModel):
    token: str
    user_id: Optional[str] = None
    platform: Optional[str] = "android"

class SendToTokenIn(BaseModel):
    token: str
    title: str
    body: str
    severity: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None

class BroadcastIn(BaseModel):
    title: str
    body: str
    severity: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None

# -------- DB Dependency ----------
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# -------- Endpoints ----------
@router.post("/register-token", tags=["Notifications"])
def register_token(payload: RegisterTokenIn, db: Session = Depends(get_db)):
    print(f"📥 Incoming token: {payload.token}, user_id={payload.user_id}, platform={payload.platform}")

    if not payload.token:
        raise HTTPException(status_code=400, detail="Token is required")

    # Upsert token
    existing = db.query(models.DeviceToken).filter(models.DeviceToken.token == payload.token).first()
    if existing:
        if payload.user_id:
            existing.user_id = payload.user_id
        if payload.platform:
            existing.platform = payload.platform
        db.commit()
        db.refresh(existing)
        return {"success": True, "message": "Token updated", "id": existing.id}

    rec = models.DeviceToken(
        token=payload.token,
        user_id=payload.user_id,
        platform=payload.platform,
    )
    db.add(rec)
    db.commit()
    db.refresh(rec)
    return {"success": True, "message": "Token registered", "id": rec.id}

@router.post("/send-to-token", tags=["Notifications"])
def send_to_token(payload: SendToTokenIn):
    note = messaging.Notification(title=payload.title, body=payload.body)
    data = {}
    if payload.severity:
        data["severity"] = payload.severity
    if payload.lat is not None:
        data["lat"] = str(payload.lat)
    if payload.lon is not None:
        data["lon"] = str(payload.lon)

    message = messaging.Message(
        token=payload.token,
        notification=note,
        data=data,
    )

    try:
        resp = messaging.send(message)
        return {"success": True, "message_id": resp}
    except Exception as e:
        print(f"❌ Error sending notification: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/broadcast", tags=["Notifications"])
def broadcast(payload: BroadcastIn, db: Session = Depends(get_db)):
    tokens: List[str] = [t.token for t in db.query(models.DeviceToken).all()]
    if not tokens:
        raise HTTPException(status_code=400, detail="No device tokens registered")

    note = messaging.Notification(title=payload.title, body=payload.body)
    data = {}
    if payload.severity:
        data["severity"] = payload.severity
    if payload.lat is not None:
        data["lat"] = str(payload.lat)
    if payload.lon is not None:
        data["lon"] = str(payload.lon)

    # Use Multicast
    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=note,
        data=data,
    )
    resp = messaging.send_multicast(message)
    return {"success": True, "success_count": resp.success_count, "failure_count": resp.failure_count}
