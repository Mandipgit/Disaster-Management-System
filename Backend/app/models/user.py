from sqlalchemy import Column, String, Boolean, Date, DateTime
from sqlalchemy.dialects.postgresql import UUID
import uuid
from sqlalchemy.sql import func
from ..database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name = Column(String)
    email = Column(String, unique=True, index=True, nullable=False)
    phone = Column(String)
    password_hash = Column(String, nullable=False)
    citizenship_number = Column(String, unique=True)
    citizenship_issue_date = Column(Date)
    citizenship_issue_district = Column(String)
    role = Column(String, default="citizen")

    is_admin = Column(Boolean, nullable=False, default=False, server_default="false")
    is_rescueteam = Column(Boolean, nullable=False, default=False, server_default="false")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())