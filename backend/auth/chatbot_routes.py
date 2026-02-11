from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import text as sql_text
from backend import database
import requests
import json
import os
import re
from typing import List, Dict, Any, Optional, Tuple

router = APIRouter()

# ==============================
# Input/Output models
# ==============================
class ChatRequest(BaseModel):
    user_id: str
    message: str
    lat: Optional[float] = None
    lon: Optional[float] = None

class ChatResponse(BaseModel):
    reply: str
    source: str   # "predefined", "faq" (legacy), "news", "citizen_report", "fallback"

# ==============================
# Predefined Q&A store
# You can keep this here OR put them into faqs.json (see loader below)
# Each item can have:
#  - q: canonical question (string)
#  - a: answer (string)
#  - keywords: optional list of strong triggers (e.g., ["flood", "safety"])
# ==============================

PREDEFINED_QA: List[Dict[str, Any]] = [
    {
        "q": "what to do during flood",
        "a": "Move to higher ground immediately. Avoid walking or driving through flood waters.",
        "keywords": ["flood", "water", "river", "inundation", "overflow"]
    },
    {
        "q": "cyclone safety",
        "a": "Stay indoors, keep an emergency kit ready, secure loose items, and follow official alerts.",
        "keywords": ["cyclone", "hurricane", "storm", "winds", "landfall"]
    },
    {
        "q": "tsunami safety",
        "a": "If you feel a coastal earthquake, move to high ground immediately and stay away from the shore.",
        "keywords": ["tsunami", "sea wave", "seismic", "earthquake", "coast"]
    },
    # 👉 Add as many as you like
]

# Optional: load/merge from ./faqs.json if present
# faqs.json expected shape: [{"q":"...", "a":"...", "keywords":["..."]}, ...]
_FAQS_PATH = os.path.join(os.path.dirname(__file__), "faqs.json")
if os.path.exists(_FAQS_PATH):
    try:
        with open(_FAQS_PATH, "r", encoding="utf-8") as f:
            loaded = json.load(f)
            # merge/extend while avoiding duplicates by canonical 'q'
            known = {item["q"].strip().lower(): item for item in PREDEFINED_QA}
            for item in loaded:
                key = item.get("q", "").strip().lower()
                if key and key not in known:
                    PREDEFINED_QA.append(item)
    except Exception:
        # If file is bad, just ignore and keep in-code defaults
        pass

# ==============================
# Text normalization & matching
# ==============================

_PUNCT_RE = re.compile(r"[^\w\s]")

def normalize(s: str) -> str:
    # lower, remove punctuation, collapse spaces
    s = s.casefold()
    s = _PUNCT_RE.sub(" ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def token_set(text: str) -> set:
    return set(normalize(text).split())

def jaccard(a: set, b: set) -> float:
    if not a or not b:
        return 0.0
    inter = len(a & b)
    union = len(a | b)
    return inter / union

def keyword_boost(user_tokens: set, keywords: Optional[List[str]]) -> float:
    if not keywords:
        return 0.0
    kw_tokens = {normalize(k) for k in keywords}
    # Simple boost: fraction of keywords appearing in user text (max +0.4)
    hits = len(user_tokens & kw_tokens)
    return min(0.4, 0.15 * hits)

def match_predefined(user_text: str) -> Optional[Tuple[Dict[str, Any], float]]:
    """
    Returns (best_item, score) if confident enough, else None.
    Strategy:
      - Jaccard similarity between user tokens and each canonical question tokens
      - Add a small boost for keyword matches
      - Threshold tuned for short, safety-style prompts
    """
    user_tokens = token_set(user_text)
    best_item, best_score = None, 0.0

    for item in PREDEFINED_QA:
        q_tokens = token_set(item["q"])
        base = jaccard(user_tokens, q_tokens)
        boost = keyword_boost(user_tokens, item.get("keywords"))
        score = base + boost
        if score > best_score:
            best_item, best_score = item, score

    # Threshold guidance:
    #  - 0.55 works well for short Qs with 1–2 keywords matched
    #  - Feel free to tune to your dataset
    if best_item and best_score >= 0.55:
        return best_item, best_score
    return None

# ==============================
# DB Session dependency
# ==============================
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ==============================
# Query nearby hazard reports
# Requires Postgres + cube/earthdistance extensions for ll_to_earth/earth_distance
# ==============================
def get_reports_nearby(db: Session, lat: float, lon: float, radius_km: int = 50):
    query = sql_text("""
        SELECT text, lat, lon, hazard_type, severity
        FROM hazard_report
        WHERE earth_distance(
            ll_to_earth(:lat, :lon),
            ll_to_earth(lat, lon)
        ) < :radius
        ORDER BY report_id DESC
        LIMIT 3;
    """)
    rows = db.execute(query, {"lat": lat, "lon": lon, "radius": radius_km * 1000}).mappings().all()
    return rows

# ==============================
# External News (optional)
# ==============================
def fetch_disaster_news():
    url = "https://newsapi.org/v2/everything"
    params = {"q": "cyclone OR tsunami OR flood India", "apiKey": "YOUR_NEWSAPI_KEY"}
    try:
        r = requests.get(url, params=params, timeout=5)
        data = r.json()
        return data.get("articles", [])[:3]
    except Exception:
        return []

# ==============================
# Main endpoint
# Order of checks:
#   1) Predefined Q&A (your curated set)
#   2) Location-based citizen reports
#   3) Latest disaster news
#   4) Fallback
# ==============================
@router.post("/chatbot", response_model=ChatResponse)
def chatbot(req: ChatRequest, db: Session = Depends(get_db)):
    msg = req.message or ""

    # 1) Predefined Q&A match
    matched = match_predefined(msg)
    if matched:
        item, _score = matched
        return ChatResponse(reply=item["a"], source="predefined")

    # 2) Location-based citizen reports
    if (req.lat is not None) and (req.lon is not None):
        reports = get_reports_nearby(db, req.lat, req.lon)
        if reports:
            reply = "Nearby Reports:\n" + "\n".join(
                [f"- {r['hazard_type']} ({r['severity']}): {r['text']}" for r in reports]
            )
            return ChatResponse(reply=reply, source="citizen_report")

    # 3) Disaster News
    news = fetch_disaster_news()
    if news:
        reply = "Latest Disaster News:\n" + "\n".join(
            [f"- {n.get('title','(no title)')} ({(n.get('source') or {}).get('name','news')})" for n in news]
        )
        return ChatResponse(reply=reply, source="news")

    # 4) Fallback
    return ChatResponse(
        reply="Sorry, I don’t have info on that right now. Stay safe and follow official alerts.",
        source="fallback"
    )
