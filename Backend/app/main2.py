from fastapi import FastAPI

from .routes.auth import router
from .database import engine, Base
from .auth.auth_utils import hash_password
from .models import User, Report, ReportMedia, RescueUpdate, Vote, RiskZone, ReportEmbedding
from app.routes import reports, auth

#Automatically table create garxa model use garera
Base.metadata.create_all(bind=engine)

app2 = FastAPI()

@app2.get("/")
def home():
    return {"message": "DISASTER360 Backend Running"}

app2.include_router(router, prefix="/auth")

app2.include_router(auth.router, prefix="/auth")
app2.include_router(reports.router)