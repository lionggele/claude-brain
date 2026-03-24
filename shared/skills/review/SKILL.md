---
name: brain-review
description: Two-pass code review. Pass 1 catches critical issues (SQL injection, secrets, race conditions). Pass 2 catches quality (scope drift, dead code, test gaps). Role-aware.
---

# Code Review

## Process

1. Determine scope: `git diff main...HEAD` (or `git diff` for unstaged work)
2. Load `@~/.claude/brain/shared/skills/review/checklist.md`
3. Load role-specific checklist if it exists: `@~/.claude/brain/roles/<active-role>/review-checklist.md`
4. Run Pass 1 (critical) -- quote failing lines, explain the fix
5. Run Pass 2 (quality) -- informational, doesn't block merge
6. Check scope drift: compare diff against commit messages and context.md "Active Work"
7. Auto-fix obvious issues (unused imports, formatting). Batch ambiguous ones for human decision.

## Output Format

```markdown
## Review: <scope>
**Verdict:** PASS / PASS WITH NOTES / NEEDS CHANGES

### Critical (Pass 1)
- [x] SQL safety: PASS
- [ ] Secrets: FAIL — hardcoded key in config.py:42

### Quality (Pass 2)
- Scope drift: none
- Missing test for error path in upload_handler

### Auto-fixed
- Removed unused import in parser.py

### Needs Human Decision
- Rate limiting on /v1/upload (currently unbounded)
```
