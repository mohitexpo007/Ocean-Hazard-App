from sqlalchemy import Column, Integer, String, Boolean, Float, LargeBinary, DateTime
from backend.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)
    otp = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False)



class HazardReport(Base):
    __tablename__ = "hazard_report"

    report_id = Column(String, primary_key=True, index=True)
    user_id = Column(String, nullable=False)
    text = Column(String, nullable=True)
    lat = Column(Float, nullable=False)
    lon = Column(Float, nullable=False)
    hazard_type = Column(String, nullable=False)
    severity = Column(String, nullable=False)
    image = Column(LargeBinary, nullable=True)
    status = Column(String, nullable=False, default="pending")
    veracity_score = Column(Float, nullable=True)   # ✅ NEW COLUMN



class Alert(Base):
    __tablename__ = "alerts"

    id          = Column(Integer, primary_key=True, index=True, autoincrement=True)
    disaster_type = Column(String(50), nullable=False)  # flood, earthquake, tsunami, etc.
    severity    = Column(String(20), nullable=False)    # low, medium, high
    description = Column(String, nullable=True)
    lat         = Column(Float, nullable=False)
    lon         = Column(Float, nullable=False)
    timestamp   = Column(DateTime, default=datetime.utcnow)

    # --- ADD THIS at the end of models.py ---
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.sql import func

class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, nullable=True)  # or Integer if you link to users.id
    token = Column(String, unique=True, index=True, nullable=False)
    platform = Column(String, nullable=True)  # 'android' / 'ios' (optional)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint('token', name='uq_device_token'),
    )

