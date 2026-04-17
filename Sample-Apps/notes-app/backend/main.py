from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from datetime import timedelta, datetime
from bson import ObjectId
from bson.errors import InvalidId

from database import db, client
from models import UserCreate, Token, NoteCreate, NoteUpdate
from auth import (
    get_password_hash,
    verify_password,
    create_access_token,
    get_current_user,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)

app = FastAPI(title="Notes App API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://localhost:80"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health & Readiness Probes ──────────────────────────────────────────────────

@app.get("/healthz")
async def health_check():
    """Liveness probe - returns 200 if app is running"""
    return {"status": "ok"}


@app.get("/ready")
async def readiness_check():
    """Readiness probe - checks database connectivity"""
    try:
        # Ping the database to verify connectivity
        await client.admin.command('ping')
        return {"status": "ready", "database": "connected"}
    except Exception as e:
        raise HTTPException(
            status_code=503, 
            detail=f"Database connection failed: {str(e)}"
        )


def serialize_note(note: dict) -> dict:
    return {
        "id": str(note["_id"]),
        "title": note["title"],
        "content": note["content"],
        "created_at": note["created_at"],
        "updated_at": note["updated_at"],
    }


# ── Auth ──────────────────────────────────────────────────────────────────────

@app.post("/auth/register", status_code=201)
async def register(user: UserCreate):
    if len(user.username.strip()) < 3:
        raise HTTPException(status_code=400, detail="Username must be at least 3 characters")
    if len(user.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    existing = await db.users.find_one({"username": user.username})
    if existing:
        raise HTTPException(status_code=400, detail="Username already taken")

    hashed = get_password_hash(user.password)
    await db.users.insert_one({"username": user.username, "hashed_password": hashed})
    return {"message": "Account created successfully"}


@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = await db.users.find_one({"username": form_data.username})
    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(
        data={"sub": user["username"]},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}


# ── Notes ─────────────────────────────────────────────────────────────────────

@app.get("/notes")
async def get_notes(current_user: dict = Depends(get_current_user)):
    notes = []
    async for note in db.notes.find({"username": current_user["username"]}).sort("created_at", -1):
        notes.append(serialize_note(note))
    return notes


@app.post("/notes", status_code=201)
async def create_note(note: NoteCreate, current_user: dict = Depends(get_current_user)):
    now = datetime.utcnow()
    doc = {
        "username": current_user["username"],
        "title": note.title,
        "content": note.content,
        "created_at": now,
        "updated_at": now,
    }
    result = await db.notes.insert_one(doc)
    doc["_id"] = result.inserted_id
    return serialize_note(doc)


@app.put("/notes/{note_id}")
async def update_note(
    note_id: str, note: NoteUpdate, current_user: dict = Depends(get_current_user)
):
    try:
        oid = ObjectId(note_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid note ID")

    existing = await db.notes.find_one({"_id": oid, "username": current_user["username"]})
    if not existing:
        raise HTTPException(status_code=404, detail="Note not found")

    update_data: dict = {"updated_at": datetime.utcnow()}
    if note.title is not None:
        update_data["title"] = note.title
    if note.content is not None:
        update_data["content"] = note.content

    await db.notes.update_one({"_id": oid}, {"$set": update_data})
    updated = await db.notes.find_one({"_id": oid})
    return serialize_note(updated)


@app.delete("/notes/{note_id}", status_code=204)
async def delete_note(note_id: str, current_user: dict = Depends(get_current_user)):
    try:
        oid = ObjectId(note_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid note ID")

    existing = await db.notes.find_one({"_id": oid, "username": current_user["username"]})
    if not existing:
        raise HTTPException(status_code=404, detail="Note not found")

    await db.notes.delete_one({"_id": oid})
