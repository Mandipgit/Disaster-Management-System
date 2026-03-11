from sqlalchemy import Column, Integer, String, ForeignKey
from ..database import Base

class ReportMedia(Base):
    __tablename__ = "report_media"

    id = Column(Integer, primary_key=True)

    report_id = Column(Integer, ForeignKey("reports.id"))

    file_url = Column(String)
    file_type = Column(String)