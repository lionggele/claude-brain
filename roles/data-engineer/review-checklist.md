# Data Engineer Review (additive to base checklist)

- [ ] ETL jobs are idempotent (safe to re-run)
- [ ] Large datasets processed in chunks (not loaded entirely into memory)
- [ ] Pipeline failures don't leave partial/corrupt state
- [ ] Embedding dimensions match model output (e.g., 3072 for Gemini)
