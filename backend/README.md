# Onda API

The iOS app reads upcoming meetings from this versioned FastAPI service. FastAPI exposes interactive OpenAPI documentation at `/docs` and the raw schema at `/openapi.json`.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e '.[dev]'
uvicorn app.main:app --reload
```

The service is then available at `http://127.0.0.1:8000`. The iOS repository automatically falls back to Core Data when the backend is unavailable.
