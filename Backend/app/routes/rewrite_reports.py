import re

with open("reports.py", "r", encoding="utf-8") as f:
    text = f.read()

# Replace db.query(Report) with db.query(Incident) in GET endpoints
# Rewrite create_report manually
new_create_report = """@router.post("/")
def create_report(
    payload: ReportCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    DISASTER_RADIUS_KM = { "flood": 15.0, "landslide": 2.0, "earthquake": 50.0, "fire": 1.0, "default": 5.0 }
    TEXT_THRESHOLD = 0.70
    RADIUS_KM = DISASTER_RADIUS_KM.get(payload.disaster_type.lower(), DISASTER_RADIUS_KM["default"])

    embedding = get_embedding(f"{payload.title}. {payload.description}")

    same_type_incidents = db.query(Incident).filter(Incident.disaster_type.ilike(payload.disaster_type)).all()
    nearby_incident_ids = []
    nearby_distances = {}

    for inc in same_type_incidents:
        if inc.latitude is None or inc.longitude is None: continue
        d_km = calculate_distance(payload.latitude, payload.longitude, inc.latitude, inc.longitude)
        if d_km <= RADIUS_KM:
            nearby_incident_ids.append(inc.id)
            nearby_distances[inc.id] = round(d_km, 2)

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
        matched_incident.sources = (matched_incident.sources or 1) + 1
        db.commit()
        db.refresh(matched_incident)

        new_report = Report(incident_id=matched_incident.id, user_id=current_user.id, description=payload.description)
        db.add(new_report)
        db.commit()
        
        return {
            "message": "Your report matched an existing incident and has been merged.",
            "merged": True,
            "report_id": matched_incident.id,  # return incident id to treat as master
            "matched_report_title": matched_incident.title,
            "disaster_type": payload.disaster_type,
            "similarity_score": round(similarity_score, 4),
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
            "report_id": new_incident.id, # treat incident as report_id to UI
            "disaster_type": payload.disaster_type,
            "sources": 1
        }
"""

new_get_reports = """@router.get("/", response_model=List[dict])
def get_reports(db: Session = Depends(get_db)):
    incidents = db.query(Incident).options(joinedload(Incident.reports)).all()
    result = []
    for inc in incidents:
        reps = [{"id": r.id, "user_id": str(r.user_id), "description": r.description} for r in inc.reports] if inc.reports else []
        result.append({
            "id": inc.id,
            "user_id": reps[0]['user_id'] if reps else None, # fallback
            "disaster_type": inc.disaster_type,
            "title": inc.title,
            "description": inc.description,
            "location": inc.location,    
            "latitude": inc.latitude,
            "longitude": inc.longitude,
            "severity": inc.severity,
            "status": inc.status,
            "created_at": inc.created_at,
            "updated_at": inc.updated_at,
            "sources": inc.sources,
            "submissions": reps
        })
    return result
"""

import sys
sys.exit(0)
"""