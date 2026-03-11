from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models.report import Report
from ..models.user import User
from ..auth.auth_utils import verify_access_token
from fastapi.security import OAuth2PasswordBearer

import uuid
# Router create garne
router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)
# User get garne function
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")
def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    payload = verify_access_token(token)
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(User).filter(User.id == uuid.UUID(user_id)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# Report post garne
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
# Report get garne function (Admin, public views ko lagi)
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
# Single Report View garne
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
