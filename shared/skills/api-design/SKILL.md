---
name: brain-api-design
description: Design microservice APIs with OpenAPI-first approach, contract-driven development, and proper HTTP semantics. Use when planning new endpoints, designing service boundaries, or reviewing API contracts.
---

# API Design

When the user needs to design an API endpoint or microservice boundary:

## Step 1: Define the Contract First

Before writing any code, produce an OpenAPI snippet:

```yaml
paths:
  /api/v1/{resource}:
    post:
      summary: What this does (1 line)
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateResourceRequest'
      responses:
        '201':
          description: Created
        '400':
          description: Validation error
        '409':
          description: Conflict (already exists)
```

## Step 2: Apply These Rules

**HTTP Semantics:**
- POST = create (201), GET = read (200), PUT = full replace (200), PATCH = partial update (200), DELETE = remove (204)
- Never use 200 for errors. Use 4xx for client errors, 5xx for server errors.
- Return Location header on 201 Created

**Naming:**
- Plural nouns for collections: `/users`, `/documents`
- Nested for ownership: `/users/{id}/documents`
- Verbs only for actions: `/users/{id}/activate`

**Pagination:**
- Default: `?page=1&limit=20`
- Return meta: `{ total, page, limit, pages }`
- Cap limit at 100

**Versioning:**
- URL prefix: `/api/v1/`
- Never break existing contracts

**Idempotency:**
- POST with `Idempotency-Key` header for create operations
- PUT and DELETE are naturally idempotent

## Step 3: Response Envelope

Always use consistent response format:

```typescript
interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: {
    code: string       // machine-readable: "VALIDATION_ERROR"
    message: string    // human-readable
    details?: unknown  // field-level errors
  }
  meta?: {
    total: number
    page: number
    limit: number
  }
}
```

## Step 4: Validation at Boundaries

```python
# FastAPI example
from pydantic import BaseModel, Field

class CreateUserRequest(BaseModel):
    email: str = Field(..., regex=r'^[\w.-]+@[\w.-]+\.\w+$')
    name: str = Field(..., min_length=1, max_length=100)
```

```typescript
// NestJS example
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
})
```

## Step 5: Rate Limiting

Every public endpoint needs rate limiting:
- Auth endpoints: 5 req/min
- Read endpoints: 100 req/min
- Write endpoints: 30 req/min
- Return `X-RateLimit-Remaining` and `Retry-After` headers

## Step 6: Save Decision to Artifacts

After finalizing the design, save it:
```bash
mkdir -p ~/.claude/brain/projects/<project>/artifacts
# Save the API contract as an artifact for future sessions
```

## Microservice Boundary Checklist

Before splitting into a separate service, verify:
- [ ] Independent data store (no shared DB)
- [ ] Clear bounded context (single domain)
- [ ] Independent deployment cycle
- [ ] Async communication where possible (events > sync calls)
- [ ] Circuit breaker for downstream calls
- [ ] Health check endpoint: `GET /health`
- [ ] Structured JSON logging with correlation ID
