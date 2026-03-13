from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models.report import Report
from ..models.user import User
from .auth import get_current_admin  
from pydantic import BaseModel

router = APIRouter(prefix="/admin", tags=["Admin"])


# ======================
# Verify Report (approved admin only)
# ======================
@router.put("/reports/{report_id}/verify")
def verify_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    report.status = "Verified"
    db.commit()
    db.refresh(report)

    return {"message": f"Report {report_id} verified successfully by {current_user.email}"}



# ======================
# Pydantic Schema for status update
# ======================
class StatusUpdateRequest(BaseModel):
    status: str
# ======================
# Update Report Status (approved admin only)
# ======================
@router.put("/reports/{report_id}/status")
def update_report_status(
    report_id: int,
    payload: StatusUpdateRequest,          
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)  
):
    # Allowed status values
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
# Get All Reports (approved admin only)
# ======================
@router.get("/reports")
def get_all_reports(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    reports = db.query(Report).all()
    return {"total": len(reports), "reports": reports}