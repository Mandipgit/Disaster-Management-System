from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models.vote import Vote
from ..models.report import Report
from ..models.user import User
from ..auth.auth_utils import verify_access_token
from fastapi.security import OAuth2PasswordBearer
import uuid

router = APIRouter(prefix="/vote", tags=["Vote"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    payload = verify_access_token(token)
    user_id = payload.get("user_id")
    user = db.query(User).filter(User.id == uuid.UUID(user_id)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# Cast vote
@router.post("/{report_id}")
def vote_report(report_id: int, vote_value: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if vote_value not in [-1, 1]:
        raise HTTPException(status_code=400, detail="Vote must be +1 or -1")

    # Check if user has already voted on this report
    existing_vote = db.query(Vote).filter(Vote.report_id == report_id, Vote.user_id == current_user.id).first()
    if existing_vote:
        existing_vote.vote = vote_value  # Update previous vote
    else:
        new_vote = Vote(report_id=report_id, user_id=current_user.id, vote=vote_value)
        db.add(new_vote)
    
    # Update verified_votes in report table
    report = db.query(Report).filter(Report.id == report_id).first()
    if report:
        total_votes = sum([v.vote for v in db.query(Vote).filter(Vote.report_id == report_id).all()])
        report.verified_votes = total_votes

    db.commit()
    return {"message": "Vote recorded successfully", "total_votes": report.verified_votes}