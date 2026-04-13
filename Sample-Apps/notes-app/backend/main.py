from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from datetime import timedelta, datetime
from sqlalchemy import select

from database import engine, AsyncSessionLocal, Base
from models import User, Note, UserCreate, Token, NoteCreate, NoteUpdate
from auth import (
    get_password_hash,
    verify_password,
    create_access_token,
    get_current_user,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(title="Notes App API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://localhost:80"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def serialize_note(note: Note) -> dict:
    return {
        "id": str(note.id),
        "title": note.title,
        "content": note.content,
        "created_at": note.created_at,
        "updated_at": note.updated_at,
    }


# ── Auth ──────────────────────────────────────────────────────────────────────

@app.post("/auth/register", status_code=201)
async def register(user: UserCreate):
    if len(user.username.strip()) < 3:
        raise HTTPException(status_code=400, detail="Username must be at least 3 characters")
    if len(user.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.username == user.username))
        if result.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Username already taken")

        new_user = User(username=user.username, hashed_password=get_password_hash(user.password))
        session.add(new_user)
        await session.commit()

    return {"message": "Account created successfully"}


@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.username == form_data.username))
        user = result.scalar_one_or_none()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(
        data={"sub": user.username},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}


# ── Notes ─────────────────────────────────────────────────────────────────────

@app.get("/notes")
async def get_notes(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Note)
            .where(Note.username == current_user.username)
            .order_by(Note.created_at.desc())
        )
        notes = result.scalars().all()
    return [serialize_note(n) for n in notes]


@app.post("/notes", status_code=201)
async def create_note(note: NoteCreate, current_user: User = Depends(get_current_user)):
    now = datetime.utcnow()
    async with AsyncSessionLocal() as session:
        new_note = Note(
            username=current_user.username,
            title=note.title,
            content=note.content,
            created_at=now,
            updated_at=now,
        )
        session.add(new_note)
        await session.commit()
        await session.refresh(new_note)
    return serialize_note(new_note)


@app.put("/notes/{note_id}")
async def update_note(
    note_id: int, note: NoteUpdate, current_user: User = Depends(get_current_user)
):
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Note).where(Note.id == note_id, Note.username == current_user.username)
        )
        existing = result.scalar_one_or_none()
        if not existing:
            raise HTTPException(status_code=404, detail="Note not found")

        if note.title is not None:
            existing.title = note.title
        if note.content is not None:
            existing.content = note.content
        existing.updated_at = datetime.utcnow()
        await session.commit()
        await session.refresh(existing)
    return serialize_note(existing)


@app.delete("/notes/{note_id}", status_code=204)
async def delete_note(note_id: int, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Note).where(Note.id == note_id, Note.username == current_user.username)
        )
        existing = result.scalar_one_or_none()
        if not existing:
            raise HTTPException(status_code=404, detail="Note not found")

        await session.delete(existing)
        await session.commit()

