from fastapi import FastAPI
from app.database import engine, Base
from app.models import User, Report, ReportMedia, RescueUpdate, RiskZone, ReportEmbedding, report_media
from app.routes import auth, admin, reports, media

# Create all tables
Base.metadata.create_all(bind=engine)

app2 = FastAPI(title="DISASTER360 API")


@app2.get("/")
def home():
    return {"message": "DISASTER360 Backend Running"}

app2.include_router(auth.router)
app2.include_router(admin.router)
app2.include_router(reports.router)
app2.include_router(media.router)