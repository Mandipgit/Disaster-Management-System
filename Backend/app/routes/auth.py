from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
import uuid

from ..database import get_db
from ..models.user import User
from ..auth.auth_utils import (
    hash_password,
    verify_password,
    create_access_token,
    verify_access_token,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


# ==============================
# Helper: safely cast is_admin to bool
# ==============================
def is_admin_approved(user: User) -> bool:
    # Handles both actual Boolean and accidental string "false"/"true"
    return str(user.is_admin).lower() == "true"


# ======================
# Pydantic Schema
# ======================
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    role: str = "citizen"


# ======================
# Register
# ======================
@router.post("/register")
def register(payload: RegisterRequest, db: Session = Depends(get_db)):

    existing_user = db.query(User).filter(User.email == payload.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    if payload.role.lower() not in ["citizen", "admin"]:
        raise HTTPException(status_code=400, detail="Role must be 'citizen' or 'admin'")

    new_user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        role=payload.role.lower(),
        is_admin=False  # always False on registration, no exceptions
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    if payload.role.lower() == "admin":
        message = "Admin registered successfully. You cannot login until manually approved in the database."
    else:
        message = "Citizen registered successfully. You can now login."

    return {"message": message}


# ======================
# Login
# ======================
@router.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    # OAuth2PasswordRequestForm sends email in the "username" field in Swagger
    user = db.query(User).filter(User.email == form_data.username).first()

    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Invalid credentials")

    # ✅ Citizen → always allowed
    # ✅ Admin not approved → strictly blocked
    # ✅ Admin approved → allowed
    if user.role == "admin" and not is_admin_approved(user):
        raise HTTPException(
            status_code=403,
            detail="Admin account pending approval. Contact system administrator."
        )

    access_token = create_access_token(
        data={
            "user_id": str(user.id),
            "role": user.role
        }
    )

    return {"access_token": access_token, "token_type": "bearer"}


# ======================
# Profile
# ======================
@router.get("/profile")
def get_profile(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    payload = verify_access_token(token)
    user = db.query(User).filter(User.id == uuid.UUID(payload.get("user_id"))).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "id": user.id,
        "email": user.email,
        "role": user.role,
        "is_admin": user.is_admin
    }


# ======================
# Dependency: any logged-in citizen OR approved admin
# ======================
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    payload = verify_access_token(token)
    user = db.query(User).filter(User.id == uuid.UUID(payload.get("user_id"))).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # ✅ Double safety — blocks admin if revoked in DB after token was issued
    if user.role == "admin" and not is_admin_approved(user):
        raise HTTPException(
            status_code=403,
            detail="Admin access has been revoked. Contact system administrator."
        )

    return user


# ======================
# Dependency: approved admin only
# ======================
def get_current_admin(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    payload = verify_access_token(token)

    if payload.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")

    user = db.query(User).filter(User.id == uuid.UUID(payload.get("user_id"))).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not is_admin_approved(user):
        raise HTTPException(
            status_code=403,
            detail="Admin access has been revoked. Contact system administrator."
        )

    return user