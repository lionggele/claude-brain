# Code Review Checklist

## Pass 1: Critical (Blocks Merge)

### SQL & Data Safety
- [ ] No f-string/string interpolation in SQL queries (use parameterized)
- [ ] No raw SQL without parameterized bindings
- [ ] NUL bytes stripped from text going to PostgreSQL
- [ ] Database connections closed in try/finally or context manager
- [ ] Batch operations use execute_values or executemany, not loops

### Injection & Trust Boundaries
- [ ] User input validated at system boundaries
- [ ] LLM output not passed unsanitized to SQL, HTML, shell commands, or eval
- [ ] External API responses validated before use
- [ ] No shell command construction from user input (use subprocess with list args)
- [ ] No eval/exec on untrusted data

### Race Conditions & Concurrency
- [ ] TOCTOU (time-of-check-to-time-of-use) patterns identified
- [ ] Shared mutable state protected or avoided
- [ ] Database transactions used for multi-step operations
- [ ] Idempotency considered for retry-able operations

### Secrets & Credentials
- [ ] No hardcoded API keys, passwords, tokens, or secrets
- [ ] No secrets in logs, error messages, or stack traces
- [ ] Credentials loaded from env vars or secret manager
- [ ] .env files not committed (in .gitignore)

### Error Handling
- [ ] No bare `except:` or `except Exception:` that swallows errors silently
- [ ] Errors logged with structured data (not just print)
- [ ] HTTP APIs return proper status codes (not 200 for errors)
- [ ] Resource cleanup in error paths (connections, file handles, temp files)

## Pass 2: Quality (Informational)

### Scope Drift
- [ ] Changes match the stated intent (PR title, commit message, active work in context.md)
- [ ] No unrelated refactoring mixed in
- [ ] No feature creep beyond what was asked

### Dead Code & Hygiene
- [ ] No unused imports
- [ ] No commented-out code blocks
- [ ] No unreachable code paths
- [ ] No TODO comments without tracking (link to issue or remove)

### Test Coverage
- [ ] New code paths have tests
- [ ] Edge cases covered (empty input, None, boundary values)
- [ ] Error paths tested (not just happy path)
- [ ] Integration tests for DB/API interactions (not just mocks)

### Naming & Clarity
- [ ] Variable/function names describe what, not how
- [ ] No single-letter variables outside loop counters
- [ ] Consistent naming style (snake_case for Python, camelCase for JS/TS)

### Resource Management
- [ ] Database connection pooling used (not new connection per request)
- [ ] File handles closed (context managers or try/finally)
- [ ] HTTP clients use connection pools or sessions
- [ ] Temporary files cleaned up

### API Design
- [ ] Proper HTTP methods (GET for reads, POST for creates, etc.)
- [ ] Input validation with Pydantic/schema (not manual checks)
- [ ] Pagination for list endpoints
- [ ] Rate limiting considered for public endpoints
