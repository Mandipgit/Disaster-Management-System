from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from pydantic import BaseModel
from typing import List, Optional
import math
from ..database import get_db
from ..models.incident import Incident
from ..models.report import Report
from ..models.user import User
from .auth import get_current_user, get_optional_current_user
from ..models.report_embedding import ReportEmbedding
from ..models.report_reaction import ReportReaction, ReactionType
from google.genai import Client
from google.genai import types
from fastapi import APIRouter
from dotenv import load_dotenv
import os

load_dotenv()
router = APIRouter(prefix="/reports", tags=["Reports/Incidents"])

client = Client(api_key=os.environ.get("GOOGLE_API_KEY"))

def get_embedding(text: str) -> list[float]:
    # Check if API key is missing from environment instead of checking the client object
    if not os.environ.get("GOOGLE_API_KEY"):
        return [0.0] * 1536
    try:
        result = client.models.embed_content(
            model="gemini-embedding-001",
            contents=text,
            config=types.EmbedContentConfig(
                task_type="SEMANTIC_SIMILARITY",
                output_dimensionality=1536
            )
        )
        if not result.embeddings:
            raise ValueError("Google embedding API returned no embeddings")
        return result.embeddings[0].values
    except Exception as e:
        print("Embedding error:", e)
        return [0.0] * 1536

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

