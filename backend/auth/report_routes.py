from fastapi import APIRouter, Depends, Form, File, UploadFile, HTTPException, WebSocket
from sqlalchemy.orm import Session
from typing import Optional
from uuid import uuid4
from backend import models, database
import asyncio
import requests   # ✅ added
import io

router = APIRouter()

# ======================================================
# ❗ Keep routes same, just add refresh WebSocket support
# ======================================================

report_clients: list[WebSocket] = []  # still track clients here

@router.websocket("/ws/reports")
async def report_ws(websocket: WebSocket):
    """Keep WebSocket connection alive so client can receive updates"""
    await websocket.accept()
    report_clients.append(websocket)
    try:
        while True:
            await websocket.receive_text()  # client pings keepalive
    except:
        if websocket in report_clients:
            report_clients.remove(websocket)


async def send_report_update(report: dict):
    """Send updated report (dict) to all WebSocket clients"""
    disconnected = []
    for ws in report_clients:
        try:
            await ws.send_json(report)
        except:
            disconnected.append(ws)

    # cleanup
    for dc in disconnected:
        if dc in report_clients:
            report_clients.remove(dc)


# ======================================================
# Routes (unchanged logic + model integration)
# ======================================================

@router.post("/reports/", tags=["Citizen Reports"])
async def submit_report(
    user_id: str = Form(...),
    text: str = Form(None),
    lat: float = Form(...),
    lon: float = Form(...),
    hazard_type: str = Form(...),
    severity: str = Form(...),
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(database.get_db)
):
    report_id = str(uuid4())

    image_data = None
    if image:
        image_data = await image.read()

    new_report = models.HazardReport(
        report_id=report_id,
        user_id=user_id,
        text=text,
        lat=lat,
        lon=lon,
        hazard_type=hazard_type,
        severity=severity,
        image=image_data,
        status="pending",
        veracity_score=None  # ✅ added placeholder
    )

    db.add(new_report)
    db.commit()
    db.refresh(new_report)

    # ✅ Call external model API (veracitymain.py running on 8001)
    try:
        files = {"image": ("image.jpg", io.BytesIO(image_data), "image/jpeg")} if image_data else None
        data = {
            "report_id": report_id,
            "user_id": user_id,
            "text": text or "",
            "lat": lat,
            "lon": lon
        }

        resp = requests.post("http://127.0.0.1:8001/analyze_report", data=data, files=files)
        if resp.status_code == 200:
            model_out = resp.json()
            veracity = model_out.get("veracity_score", 0.0)

            # ✅ Save veracity_score to DB
            new_report.veracity_score = veracity
            db.commit()
            db.refresh(new_report)
        else:
            print("⚠️ Model API error:", resp.text)
    except Exception as e:
        print("⚠️ Model call failed:", e)

    # ✅ Send async update (so Flutter gets it instantly)
    asyncio.create_task(send_report_update({
        "report_id": new_report.report_id,
        "user_id": new_report.user_id,
        "text": new_report.text,
        "lat": new_report.lat,
        "lon": new_report.lon,
        "hazard_type": new_report.hazard_type,
        "severity": new_report.severity,
        "status": new_report.status,
        "veracity_score": getattr(new_report, "veracity_score", None)  # include in update
    }))

    return {
        "success": True,
        "message": "Report submitted successfully",
        "data": {
            "report_id": new_report.report_id,
            "user_id": new_report.user_id,
            "text": new_report.text,
            "lat": new_report.lat,
            "lon": new_report.lon,
            "hazard_type": new_report.hazard_type,
            "severity": new_report.severity,
            "status": new_report.status,
            "veracity_score": getattr(new_report, "veracity_score", None)
        }
    }


@router.get("/reports/", tags=["Citizen Reports"])
def list_reports(db: Session = Depends(database.get_db)):
    reports = db.query(models.HazardReport).all()
    return [
        {
            "report_id": r.report_id,
            "user_id": r.user_id,
            "text": r.text,
            "lat": r.lat,
            "lon": r.lon,
            "hazard_type": r.hazard_type,
            "severity": r.severity,
            "status": r.status,
            "veracity_score": r.veracity_score
        } for r in reports
    ]


@router.get("/reports/status/{user_id}", tags=["Citizen Reports"])
def get_user_reports(user_id: str, db: Session = Depends(database.get_db)):
    reports = db.query(models.HazardReport).filter(models.HazardReport.user_id == user_id).all()
    return {
        "success": True,
        "reports": [
            {
                "report_id": r.report_id,
                "text": r.text,
                "lat": r.lat,
                "lon": r.lon,
                "hazard_type": r.hazard_type,
                "severity": r.severity,
                "status": r.status,
                "veracity_score": r.veracity_score
            } for r in reports
        ]
    }


@router.put("/reports/{report_id}/verify", tags=["Citizen Reports"])
async def verify_report(report_id: str, db: Session = Depends(database.get_db)):
    report = db.query(models.HazardReport).filter(models.HazardReport.report_id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    report.status = "verified"
    db.commit()
    db.refresh(report)

    # ✅ Notify clients after verification
    asyncio.create_task(send_report_update({
        "report_id": report.report_id,
        "user_id": report.user_id,
        "text": report.text,
        "lat": report.lat,
        "lon": report.lon,
        "hazard_type": report.hazard_type,
        "severity": report.severity,
        "status": report.status,
        "veracity_score": report.veracity_score
    }))

    return {
        "success": True,
        "message": "Report verified",
        "data": {
            "report_id": report.report_id,
            "status": report.status,
            "hazard_type": report.hazard_type,
            "severity": report.severity,
            "veracity_score": report.veracity_score
        }
    }


@router.get("/reports/{report_id}", tags=["Citizen Reports"])
def get_report(report_id: str, db: Session = Depends(database.get_db)):
    r = db.query(models.HazardReport).filter(models.HazardReport.report_id == report_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Report not found")
    return {
        "report_id": r.report_id,
        "user_id": r.user_id,
        "text": r.text,
        "lat": r.lat,
        "lon": r.lon,
        "hazard_type": r.hazard_type,
        "severity": r.severity,
        "status": r.status,
        "veracity_score": r.veracity_score
    }
