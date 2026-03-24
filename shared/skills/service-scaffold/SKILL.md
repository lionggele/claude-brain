---
name: brain-service-scaffold
description: Bootstrap new microservices with production-ready structure. Generates FastAPI or NestJS projects with proper layering, error handling, health checks, and Docker support. Use when starting a new service or project.
---

# Service Scaffold

When the user wants to start a new service or project:

## Step 1: Ask What Stack

1. **Language**: Python (FastAPI) or TypeScript (NestJS)?
2. **Database**: PostgreSQL, MongoDB, or none?
3. **Auth**: JWT, API key, or none?
4. **Queue**: Redis, RabbitMQ, or none?

## Step 2: Generate Structure

### FastAPI Service

```
service-name/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app, middleware, lifespan
│   ├── config.py             # Settings from env vars (pydantic-settings)
│   ├── dependencies.py       # Shared dependencies (db session, auth)
│   ├── api/
│   │   ├── __init__.py
│   │   ├── router.py         # Combines all route modules
│   │   ├── health.py         # GET /health
│   │   └── v1/
│   │       ├── __init__.py
│   │       └── {resource}.py # One file per resource
│   ├── models/
│   │   ├── __init__.py
│   │   └── {resource}.py     # SQLAlchemy/Pydantic models
│   ├── services/
│   │   ├── __init__.py
│   │   └── {resource}.py     # Business logic (no HTTP concepts)
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── {resource}.py     # Database queries only
│   └── core/
│       ├── __init__.py
│       ├── exceptions.py     # Custom exception classes
│       └── logging.py        # Structured JSON logging
├── tests/
│   ├── conftest.py           # Fixtures (test db, client)
│   ├── test_health.py
│   └── test_{resource}.py
├── alembic/                  # Database migrations
│   └── versions/
├── Dockerfile
├── docker-compose.yml
├── pyproject.toml
├── alembic.ini
└── .env.example
```

### Key Files to Generate

**config.py** (always start here):
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "service-name"
    database_url: str
    redis_url: str = ""
    log_level: str = "INFO"

    model_config = {"env_prefix": "APP_"}
```

**main.py** (lifespan pattern):
```python
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create pools, warm caches
    await db.connect()
    yield
    # Shutdown: close pools
    await db.disconnect()

app = FastAPI(lifespan=lifespan)
```

**exceptions.py** (consistent errors):
```python
from dataclasses import dataclass

@dataclass(frozen=True)
class AppError(Exception):
    code: str
    message: str
    status_code: int = 400

class NotFoundError(AppError):
    status_code: int = 404

class ConflictError(AppError):
    status_code: int = 409
```

### NestJS Service

```
service-name/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── config/
│   │   └── configuration.ts
│   ├── common/
│   │   ├── filters/exception.filter.ts
│   │   ├── interceptors/logging.interceptor.ts
│   │   └── dto/api-response.dto.ts
│   ├── health/
│   │   └── health.controller.ts
│   └── {resource}/
│       ├── {resource}.module.ts
│       ├── {resource}.controller.ts
│       ├── {resource}.service.ts
│       ├── {resource}.repository.ts
│       ├── dto/
│       └── entities/
├── test/
├── Dockerfile
├── docker-compose.yml
├── package.json
└── .env.example
```

## Step 3: Apply Standards

Every scaffold must include:

- [ ] Health check endpoint (`GET /health`)
- [ ] Structured JSON logging (not print/console.log)
- [ ] Environment-based config (never hardcoded)
- [ ] `.env.example` with all required vars
- [ ] Dockerfile (multi-stage build)
- [ ] Error handling middleware
- [ ] Input validation (Pydantic/Zod)
- [ ] CORS configuration
- [ ] Graceful shutdown

## Step 4: Docker Template

```dockerfile
# Multi-stage build
FROM python:3.12-slim AS base
WORKDIR /app
COPY pyproject.toml .
RUN pip install --no-cache-dir .

FROM base AS production
COPY app/ app/
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Step 5: Save as Project Artifact

After scaffolding, register the project:
```bash
bash ~/.claude/brain/scripts/init-project.sh <name> --role backend
```
