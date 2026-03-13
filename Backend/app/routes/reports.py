from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List
import math

from ..database import get_db
from ..models.report import Report
from ..models.user import User
from .auth import get_current_user, get_current_admin

router = APIRouter(prefix="/reports", tags=["Reports"])


# ======================
# Pydantic Schema
# ======================
class StatusUpdateRequest(BaseModel):
    status: str


# ======================
# Helper: Haversine distance calculator
# ======================
def calculate_distance(lat1, lon1, lat2, lon2):
    R = 6371  # Earth radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


# ======================
# Create Report (citizen or approved admin)
# ======================
@router.post("/")
def create_report(
    disaster_type: str,
    title: str,
    description: str,
    latitude: float,
    longitude: float,
    severity: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_report = Report(
        user_id=current_user.id,
        disaster_type=disaster_type,
        title=title,
        description=description,
        latitude=latitude,
        longitude=longitude,
        severity=severity
    )

    db.add(new_report)
    db.commit()
    db.refresh(new_report)

    return {"message": "Report created successfully", "report_id": new_report.id}


# ======================
# Get All Reports (public)
# ======================
@router.get("/", response_model=List[dict])
def get_reports(db: Session = Depends(get_db)):
    reports = db.query(Report).all()
    result = []
    for r in reports:
        result.append({
            "id": r.id,
            "user_id": r.user_id,
            "disaster_type": r.disaster_type,
            "title": r.title,
            "description": r.description,
            "latitude": r.latitude,
            "longitude": r.longitude,
            "severity": r.severity,
            "status": r.status,
            "created_at": r.created_at,
            "updated_at": r.updated_at
        })
    return result


# ======================
# ✅ Get Verified Reports (public)
# Must be above /{report_id}
# ======================
@router.get("/verified", response_model=List[dict])
def get_verified_reports(db: Session = Depends(get_db)):
    reports = db.query(Report).filter(Report.status == "Verified").all()

    if not reports:
        raise HTTPException(status_code=404, detail="No verified reports found")

    result = []
    for r in reports:
        result.append({
            "id": r.id,
            "user_id": r.user_id,
            "disaster_type": r.disaster_type,
            "title": r.title,
            "description": r.description,
            "latitude": r.latitude,
            "longitude": r.longitude,
            "severity": r.severity,
            "status": r.status,
            "created_at": r.created_at,
            "updated_at": r.updated_at
        })
    return result


# ======================
# ✅ Get Nearby Verified Reports (public)
# Must be above /{report_id}
# ======================
@router.get("/nearby", response_model=List[dict])
def get_nearby_reports(
    lat: float,
    lon: float,
    radius: float = 5.0,
    db: Session = Depends(get_db)
):
    # ✅ Step 1: Check ALL reports first, not just verified
    all_reports = db.query(Report).all()
    print(f"DEBUG >>> Total reports in DB: {len(all_reports)}")

    verified_reports = db.query(Report).filter(Report.status == "Verified").all()
    print(f"DEBUG >>> Verified reports: {len(verified_reports)}")

    # ✅ Step 2: Print distance of every verified report from your location
    for r in verified_reports:
        distance = calculate_distance(lat, lon, r.latitude, r.longitude)
        print(f"DEBUG >>> Report {r.id} | lat={r.latitude} lon={r.longitude} | distance={round(distance, 2)} km | status={r.status}")

    # ✅ Step 3: Filter by radius
    nearby = []
    for r in verified_reports:
        distance = calculate_distance(lat, lon, r.latitude, r.longitude)
        if distance <= radius:
            nearby.append({
                "id": r.id,
                "user_id": r.user_id,
                "disaster_type": r.disaster_type,
                "title": r.title,
                "description": r.description,
                "latitude": r.latitude,
                "longitude": r.longitude,
                "severity": r.severity,
                "status": r.status,
                "distance_km": round(distance, 2),
                "created_at": r.created_at,
                "updated_at": r.updated_at
            })

    print(f"DEBUG >>> Reports within {radius} km: {len(nearby)}")

    if not nearby:
        raise HTTPException(
            status_code=404,
            detail=f"No verified reports found within {radius} km"
        )

    nearby.sort(key=lambda x: x["distance_km"])
    return nearby


# ======================
# Must be above /{report_id}
# ======================
@router.put("/reports/{report_id}/status")
def update_report_status(
    report_id: int,
    payload: StatusUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)  # ✅ admin only
):
    allowed_status = [
        "Pending",
        "Verified",
        "Rescue In Progress",
        "Controlled",
        "Closed"
    ]

    if payload.status not in allowed_status:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status. Allowed values: {allowed_status}"
        )

    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    report.status = payload.status
    db.commit()
    db.refresh(report)

    return {
        "message": "Report status updated successfully",
        "report_id": report.id,
        "new_status": report.status,
        "updated_by": current_user.email
    }


# ======================
# Get Single Report (public)
# ✅ Always LAST — /{report_id} must never appear before fixed paths
# ======================
@router.get("/{report_id}")
def get_report(report_id: int, db: Session = Depends(get_db)):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    return {
        "id": report.id,
        "user_id": report.user_id,
        "disaster_type": report.disaster_type,
        "title": report.title,
        "description": report.description,
        "latitude": report.latitude,
        "longitude": report.longitude,
        "severity": report.severity,
        "status": report.status,
        "created_at": report.created_at,
        "updated_at": report.updated_at
    }
