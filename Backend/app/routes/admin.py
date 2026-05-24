# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
# pyrefly: ignore [missing-import]
from pydantic import BaseModel
from typing import Optional, List

from ..database import get_db
from ..models.incident import Incident
from ..models.incident_assignment import IncidentAssignment
from ..models.report import Report
from ..models.user import User
from .auth import get_current_admin

router = APIRouter(prefix="/admin", tags=["Admin"])


# ======================
# Pydantic Schemas
# ======================
class AssignTeamRequest(BaseModel):
    team_names: List[str]


class StatusUpdateRequest(BaseModel):
    status: str


class ReportUpdateRequest(BaseModel):
    disaster_type: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    severity: Optional[str] = None


# pyrefly: ignore [missing-import]
from sqlalchemy.orm import joinedload

# ======================
# Get All Reports (approved admin only)
# Fixed path — must stay above /reports/{report_id}
# ======================
@router.get("/reports")
def get_all_reports(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    from .reports import serialize_incident
    
    incidents = (
        db.query(Incident)
        .options(
            joinedload(Incident.reports).joinedload(Report.user),
            joinedload(Incident.reactions)
        )
        .all()
    )
    
    result = [serialize_incident(inc, current_user.id) for inc in incidents]
    return {"total": len(result), "reports": result}


# ======================
# Update Any Report (approved admin only)
# Must stay above /reports/{report_id}/verify and /reports/{report_id}/status
# ======================
@router.put("/reports/{report_id}")
def admin_update_report(
    report_id: int,
    payload: ReportUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    incident = db.query(Incident).filter(Incident.id == report_id).first()

    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    # Only update fields that were actually sent
    if payload.disaster_type is not None:
        incident.disaster_type = payload.disaster_type
    if payload.title is not None:
        incident.title = payload.title
    if payload.description is not None:
        incident.description = payload.description
    if payload.latitude is not None:
        incident.latitude = payload.latitude
    if payload.longitude is not None:
        incident.longitude = payload.longitude
    if payload.severity is not None:
        incident.severity = payload.severity

    db.commit()
    db.refresh(incident)

    return {
        "message": "Incident updated successfully",
        "report_id": incident.id,
        "updated_by": current_user.email
    }


# ======================
# Verify Report (approved admin only)
# The frontend sends the INCIDENT id (displayed as RPT-{incident.id}).
# We look up the Incident and mark it + all its linked Reports as Verified.
# ======================
@router.put("/reports/{report_id}/verify")
def verify_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    # report_id here is actually the incident id sent from the frontend
    incident = db.query(Incident).filter(Incident.id == report_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Report not found")

    # Mark the incident as verified
    incident.status = "Verified"
    incident.verified = True

    # Mark every linked report as verified
    for r in incident.reports:
        r.status = "Verified"
        r.verified = True

    db.commit()
    db.refresh(incident)

    return {
        "message": f"Incident {report_id} verified successfully",
        "verified_by": current_user.email
    }


# ======================
# Unverify Report (undo a mistaken verification)
# ======================
@router.put("/reports/{report_id}/unverify")
def unverify_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    incident = db.query(Incident).filter(Incident.id == report_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Report not found")

    incident.status = "Pending"
    incident.verified = False

    for r in incident.reports:
        r.status = "Pending"
        r.verified = False

    db.commit()
    db.refresh(incident)

    return {
        "message": f"Incident {report_id} unverified (reset to Pending)",
        "unverified_by": current_user.email
    }


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
    allowed_status = [
        "Pending",
        "Verified",
        "Verified Rescue In Progress",
        "Verified Controlled",
        "Verified and Closed"
    ]

    if payload.status not in allowed_status:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status. Allowed values: {allowed_status}"
        )

    incident = db.query(Incident).filter(Incident.id == report_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    incident.status = payload.status

    # Cascade the status to all linked reports
    for r in incident.reports:
        r.status = payload.status

    db.commit()
    db.refresh(incident)

    return {
        "message": "Incident status updated successfully",
        "report_id": incident.id,
        "new_status": incident.status,
        "updated_by": current_user.email
    }


# ======================
# Assign Teams to Report (approved admin only)
# ======================
@router.post("/reports/{report_id}/assign")
def admin_assign_team(
    report_id: int,
    payload: AssignTeamRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    incident = db.query(Incident).filter(Incident.id == report_id).first()

    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    # Clear existing assignments
    db.query(IncidentAssignment).filter(IncidentAssignment.incident_id == incident.id).delete()

    # Add new ones
    for t in payload.team_names:
        db.add(IncidentAssignment(incident_id=incident.id, team_name=t))

    db.commit()
    db.refresh(incident)

    return {
        "message": "Teams assigned successfully",
        "report_id": incident.id,
        "assigned_teams": payload.team_names,
        "assigned_by": current_user.email
    }


# ======================
# Delete Any Report (approved admin only)
# ======================
@router.delete("/reports/{report_id}")
def admin_delete_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin)
):
    incident = db.query(Incident).filter(Incident.id == report_id).first()

    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    db.delete(incident)
    db.commit()

    return {
        "message": f"Incident {report_id} and all associated reports deleted successfully",
        "deleted_by": current_user.email
    }
# ======================
# User Management Endpoints
# ======================

@router.get("/users")
def get_users(
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    users = db.query(User).all()
    return [{"id": str(u.id), "full_name": u.full_name, "email": u.email, "phone": u.phone, 
             "role": u.role, "is_admin": u.is_admin, "is_rescueteam": u.is_rescueteam,
             "created_at": u.created_at} for u in users]


@router.put("/users/{user_id}/status")
def update_user_status(
    user_id: str,
    payload: dict,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if "is_admin" in payload:
        user.is_admin = payload["is_admin"]
    if "is_rescueteam" in payload:
        user.is_rescueteam = payload["is_rescueteam"]
        
    db.commit()
    db.refresh(user)
    return {"message": "User status updated", "is_admin": user.is_admin, "is_rescueteam": user.is_rescueteam}
