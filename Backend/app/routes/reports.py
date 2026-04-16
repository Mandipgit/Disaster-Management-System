from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
import math

from ..database import get_db
from ..models.report import Report
from ..models.user import User
from .auth import get_current_user
from sentence_transformers import SentenceTransformer
from ..models.report_embedding import ReportEmbedding


router = APIRouter(prefix="/reports", tags=["Reports"])
model = SentenceTransformer('all-mpnet-base-v2')


def get_embedding(text: str) -> list[float]:
    return model.encode(text).tolist()


# ======================
# Pydantic Schemas
# ======================
class ReportCreateRequest(BaseModel):
    disaster_type: str
    title: str
    description: str
    location: Optional[str] = None
    latitude: float
    longitude: float
    severity: str

class ReportUpdateRequest(BaseModel):
    disaster_type: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    location: Optional[str] = None      
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    severity: Optional[str] = None


class DuplicateCheckRequest(BaseModel):
    title: str
    description: str


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
    payload: ReportCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    THRESHOLD = 0.82

    # Step 1: Convert new report text to vector
    embedding = get_embedding(f"{payload.title}. {payload.description}")

    # Step 2: Check if a similar report already exists
    closest = (
        db.query(
            ReportEmbedding,
            (1 - ReportEmbedding.embedding_vector.cosine_distance(embedding)).label("similarity")
        )
        .filter(ReportEmbedding.embedding_vector.isnot(None))
        .order_by(ReportEmbedding.embedding_vector.cosine_distance(embedding))
        .first()
    )

    # Step 3: If duplicate found, merge into existing report
    if closest is not None:
        report_embedding, similarity = closest
        similarity = float(similarity)

        if similarity >= THRESHOLD:
            # Find the existing report
            existing_report = db.query(Report).filter(
                Report.id == report_embedding.report_id
            ).first()

            if existing_report:
                # Increment sources count
                existing_report.sources = (existing_report.sources or 1) + 1 # pyright: ignore[reportAttributeAccessIssue]
                db.commit()
                db.refresh(existing_report)

                return {
                    "message": f"Your report matched an existing report and has been merged.",
                    "merged": True,
                    "matched_report_id": existing_report.id,
                    "matched_report_title": existing_report.title,
                    "similarity_score": round(similarity, 4),
                    "sources": existing_report.sources
                }

    # Step 4: No duplicate found — save as a brand new report
    new_report = Report(
        user_id=current_user.id,
        disaster_type=payload.disaster_type,
        title=payload.title,
        description=payload.description,
        location=payload.location,             
        latitude=payload.latitude,
        longitude=payload.longitude,
        severity=payload.severity,
        sources=1
    )
    db.add(new_report)
    db.commit()
    db.refresh(new_report)

 # Step 5: Save its embedding
    report_embedding = ReportEmbedding(
        report_id=new_report.id,
        embedding_vector=embedding
    )
    db.add(report_embedding)
    db.commit()

    return {
        "message": "New report created successfully",
        "merged": False,
        "report_id": new_report.id,
        "sources": 1
    }

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
            "location": r.location,    
            "latitude": r.latitude,
            "longitude": r.longitude,
            "severity": r.severity,
            "status": r.status,
            "created_at": r.created_at,
            "updated_at": r.updated_at,
            "sources": r.sources 
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
            "location": r.location,      
            "latitude": r.latitude,
            "longitude": r.longitude,
            "severity": r.severity,
            "status": r.status,
            "created_at": r.created_at,
            "updated_at": r.updated_at,
            "sources": r.sources 
        })
    return result


# ======================
# Get My Reports (logged-in user's own reports)
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
            "location": r.location,    
            "latitude": r.latitude,
            "longitude": r.longitude,
            "severity": r.severity,
            "status": r.status,
            "created_at": r.created_at,
            "updated_at": r.updated_at,
            "sources": r.sources 
        })
    return result


# ======================
# Get Nearby Reports (public) — all statuses
# ======================
@router.get("/nearby", response_model=List[dict])
def get_nearby_reports(
    lat: float,
    lon: float,
    radius: float = 5.0,
    db: Session = Depends(get_db)
):
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
                "location": r.location,   
                "latitude": r.latitude,
                "longitude": r.longitude,
                "severity": r.severity,
                "status": r.status,
                "distance_km": round(distance, 2),
                "created_at": r.created_at,
                "updated_at": r.updated_at,
            "sources": r.sources 
            })

    if not nearby:
        raise HTTPException(
            status_code=404,
            detail=f"No reports found within {radius} km"
        )

    nearby.sort(key=lambda x: x["distance_km"])
    return nearby


# ======================
# Check Duplicate Report
# ======================
@router.post("/check-duplicate")
def check_duplicate(
    payload: DuplicateCheckRequest,
    db: Session = Depends(get_db)
):
    embedding = get_embedding(f"{payload.title}. {payload.description}")

    closest = (
        db.query(
            ReportEmbedding,
            (1 - ReportEmbedding.embedding_vector.cosine_distance(embedding)).label("similarity")
        ).filter(ReportEmbedding.embedding_vector.isnot(None))
        .order_by(ReportEmbedding.embedding_vector.cosine_distance(embedding))
        .first()
    )

    if closest is None:
        return {"is_duplicate": False, "similarity_score": 0.0}

    report_embedding, similarity = closest
    similarity = float(similarity)
    THRESHOLD = 0.82

    if similarity >= THRESHOLD:
        matched_report = db.query(Report).filter(
            Report.id == report_embedding.report_id
        ).first()
        return {
            "is_duplicate": True,
            "similarity_score": round(similarity, 4),
            "matched_report_id": matched_report.id if matched_report else None,
            "matched_report_title": matched_report.title if matched_report else None
        }

    return {
        "is_duplicate": False,
        "similarity_score": round(similarity, 4),
        "matched_report_id": None,
        "matched_report_title": None
    }


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

    if report.user_id != current_user.id:  # pyright: ignore[reportGeneralTypeIssues]
        raise HTTPException(
            status_code=403,
            detail="You can only edit your own reports"
        )

    if payload.disaster_type is not None:
        setattr(report, "disaster_type", payload.disaster_type)
    if payload.title is not None:
        setattr(report, "title", payload.title)
    if payload.description is not None:
        setattr(report, "description", payload.description)
    if payload.location is not None:          
        setattr(report, "location", payload.location)
    if payload.latitude is not None:
        setattr(report, "latitude", payload.latitude)
    if payload.longitude is not None:
        setattr(report, "longitude", payload.longitude)
    if payload.severity is not None:
        setattr(report, "severity", payload.severity)

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

    if report.user_id != current_user.id:  # pyright: ignore[reportGeneralTypeIssues]
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
        "location": report.location,          
        "latitude": report.latitude,
        "longitude": report.longitude,
        "severity": report.severity,
        "status": report.status,
        "created_at": report.created_at,
        "updated_at": report.updated_at,
            "sources": report.sources 
    }
  
