from sqlalchemy import Column, String, Integer, Date
from sqlalchemy.dialects.postgresql import UUID
import uuid
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
    trust_score = Column(Integer, default=0)