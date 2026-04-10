# Notes App

A simple three-tier notes application with JWT authentication.

| Layer    | Technology             |
|----------|------------------------|
| Frontend | React 18, served by Nginx |
| Backend  | FastAPI (Python)       |
| Database | MongoDB 7              |

## Architecture

```
Browser
  │
  └─► Nginx (port 80)
        ├─ /api/*  ──► FastAPI backend (internal port 8000)
        └─ /*      ──► React static build (SPA fallback)
```

Nginx acts as the single entry point. All API requests are proxied through
`/api/` — the backend is not exposed directly to the host.

## Project Structure

```
sample-app/
├── docker-compose.yml
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py        # routes
│   ├── auth.py        # JWT + password hashing
│   ├── models.py      # Pydantic schemas
│   └── database.py    # MongoDB connection
└── frontend/
    ├── Dockerfile     # multi-stage: Node build → nginx:alpine
    ├── nginx.conf     # reverse proxy + SPA config
    ├── package.json
    ├── public/index.html
    └── src/
        ├── App.js
        ├── api.js         # axios calls (base URL: /api)
        ├── index.js / index.css
        └── components/
            ├── Login.js
            ├── Register.js
            ├── Notes.js
            └── NoteForm.js
```

## Run locally

```bash
docker compose up --build
```

- App: http://localhost

## Authentication

JWT Bearer tokens — set a strong `SECRET_KEY` in `docker-compose.yml` before deploying.
