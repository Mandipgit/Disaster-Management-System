from sqlalchemy import Column, Integer, String, ForeignKey
from ..database import Base

class Vote(Base):
    __tablename__ = "votes"

    id = Column(Integer, primary_key=True)

    report_id = Column(Integer, ForeignKey("reports.id"))
    user_id = Column(String)

    vote_type = Column(String)