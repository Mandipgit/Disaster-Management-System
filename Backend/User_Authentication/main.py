from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from database import get_db

from database_models import User
from database import engine
from database_models import Base

Base.metadata.create_all(bind=engine)
from auth_utils import (
    hash_password,
    verify_password,
    create_access_token,
    verify_access_token,
)

app = FastAPI()



oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")




@app.post("/register")
def register(email: str, password: str, db: Session = Depends(get_db)):

    existing_user = db.query(User).filter(User.email == email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pw = hash_password(password)

    new_user = User(
        email=email,
        hashed_password=hashed_pw
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"message": "User registered successfully"}




@app.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(),
          db: Session = Depends(get_db)):

    user = db.query(User).filter(User.email == form_data.username).first()

    if not user:
        raise HTTPException(status_code=400, detail="Invalid credentials")

    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Invalid credentials")

    access_token = create_access_token(
        data={"user_id": user.id}
    )

    return {"access_token": access_token, "token_type": "bearer"}




@app.get("/profile")
def get_profile(token: str = Depends(oauth2_scheme),
                db: Session = Depends(get_db)):

    payload = verify_access_token(token)
    user_id = payload.get("user_id")

    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "id": user.id,
        "email": user.email
    }