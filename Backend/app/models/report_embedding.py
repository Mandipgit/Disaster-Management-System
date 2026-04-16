from sqlalchemy import Column, Integer, ForeignKey
from pgvector.sqlalchemy import Vector
from ..database import Base

class ReportEmbedding(Base):
    __tablename__ = "report_embeddings"

    id = Column(Integer, primary_key=True)
    report_id = Column(Integer, ForeignKey("reports.id"))
    embedding_vector = Column(Vector(768))