def calculate_distance(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def serialize_incident(inc, current_user_id=None):
    submissions = []
    for r in inc.reports:
        user_name = r.user.full_name if (hasattr(r, "user") and r.user) else str(r.user_id)
        # Using string representation of timestamp for time updated
        ts = r.timestamp.isoformat() if hasattr(r, 'timestamp') and r.timestamp else ''
        submissions.append({
            "id": r.id, 
            "user_id": str(r.user_id), 
            "user_name": user_name, 
            "description": r.description,
            "timestamp": ts,
            "title": inc.title,
            "verified": getattr(r, 'verified', False)
        })

    likes = sum(1 for r in getattr(inc, 'reactions', []) if r.reaction_type.value == "LIKE")
    dislikes = sum(1 for r in getattr(inc, 'reactions', []) if r.reaction_type.value == "DISLIKE")
    user_reaction = None
    if current_user_id:
        for r in getattr(inc, 'reactions', []):
            if str(r.user_id) == str(current_user_id):
                user_reaction = r.reaction_type.value
                break

    return {
        "id": inc.id,
        "user_id": submissions[0]["user_id"] if submissions else None,
        "disaster_type": inc.disaster_type,
        "title": inc.title,
        "description": inc.description,
        "location": inc.location,    
        "latitude": inc.latitude,
        "longitude": inc.longitude,
        "severity": inc.severity,
        "status": inc.status,
        "verified": getattr(inc, 'verified', False),
        "created_at": inc.created_at,
        "updated_at": inc.updated_at,
        "sources": inc.sources or len(submissions),
        "likes": likes,
        "dislikes": dislikes,
        "user_reaction": user_reaction,
        "submissions": submissions,
        "media_urls": [m.file_path for m in inc.media if m.file_type == "image"] if hasattr(inc, "media") and inc.media else []
    }

@router.post("/")
def create_report(
    payload: ReportCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    DISASTER_RADIUS_KM = {"flood": 15.0, "landslide": 2.0, "earthquake": 50.0, "fire": 1.0, "default": 5.0}
    TEXT_THRESHOLD = 0.8

    RADIUS_KM = DISASTER_RADIUS_KM.get(payload.disaster_type.lower(), DISASTER_RADIUS_KM["default"])
    embedding = get_embedding(f"{payload.title}. {payload.description}")

    same_type_incidents = db.query(Incident).filter(Incident.disaster_type.ilike(payload.disaster_type)).all()
    nearby_incident_ids = []
    nearby_distances = {}

    for inc in same_type_incidents:
        if inc.latitude is None or inc.longitude is None: continue
        distance_km = calculate_distance(payload.latitude, payload.longitude, inc.latitude, inc.longitude)
        if distance_km <= RADIUS_KM:
            nearby_incident_ids.append(inc.id)
            nearby_distances[inc.id] = round(distance_km, 2)

    closest = None
    if nearby_incident_ids:
        closest = (
            db.query(ReportEmbedding, (1 - ReportEmbedding.embedding_vector.cosine_distance(embedding)).label("similarity"))
            .filter(ReportEmbedding.embedding_vector.isnot(None))
            .filter(ReportEmbedding.incident_id.in_(nearby_incident_ids))
            .order_by(ReportEmbedding.embedding_vector.cosine_distance(embedding))
            .first()
        )

    matched_incident = None
    similarity_score = 0.0

    if closest is not None:
        emb_row, sim = closest
        similarity_score = float(sim)
        if similarity_score >= TEXT_THRESHOLD:
            matched_incident = db.query(Incident).filter(Incident.id == emb_row.incident_id).first()

    if matched_incident:
        matched_incident.sources = (matched_incident.sources or 1) + 1 # type: ignore
        db.commit()
        db.refresh(matched_incident)
        
        new_report = Report(incident_id=matched_incident.id, user_id=current_user.id, description=payload.description)
        db.add(new_report)
        db.commit()

        distance_km = nearby_distances.get(matched_incident.id, 0.0)

        return {
            "message": "Your report matched an existing incident and has been merged.",
            "merged": True,
            "report_id": matched_incident.id,
            "disaster_type": payload.disaster_type,
            "similarity_score": round(similarity_score, 4),
            "distance_km": distance_km,
            "radius_used_km": RADIUS_KM,
            "sources": matched_incident.sources
        }
    else:
        new_incident = Incident(
            disaster_type=payload.disaster_type, title=payload.title, description=payload.description,
            location=payload.location, latitude=payload.latitude, longitude=payload.longitude,
            severity=payload.severity, sources=1
        )
        db.add(new_incident)
        db.commit()
        db.refresh(new_incident)

        new_report = Report(incident_id=new_incident.id, user_id=current_user.id, description=payload.description)
        db.add(new_report)
        db.commit()

        new_embedding = ReportEmbedding(incident_id=new_incident.id, embedding_vector=embedding)
        db.add(new_embedding)
        db.commit()

        return {
            "message": "New report/incident created successfully",
            "merged": False,
            "report_id": new_incident.id,
            "disaster_type": payload.disaster_type,
            "radius_used_km": RADIUS_KM,
            "sources": 1
        }

@router.get("/", response_model=List[dict])
def get_reports(db: Session = Depends(get_db), current_user: User | None = Depends(get_optional_current_user)):
    incidents = (
        db.query(Incident)
        .options(joinedload(Incident.reports).joinedload(Report.user), joinedload(Incident.reactions))
        .all()
    )
    user_id = current_user.id if current_user else None
    return [serialize_incident(inc, user_id) for inc in incidents if inc.reports]

@router.get("/verified", response_model=List[dict])
def get_verified_reports(db: Session = Depends(get_db), current_user: User | None = Depends(get_optional_current_user)):
    incidents = db.query(Incident).filter(Incident.status == "Verified").options(joinedload(Incident.reports).joinedload(Report.user), joinedload(Incident.reactions)).all()
    if not incidents: raise HTTPException(status_code=404, detail="No verified reports found")
    user_id = current_user.id if current_user else None
    return [serialize_incident(inc, user_id) for inc in incidents]

@router.get("/my-reports", response_model=List[dict])
def get_my_reports(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    reports = db.query(Report).filter(Report.user_id == current_user.id).options(joinedload(Report.incident)).all()
    if not reports: raise HTTPException(status_code=404, detail="You have not posted any reports")
    inc_ids = list(set([r.incident_id for r in reports]))
    incidents = db.query(Incident).filter(Incident.id.in_(inc_ids)).options(joinedload(Incident.reports).joinedload(Report.user), joinedload(Incident.reactions)).all()
    return [serialize_incident(inc, current_user.id) for inc in incidents]

@router.get("/nearby", response_model=List[dict])
def get_nearby_reports(lat: float, lon: float, radius: float = 5.0, db: Session = Depends(get_db), current_user: User | None = Depends(get_optional_current_user)):
    incidents = db.query(Incident).options(joinedload(Incident.reports).joinedload(Report.user), joinedload(Incident.reactions)).all()
    if not incidents: raise HTTPException(status_code=404, detail="No incidents found")

    nearby = []
    user_id = current_user.id if current_user else None
    for inc in incidents:
        distance = calculate_distance(lat, lon, inc.latitude, inc.longitude)
        if distance <= radius:
            data = serialize_incident(inc, user_id)
            data["distance_km"] = round(distance, 2)
            nearby.append(data)
    if not nearby: raise HTTPException(status_code=404, detail=f"No incidents found within {radius} km")
    nearby.sort(key=lambda x: x["distance_km"])
    return nearby

@router.delete("/{report_id}")
def delete_own_report(report_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report: raise HTTPException(status_code=404, detail="Report not found")
    if report.user_id != current_user.id: raise HTTPException(status_code=403, detail="Not your report")
    
    incident_id = report.incident_id
    db.delete(report)
    db.commit()
    
    inc = db.query(Incident).filter(Incident.id == incident_id).first()
    if inc and len(inc.reports) == 0:
        db.delete(inc)
        db.commit()
    elif inc:
        inc.sources -= 1
        db.commit()
        
    return {"message": "Report deleted successfully"}

@router.get("/{report_id}")
def get_report(report_id: int, db: Session = Depends(get_db), current_user: User | None = Depends(get_optional_current_user)):
    inc = db.query(Incident).filter(Incident.id == report_id).options(joinedload(Incident.reports).joinedload(Report.user), joinedload(Incident.reactions)).first()
    if not inc: raise HTTPException(status_code=404, detail="Incident not found")
    user_id = current_user.id if current_user else None
    return serialize_incident(inc, user_id)

@router.put("/{report_id}")
def update_report(
    report_id: int,
    payload: ReportUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    inc = db.query(Incident).filter(Incident.id == report_id).first()
    if not inc: raise HTTPException(status_code=404, detail="Incident not found")
    
    if payload.disaster_type: inc.disaster_type = payload.disaster_type
    if payload.title: inc.title = payload.title
    if payload.description: inc.description = payload.description
    if payload.location: inc.location = payload.location
    if payload.latitude: inc.latitude = payload.latitude
    if payload.longitude: inc.longitude = payload.longitude
    if payload.severity: inc.severity = payload.severity
    db.commit()
    db.refresh(inc)
    return {"message": "Incident updated", "report_id": inc.id}

@router.post("/{report_id}/react")
def react_to_report(
    report_id: int, 
    reaction: str, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    if reaction not in ["LIKE", "DISLIKE"]:
        raise HTTPException(status_code=400, detail="Invalid reaction type")

    inc = db.query(Incident).filter(Incident.id == report_id).first()
    if not inc:
        raise HTTPException(status_code=404, detail="Incident not found")

    existing_reaction = db.query(ReportReaction).filter(
        ReportReaction.incident_id == report_id,
        ReportReaction.user_id == current_user.id
    ).first()

    if existing_reaction:
        if existing_reaction.reaction_type.value == reaction:
            db.delete(existing_reaction)
            db.commit()
        else:
            existing_reaction.reaction_type = ReactionType(reaction)
            db.commit()
    else:
        new_reaction = ReportReaction(
            incident_id=report_id,
            user_id=current_user.id,
            reaction_type=ReactionType(reaction)
        )
        db.add(new_reaction)
        db.commit()

    all_reactions = db.query(ReportReaction).filter(ReportReaction.incident_id == report_id).all()
    likes = sum(1 for r in all_reactions if r.reaction_type.value == "LIKE")
    dislikes = sum(1 for r in all_reactions if r.reaction_type.value == "DISLIKE")
    
    user_new_reaction = None
    for r in all_reactions:
        if str(r.user_id) == str(current_user.id):
            user_new_reaction = r.reaction_type.value
            break

    return {"likes": likes, "dislikes": dislikes, "user_reaction": user_new_reaction}
