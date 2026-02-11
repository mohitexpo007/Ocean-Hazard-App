from fastapi import FastAPI, WebSocket, UploadFile, File, Form, Depends, HTTPException
from backend import models, database
from backend.auth.auth_routes import router as auth_router
from backend.auth.report_routes import router as report_router
from backend.auth.notifications_fcm_routes import router as notification_router  # ✅ NEW

from dotenv import load_dotenv
import os
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from backend.auth.chatbot_routes import router as chatbot_router

# 🔹 NEW: for Postgres LISTEN/NOTIFY
import asyncio
import json
import asyncpg

# 🔹 Firebase Admin
import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy.orm import Session

# 🔹 OPTIONAL JWT router (import safely; we’ll mount it later)
try:
    from backend.auth.app_jwt_routes import router as app_jwt_router
except Exception as e:
    app_jwt_router = None
    print("ℹ️ App JWT router not available (skipping):", e)

# ======================================================
# App Setup
# ======================================================
app = FastAPI()

# Routers
app.include_router(report_router, prefix="/citizen", tags=["Citizen Reports"])
app.include_router(auth_router, prefix="/auth", tags=["Auth"])
app.include_router(notification_router, prefix="/notifications", tags=["Notifications"])  # ✅ Mounted
app.include_router(chatbot_router, prefix="/citizen", tags=["Chatbot"])

# ✅ Mount JWT router only if import succeeded
if app_jwt_router is not None:
    app.include_router(app_jwt_router, tags=["AppJWT"])

# Enable CORS so Flutter app can fetch data
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load env variables
load_dotenv()
GMAIL_USER = os.getenv("GMAIL_USER")
GMAIL_APP_PASSWORD = os.getenv("GMAIL_APP_PASSWORD")

# Create database tables
models.Base.metadata.create_all(bind=database.engine)

# ======================================================
# 🔹 Firebase Initialization (safe)
# ======================================================
firebase_initialized = False

@app.on_event("startup")
async def init_firebase():
    global firebase_initialized
    if not firebase_admin._apps:
        cred_path = os.getenv("FIREBASE_CREDENTIALS_FILE", "backend/keys/firebase-service-account.json")
        if os.path.exists(cred_path):
            firebase_admin.initialize_app(credentials.Certificate(cred_path))
            firebase_initialized = True
            print("✅ Firebase Admin initialized")
        else:
            print(f"⚠️ Firebase credentials not found at {cred_path}. Notifications disabled.")

# ======================================================
# 🔹 ALERTS SYSTEM
# ======================================================
class DisasterAlert(BaseModel):
    id: int
    disaster_type: str
    location: str
    severity: str
    timestamp: datetime
    description: str
    lat: float
    lon: float

alerts_db: List[dict] = []
clients: List[WebSocket] = []

@app.post("/alerts/", tags=["Disasters"])
async def create_alert(alert: DisasterAlert):
    new_alert = alert.dict()
    alerts_db.append(new_alert)
    await send_alert_to_clients(new_alert)
    return {"message": "Alert added", "data": new_alert}

@app.get("/alerts/", tags=["Disasters"])
def get_alerts():
    return alerts_db

@app.websocket("/ws/alerts")
async def alerts_ws(websocket: WebSocket):
    await websocket.accept()
    clients.append(websocket)
    try:
        while True:
            await websocket.receive_text()  # keeps connection alive
    except:
        clients.remove(websocket)

async def send_alert_to_clients(alert: dict):
    disconnected = []
    for client in clients:
        try:
            await client.send_json(alert)
        except:
            disconnected.append(client)
    for dc in disconnected:
        clients.remove(dc)

# ======================================================
# 🔹 CITIZEN REPORT SYSTEM
# ======================================================
class HazardReport(BaseModel):
    reportedBy: str
    location: dict   # { "type": "Point", "coordinates": [lon, lat] }
    hazardType: str  # Enum
    severity: str    # Enum
    description: str
    mediaUrl: Optional[str] = None
    mediaType: Optional[str] = "image"

HAZARD_TYPES = ["oil_spill", "flood", "earthquake", "fire", "landslide", "tsunami"]
SEVERITY_LEVELS = ["low", "medium", "high"]

hazard_reports_db: List[dict] = []

@app.post("/reports/", tags=["Citizen Reports"])
async def submit_report(
    reportedBy: str = Form(...),
    hazardType: str = Form(...),
    severity: str = Form(...),
    description: str = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    media: Optional[UploadFile] = File(None)
):
    if hazardType not in HAZARD_TYPES:
        return {"error": f"Invalid hazardType. Allowed: {HAZARD_TYPES}"}
    if severity not in SEVERITY_LEVELS:
        return {"error": f"Invalid severity. Allowed: {SEVERITY_LEVELS}"}

    location = {"type": "Point", "coordinates": [lon, lat]}
    media_url = None
    if media:
        media_url = f"/uploads/{media.filename}"  # TODO: save file properly

    report = HazardReport(
        reportedBy=reportedBy,
        location=location,
        hazardType=hazardType,
        severity=severity,
        description=description,
        mediaUrl=media_url,
        mediaType="image"
    ).dict()

    hazard_reports_db.append(report)

    return {"message": "Report submitted successfully", "data": report}

@app.get("/reports/", tags=["Citizen Reports"])
def get_reports():
    return hazard_reports_db

# ======================================================
# Root endpoint
# ======================================================
@app.get("/")
def root():
    return {"message": "Backend is running"}

# ======================================================
# 🔹 LISTEN/NOTIFY for hazard_report table
# ======================================================
report_clients: list[WebSocket] = []

