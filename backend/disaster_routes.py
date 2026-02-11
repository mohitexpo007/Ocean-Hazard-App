from fastapi import APIRouter, Depends, WebSocket, HTTPException
from sqlalchemy.orm import Session
from typing import List
from backend import models, database, schemas
import asyncio

router = APIRouter(
    prefix="/disasters",
    tags=["Disasters"]
)

# Track connected clients
alert_clients: list[WebSocket] = []


# ========== WebSocket for real-time alerts ==========
@router.websocket("/ws/alerts")
async def alerts_ws(websocket: WebSocket):
    await websocket.accept()
    alert_clients.append(websocket)
    try:
        while True:
            await websocket.receive_text()  # keep connection alive
    except:
        alert_clients.remove(websocket)


async def broadcast_alert(alert: dict):
    """Send new alerts to all connected clients"""
    disconnected = []
    for ws in alert_clients:
        try:
            await ws.send_json(alert)
        except:
            disconnected.append(ws)

    for dc in disconnected:
        alert_clients.remove(dc)


# ========== REST APIs ==========
@router.post("/", response_model=schemas.AlertResponse)
async def create_alert(alert: schemas.AlertCreate, db: Session = Depends(database.get_db)):
    new_alert = models.Alert(
        disaster_type=alert.disaster_type,
        severity=alert.severity,
        description=alert.description,
        lat=alert.lat,
        lon=alert.lon
    )
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)

    # 🔹 Broadcast new alert to WebSocket clients
    asyncio.create_task(broadcast_alert({
        "id": new_alert.id,
        "disaster_type": new_alert.disaster_type,
        "severity": new_alert.severity,
        "description": new_alert.description,
        "lat": new_alert.lat,
        "lon": new_alert.lon,
        "timestamp": str(new_alert.timestamp)
    }))

    return new_alert


@router.get("/", response_model=List[schemas.AlertResponse])
def get_alerts(db: Session = Depends(database.get_db)):
    return db.query(models.Alert).order_by(models.Alert.timestamp.desc()).all()
