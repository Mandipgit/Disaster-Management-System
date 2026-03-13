from sqlalchemy.dialects.postgresql import UUID

from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from ..database import Base

class ReportMedia(Base):
    __tablename__ = "report_media"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    report_id = Column(Integer, ForeignKey("reports.id"))
    file_path = Column(String)
    file_type = Column(String)

    __table_args__ = (UniqueConstraint("report_id", "file_path", name="uq_report_file"),)