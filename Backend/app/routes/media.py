from fastapi import APIRouter, UploadFile, Depends, HTTPException
from sqlalchemy.orm import Session
import shutil
import uuid
import os

from ..database import get_db
from ..models.report import Report
from ..models.report_media import ReportMedia
from ..models.user import User
from .auth import get_current_user  # ✅ import, never rewrite

router = APIRouter(prefix="/media", tags=["Media"])


# ======================
# Upload Media (citizen or approved admin)
# ======================
@router.post("/upload/{report_id}")
def upload_media(
    report_id: int,
    file: UploadFile,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check report exists
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    # Only report owner or approved admin can upload media
    if report.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=403,
            detail="Not authorized to upload media for this report"
        )

    # Check duplicate
    existing_media = db.query(ReportMedia).filter(
        ReportMedia.report_id == report_id,
        ReportMedia.file_path == f"uploads/reports/{file.filename}"
    ).first()

    if existing_media:
        raise HTTPException(
            status_code=400,
            detail="This media is already uploaded for this report"
        )

    # Create uploads directory if it does not exist
    os.makedirs("uploads/reports", exist_ok=True)

    # Save file with unique name
    filename = f"{uuid.uuid4()}_{file.filename}"
    file_location = f"uploads/reports/{filename}"
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Save to DB
    media = ReportMedia(
        report_id=report_id,
        user_id=current_user.id,
        file_path=file_location,
        file_type=file.content_type
    )
    db.add(media)
    db.commit()
    db.refresh(media)

    return {
        "message": "Media uploaded successfully",
        "media_id": media.id,
        "file_path": file_location
    }