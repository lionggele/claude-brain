# Backend Review (additive to base checklist)

- [ ] Schema changes have Alembic migration files
- [ ] Async endpoints don't call blocking I/O (no sync DB/HTTP in async context)
- [ ] Background tasks use Celery, not in-request processing for long operations
- [ ] Structured JSON logging (not print or unstructured text)
