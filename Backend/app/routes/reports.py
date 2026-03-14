from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
import math

from ..database import get_db
from ..models.report import Report
from ..models.user import User
from .auth import get_current_user

router = APIRouter(prefix="/reports", tags=["Reports"])


# ======================
# Pydantic Schema
# ======================
class ReportUpdateRequest(BaseModel):
    disaster_type: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    severity: Optional[str] = None


# ======================
# Helper: Haversine distance calculator
# ======================
def calculate_distance(lat1, lon1, lat2, lon2):
    R = 6371
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
# Get Verified Reports (public)
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
# Get own reports
# ======================

@router.get("/my-reports", response_model=List[dict])
def get_my_reports(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    reports = db.query(Report).filter(Report.user_id == current_user.id).all()

    if not reports:
        raise HTTPException(status_code=404, detail="You have not posted any reports")

    result = []
    for r in reports:
        result.append({
            "id": r.id,
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
# Get Nearby Verified Reports (public)
# ======================
@router.get("/nearby", response_model=List[dict])
def get_nearby_reports(
    lat: float,
    lon: float,
    radius: float = 5.0,
    db: Session = Depends(get_db)
):
    #Fetch ALL reports regardless of status
    all_reports = db.query(Report).all()

    if not all_reports:
        raise HTTPException(status_code=404, detail="No reports found")

    nearby = []
    for r in all_reports:
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
                "status": r.status,  # shows actual status of each report
                "distance_km": round(distance, 2),
                "created_at": r.created_at,
                "updated_at": r.updated_at
            })

    if not nearby:
        raise HTTPException(
            status_code=404,
            detail=f"No reports found within {radius} km"
        )

    # Sort by closest first
    nearby.sort(key=lambda x: x["distance_km"])

    return nearby

# ======================
# Edit Own Report (citizen only)
# ======================
@router.put("/{report_id}")
def update_report(
    report_id: int,
    payload: ReportUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    report = db.query(Report).filter(Report.id == report_id).first()

    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    # Citizens can only edit their own reports
    if report.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You can only edit your own reports"
        )

    if payload.disaster_type is not None:
        report.disaster_type = payload.disaster_type
    if payload.title is not None:
        report.title = payload.title
    if payload.description is not None:
        report.description = payload.description
    if payload.latitude is not None:
        report.latitude = payload.latitude
    if payload.longitude is not None:
        report.longitude = payload.longitude
    if payload.severity is not None:
        report.severity = payload.severity

    db.commit()
    db.refresh(report)

    return {
        "message": "Report updated successfully",
        "report_id": report.id,
        "updated_by": current_user.email
    }


# ======================
# Delete Own Report (citizen only)
# ======================
@router.delete("/{report_id}")
def delete_own_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    report = db.query(Report).filter(Report.id == report_id).first()

    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    # Citizens can only delete their own reports
    if report.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You can only delete your own reports"
        )

    db.delete(report)
    db.commit()

    return {"message": f"Report {report_id} deleted successfully"}


# ======================
# Get Single Report (public)
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