from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from backend import models, schemas, database
import random, smtplib, os
from pydantic import BaseModel
from dotenv import load_dotenv

# ======================================================
# Setup
# ======================================================
router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ======================================================
# FCM Token Registration
# ======================================================
class TokenModel(BaseModel):
    token: str

fcm_tokens = []  # in-memory for now (replace with DB model if needed)

@router.post("/register-token", tags=["Notifications"])
async def register_token(data: TokenModel):
    if data.token not in fcm_tokens:
        fcm_tokens.append(data.token)
    return {"success": True, "token": data.token}

# ======================================================
# OTP Email Helper
# ======================================================
def send_otp_email(email: str, otp: str):
    try:
        load_dotenv()
        GMAIL_USER = os.getenv("GMAIL_USER")
        GMAIL_APP_PASSWORD = os.getenv("GMAIL_APP_PASSWORD")

        if not GMAIL_USER or not GMAIL_APP_PASSWORD:
            print("⚠️ Gmail credentials not loaded from .env")
            return

        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        server.login(GMAIL_USER, GMAIL_APP_PASSWORD)
        message = f"Subject: OTP Verification\n\nYour OTP is {otp}"
        server.sendmail(GMAIL_USER, email, message)
        server.quit()
        print(f"✅ OTP sent to {email}")
    except Exception as e:
        print("❌ Email error:", e)

# ======================================================
# Auth Endpoints
# ======================================================
@router.post("/signup", tags=["Auth"])
def signup(user: schemas.UserCreate, db: Session = Depends(get_db)):
    print("📩 Received signup data:", user.dict())  # debug log

    # Check if email exists
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    # Check if username exists
    db_username = db.query(models.User).filter(models.User.username == user.username).first()
    if db_username:
        raise HTTPException(status_code=400, detail="Username already taken")

    # Generate OTP + hash password
    otp = str(random.randint(100000, 999999))
    hashed_password = pwd_context.hash(user.password)

    new_user = models.User(
        username=user.username,
        email=user.email,
        password=hashed_password,
        otp=otp,
        is_verified=False
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    send_otp_email(user.email, otp)

    return {"success": True, "message": "OTP sent to email. Please verify."}


@router.post("/verify-otp", tags=["Auth"])
def verify_otp(data: schemas.OTPVerify, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == data.email).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if db_user.otp != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    db_user.is_verified = True
    db_user.otp = None
    db.commit()
    db.refresh(db_user)

    return {"success": True, "message": "Account verified successfully"}


@router.post("/login", tags=["Auth"])
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if not pwd_context.verify(user.password, db_user.password):
        raise HTTPException(status_code=400, detail="Incorrect password")

    if not db_user.is_verified:
        raise HTTPException(status_code=403, detail="Account not verified. Please verify OTP.")

    return {"success": True, "message": "Login successful", "user": db_user.username}
