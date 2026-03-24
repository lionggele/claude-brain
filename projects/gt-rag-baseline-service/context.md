# Project: gt-rag-baseline-service
Last updated: 2026-03-24

## Stack
- **API**: FastAPI (async), uvicorn, port 8080
- **DB**: PostgreSQL 16 + pgvector (port 5433), SQLAlchemy async + asyncpg
- **Queue**: Celery + Redis (port 6380) for document ingestion
- **Embeddings**: Gemini embedding-001 (3072-D), Google Cloud AI Platform
- **PDF Parsing**: Docling (default), Unstructured (fallback), Google Document AI (paid tier)
- **OCR**: PaddleOCR, Tesseract, pdfplumber, opencv
- **Storage**: Local blob storage (dev), GCS (prod)
- **Frontend**: Separate app on port 3000
- **Monitoring**: Flower (Celery dashboard) on port 5555
- **Package manager**: uv
- **Architecture**: Hexagonal (port/adapter) -- app/adapters, app/api, app/core, app/domain, app/workers

## Key Decisions
- (Decisions will be saved here by /brain-spike and /brain-api-design)

## Active Work
- (What are you working on now?)

## Gotchas
- Redis runs on port 6380, not default 6379
- PostgreSQL runs on port 5433, not default 5432
- Credentials file expected at `credentials/botunify-gcs-key.json` for GCS access
- DB submodule at `db/schema` (bitbucket: get-rnd/database-schema)
- asyncio_mode = "auto" in pytest config (no need for @pytest.mark.asyncio)