async def send_report_update(report: dict):
    disconnected = []
    for ws in report_clients:
        try:
            await ws.send_json(report)
        except:
            disconnected.append(ws)
    for dc in disconnected:
        report_clients.remove(dc)

@app.websocket("/citizen/ws/reports")
async def report_ws(websocket: WebSocket):
    await websocket.accept()
    report_clients.append(websocket)
    try:
        while True:
            await websocket.receive_text()
    except:
        report_clients.remove(websocket)

async def listen_to_postgres():
    conn = await asyncpg.connect(
        "postgresql://postgres.viuasxnhzbzitdlgjkqm:Mohit%402004@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres",
        statement_cache_size=0
    )
    await conn.add_listener("hazard_changes", pg_notify_handler)

def pg_notify_handler(conn, pid, channel, payload):
    data = json.loads(payload)
    asyncio.create_task(send_report_update(data))

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(listen_to_postgres())

alerts_db: List[dict] = [
    {
        "id": 1,
        "disaster_type": "flood",
        "location": "Mumbai",
        "severity": "high",
        "timestamp": datetime.utcnow(),
        "description": "Heavy flooding reported in Mumbai.",
        "lat": 19.0760,
        "lon": 72.8777,
    },
    {
        "id": 2,
        "disaster_type": "cyclone",
        "location": "Chennai",
        "severity": "medium",
        "timestamp": datetime.utcnow(),
        "description": "Cyclone alert near Chennai coast.",
        "lat": 13.0827,
        "lon": 80.2707,
    },
    {
        "id": 3,
        "disaster_type": "earthquake",
        "location": "Kolkata",
        "severity": "low",
        "timestamp": datetime.utcnow(),
        "description": "Minor tremors felt in Kolkata.",
        "lat": 22.5726,
        "lon": 88.3639,
    },
    {
        "id": 4,
        "disaster_type": "flood",
        "location": "Butibori, Nagpur",
        "severity": "medium",
        "timestamp": "2025-09-26T00:00:00Z",
        "description": "Flooding reported near Butibori, Nagpur.",
        "lat": 20.9392098,
        "lon": 79.0100148
    }

]

# ... (everything from your provided main.py above remains the same)

import praw
from transformers import pipeline

# ======================================================
# 🔹 Reddit Scraper Logic
# ======================================================

# Reddit API credentials (put in .env for safety)
REDDIT_CLIENT_ID = os.getenv("REDDIT_CLIENT_ID", "IUbK1kUWNhoU4sXlKjy7_g")
REDDIT_CLIENT_SECRET = os.getenv("REDDIT_CLIENT_SECRET", "SmABznSzUFtBMu-VaCFhGPpOIh_xhQ")
REDDIT_USER_AGENT = os.getenv("REDDIT_USER_AGENT", "disaster-alerts-app by mohit")

reddit = praw.Reddit(
    client_id=REDDIT_CLIENT_ID,
    client_secret=REDDIT_CLIENT_SECRET,
    user_agent=REDDIT_USER_AGENT,
)

hazard_keywords = ["earthquake", "flood", "cyclone", "tsunami", "landslide", "disaster"]
classifier = pipeline("text-classification", model="distilbert-base-uncased-finetuned-sst-2-english")

def is_hazard_post(text: str) -> bool:
    text_lower = text.lower()
    if not any(word in text_lower for word in hazard_keywords):
        return False
    result = classifier(text)[0]
    return result["score"] > 0.60  # accept strong positive/negative

def compute_score(likes, comments, date_obj: datetime):
    base_score = 0.6 * likes + 0.4 * comments
    now = datetime.utcnow()
    age_hours = (now - date_obj).total_seconds() / 3600.0
    decay = pow(2.718, -0.05 * age_hours)
    return base_score * decay

class ScrapedReport(BaseModel):
    text: str
    author: str
    date: datetime
    likes: int
    replies: int
    url: str
    score: float

@app.post("/scraped/reports", tags=["Scraped Reports"])
async def fetch_and_store_reports():
    """Scrapes Reddit for hazard posts and inserts them into Supabase"""
    subreddit = reddit.subreddit("all")
    query = " OR ".join(hazard_keywords) + ' "Indian Ocean"'
    print(f"🔎 Running query: {query}")

    inserted = 0
    conn = await asyncpg.connect(
        "postgresql://postgres.viuasxnhzbzitdlgjkqm:Mohit%402004@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres",
        statement_cache_size=0
    )

    async with conn.transaction():
        for submission in subreddit.search(query, sort="new", limit=20):
            text = submission.title + " " + (submission.selftext or "")
            if is_hazard_post(text):
                created = datetime.utcfromtimestamp(submission.created_utc)
                score = compute_score(submission.score, submission.num_comments, created)
                await conn.execute("""
                    INSERT INTO scraped_reports (text, author, date, likes, retweets, replies, url, score)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                """,
                    submission.title,
                    str(submission.author),
                    created.replace(tzinfo=None),
                    submission.score,
                    0,  # no retweets on Reddit
                    submission.num_comments,
                    submission.url,
                    score
                )
                inserted += 1
                print("🟢 Inserted:", submission.title[:80])

    await conn.close()
    return {"message": f"Inserted {inserted} reports"}

@app.get("/scraped/reports", tags=["Scraped Reports"])
async def get_scraped_reports():
    """Fetch top scraped hazard posts"""
    conn = await asyncpg.connect(
        "postgresql://postgres.viuasxnhzbzitdlgjkqm:Mohit%402004@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres",
        statement_cache_size=0
    )
    rows = await conn.fetch("""
        SELECT * FROM scraped_reports 
        ORDER BY score DESC, date DESC 
        LIMIT 50
    """)
    await conn.close()
    return [dict(row) for row in rows]
