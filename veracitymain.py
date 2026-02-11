from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Optional, Dict, Any
from datetime import datetime, timezone
import io
import math
import logging

import numpy as np
import pandas as pd
from PIL import Image

import torch
from transformers import pipeline, CLIPTokenizer, CLIPFeatureExtractor, CLIPModel
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# --------------------------
# Logging + Device
# --------------------------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("veracity_api")
device = "cuda" if torch.cuda.is_available() else "cpu"
logger.info(f"Device set to: {device}")

# --------------------------
# FastAPI app + CORS
# --------------------------
app = FastAPI(title="Hazard Veracity API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --------------------------
# Load models
# --------------------------
text_classifier = pipeline(
    "zero-shot-classification",
    model="roberta-large-mnli",
    device=0 if device == "cuda" else -1
)

clip_tokenizer = CLIPTokenizer.from_pretrained("openai/clip-vit-large-patch14")
clip_feature_extractor = CLIPFeatureExtractor.from_pretrained("openai/clip-vit-large-patch14")
clip_model = CLIPModel.from_pretrained("openai/clip-vit-large-patch14").to(device)

embedder = SentenceTransformer("all-mpnet-base-v2", device=device)

hazard_labels = ["Flooding", "Tsunami", "High Waves", "Storm Surge", "Coastal Erosion", "Other"]

# --------------------------
# Utility functions
# --------------------------
def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))

def analyze_text(text: str):
    if not text:
        return None, 0.0
    res = text_classifier(text, candidate_labels=hazard_labels)
    return res["labels"][0], float(res["scores"][0])

def analyze_image(image: Image.Image):
    inputs = clip_feature_extractor(images=image, return_tensors="pt").to(device)
    text_inputs = clip_tokenizer(hazard_labels, return_tensors="pt", padding=True).to(device)
    with torch.no_grad():
        image_emb = clip_model.get_image_features(**inputs)
        text_emb = clip_model.get_text_features(**text_inputs)
    image_emb = image_emb / image_emb.norm(dim=-1, keepdim=True)
    text_emb = text_emb / text_emb.norm(dim=-1, keepdim=True)
    sims = (image_emb @ text_emb.T).squeeze(0)
    probs = torch.softmax(sims * 10, dim=0).cpu().numpy()
    idx = int(np.argmax(probs))
    return hazard_labels[idx], float(probs[idx])

def user_reputation(user_record: Dict[str, Any]):
    if not user_record:
        return 0.0
    now = datetime.now(timezone.utc)
    age_days = max(0, (now - user_record["created_at"]).days)
    age_score = min(1.0, age_days / 365)
    verified_reports = user_record.get("verified_reports", 0)
    reports_score = min(1.0, verified_reports / 20)
    verified_bonus = 0.1 if verified_reports > 0 else 0.0
    reputation = 0.5 * age_score + 0.4 * reports_score + verified_bonus
    return round(reputation, 3)

def cluster_strength(report: Dict[str, Any], recent_reports_df: pd.DataFrame, threshold: float = 0.7):
    if recent_reports_df is None or recent_reports_df.empty:
        return 0.0
    nearby_texts = []
    for _, row in recent_reports_df.iterrows():
        try:
            d = haversine_km(report["lat"], report["lon"], float(row["lat"]), float(row["lon"]))
        except Exception:
            continue
        if d <= 5.0:
            nearby_texts.append(str(row.get("text", "")))
    if not nearby_texts or not report.get("text"):
        return 0.0
    q_emb = embedder.encode([report["text"]], convert_to_numpy=True)
    c_emb = embedder.encode(nearby_texts, convert_to_numpy=True)
    sims = cosine_similarity(q_emb, c_emb).flatten()
    count_similar = float((sims > threshold).sum())
    return min(1.0, count_similar / 10.0)

def compute_veracity(text_c: float, img_c: float, user_r: float, cluster_s: float):
    weights = {"text": 0.45, "image": 0.45, "user": 0.05, "cluster": 0.05}
    return round(weights["text"] * text_c + weights["image"] * img_c + weights["user"] * user_r + weights["cluster"] * cluster_s, 3)

# --------------------------
# Mock databases
# --------------------------
user_db = {}      # user_id -> user info
report_db = {}    # report_id -> report info

def get_recent_reports_placeholder() -> pd.DataFrame:
    rows = [
        {"text": "Flooding in Marina area", "lat": 13.06, "lon": 80.27},
        {"text": "Storm surge warning issued", "lat": 13.01, "lon": 80.29}
    ]
    return pd.DataFrame(rows)

# --------------------------
# FastAPI endpoints
# --------------------------
@app.get("/")
def health():
    return {"status": "ok", "device": device}

@app.post("/analyze_report")
async def analyze_report(
    report_id: str = Form(...),
    user_id: str = Form(...),
    text: Optional[str] = Form(None),
    lat: float = Form(...),
    lon: float = Form(...),
    image: Optional[UploadFile] = File(None)
):
    # --- Add new user if not exists
    if user_id not in user_db:
        user_db[user_id] = {"created_at": datetime.now(timezone.utc),
                            "reports": 0,
                            "verified_reports": 0,
                            "verified": False}
    user = user_db[user_id]

    result = {"report_id": report_id, "status": "Pending"}

    # --- Text analysis
    text_label, text_conf = (None, 0.0)
    if text:
        text_label, text_conf = analyze_text(text)

    # --- Image analysis
    img_label, img_conf = (None, 0.0)
    if image:
        try:
            img = Image.open(io.BytesIO(await image.read())).convert("RGB")
            img_label, img_conf = analyze_image(img)
        except Exception as e:
            result["image_error"] = str(e)

    # --- User & cluster
    user["reports"] += 1
    user_r = user_reputation(user)
    recent_reports_df = get_recent_reports_placeholder()
    clust = cluster_strength({"text": text, "lat": lat, "lon": lon}, recent_reports_df)

    veracity = compute_veracity(text_conf, img_conf, user_r, clust)

    # --- Store report
    report_db[report_id] = {
        "user_id": user_id,
        "text": text,
        "lat": lat,
        "lon": lon,
        "text_label": text_label,
        "text_conf": text_conf,
        "image_label": img_label,
        "image_conf": img_conf,
        "veracity": veracity,
        "verified": False
    }

    result.update({
        "text_label": text_label,
        "text_confidence": text_conf,
        "image_label": img_label,
        "image_confidence": img_conf,
        "user_reputation": user_r,
        "cluster_strength": clust,
        "veracity_score": veracity
    })

    return JSONResponse(result)

@app.post("/verify_report")
async def verify_report(report_id: str = Form(...)):
    if report_id not in report_db:
        raise HTTPException(status_code=404, detail="Report not found")
    report = report_db[report_id]
    report["verified"] = True

    # Update user's verified_reports count
    user = user_db[report["user_id"]]
    user["verified_reports"] += 1
    user["verified"] = True

    return {
        "report_id": report_id,
        "status": "Verified (Green Pin)",
        "user_id": report["user_id"],
        "user_reputation": user_reputation(user)
    }
