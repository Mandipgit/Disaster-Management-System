from sqlalchemy import Column, Integer, String, Text, ForeignKey
from ..database import Base

class RescueUpdate(Base):
    __tablename__ = "rescue_updates"

    id = Column(Integer, primary_key=True)

    incident_id = Column(Integer, ForeignKey("incidents.id", ondelete="CASCADE"), nullable=False)

    updated_by = Column(String)
    status = Column(String)
    note = Column(Text)