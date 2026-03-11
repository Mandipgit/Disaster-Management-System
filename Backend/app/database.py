from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 🔹 Replace YOUR_PASSWORD with your PostgreSQL password
DATABASE_URL = "postgresql://postgres:9845@localhost:5432/disaster360_db"

# PostgreSQL lai fastapi sanga connect garne
engine = create_engine(DATABASE_URL)

# Data haru insert, read, update ani delete garna
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Base class (all tables will inherit from this)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()