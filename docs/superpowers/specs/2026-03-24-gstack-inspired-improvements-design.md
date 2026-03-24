# Design: gstack-Inspired Improvements for claude-brain

**Date:** 2026-03-24
**Status:** Approved
**Source:** Analysis of [garrytan/gstack](https://github.com/garrytan/gstack) ARCHITECTURE.md and skill definitions

## Summary

Incrementally add the best ideas from gstack to claude-brain, ordered by impact-to-effort ratio. Five phases, each building on the previous. No browser daemon, no telemetry backend, no bloat -- just markdown, shell scripts, and hooks.

## Principles

- Stay lightweight: markdown + shell scripts, no compiled binaries or package managers
- Role-aware: new features leverage the existing 10-role system
- Backwards-compatible: existing workflows don't break
- Incremental: each phase is independently useful

---

## Phase 1: Safety Hooks

**Goal:** Prevent destructive commands and scope creep during debugging.

### `/brain-careful` (PreToolUse hook on Bash)

Pattern-match commands against destructive patterns:
- `rm -rf` (except node_modules, dist, __pycache__, .venv, build)
- `DROP TABLE`, `DROP DATABASE`, `TRUNCATE`
- `git push --force`, `git push -f` (to main/master)
- `git reset --hard`
- `git checkout .`, `git restore .`
- `kubectl delete`
- `docker system prune`

Implementation:
- `shared/hooks/check-careful.sh` -- reads stdin (the command), returns exit 2 + warning message if destructive
- `shared/skills/careful/SKILL.md` -- slash command to enable/disable per session
- Wired into `hooks.json` as PreToolUse on Bash tool

### `/brain-freeze` (PreToolUse hook on Edit/Write)

Restrict edits to a single directory during debugging:
- `~/.claude/brain/.local/freeze-dir.txt` -- contains the allowed path
- `shared/hooks/check-freeze.sh` -- reads the file_path argument, blocks if outside freeze dir
- `/brain-freeze <dir>` enables, `/brain-unfreeze` removes

### Deliverables
- `shared/hooks/check-careful.sh`
- `shared/hooks/check-freeze.sh`
- `shared/skills/careful/SKILL.md`
- `shared/skills/freeze/SKILL.md`
- Updated `activate-role.sh` to wire hooks

---

## Phase 2: Structured Code Review Skill

**Goal:** Checklist-driven code review that's role-aware.

### `/brain-review`

Two-pass review:

**Pass 1 -- Critical (blocks merge):**
- SQL injection (f-string interpolation in queries)
- Race conditions / TOCTOU
- Secrets in code (API keys, passwords, tokens)
- LLM output trust boundaries (unsanitized LLM output in SQL/HTML/commands)
- Error handling gaps (bare except, swallowed errors)
- Missing input validation at system boundaries

**Pass 2 -- Quality (informational):**
- Scope drift: compare diff against `context.md` "Active Work" section
- Dead code / unused imports
- Test coverage gaps
- Naming consistency
- Resource cleanup (connections, file handles)
- Proper HTTP status codes

**Role-specific checks:**
- backend: parameterized queries, connection pooling, migration files
- frontend: XSS prevention, bundle size, accessibility
- devops: hardcoded secrets, IaC drift, health checks
- security: OWASP Top 10 pass
- data-engineer: batch operations, NUL byte handling

**Behavior:**
- Auto-fix obvious issues (formatting, unused imports)
- Batch ambiguous issues for human decision
- Output: structured checklist with pass/fail per item

### Deliverables
- `shared/skills/review/SKILL.md`
- `shared/skills/review/checklist.md` (the actual checklist)
- Role-specific checklist extensions in `roles/<role>/review-checklist.md`

---

## Phase 3: Smarter Learning System

**Goal:** Make smart-capture actively helpful instead of passive.

### Fuzzy matching for corrections
- When capturing a new learning, scan existing corrections.md for semantic overlap
- Group related learnings (e.g., "no f-string SQL" + "parameterize queries" = same rule)
- Bump confidence of the existing learning instead of creating duplicates

### Auto-capture hook
- PostToolUse hook that detects correction patterns in user messages:
  - "no", "don't", "stop", "use X instead", "that's wrong"
- Auto-suggests `/brain-smart-capture` with pre-filled correction text
- User confirms or dismisses

### Learning decay
- Add `last_seen: YYYY-MM-DD` to each correction entry
- Learnings not referenced in 6+ months get flagged in `/brain-brain-status`
- `/brain-learning-review` skill to batch review, merge, prune, or promote

### Audit trail
- Each correction gets a `session: YYYY-MM-DD-HH:MM` field
- Links back to session summary where it was captured

### Deliverables
- Updated `scripts/smart-capture.sh` with fuzzy matching
- `shared/hooks/detect-correction.sh` (auto-capture hook)
- `shared/skills/learning-review/SKILL.md`
- Updated corrections.md format with `last_seen` and `session` fields

---

## Phase 4: Session Automation & Analytics

**Goal:** Track session patterns and automate session lifecycle.

### Session tracking
- On session start: touch `~/.claude/brain/.local/sessions/$PPID`
- Track session duration, skills used, corrections captured

### Session-end reminder
- Hook or convention: remind user to run `/brain-session-summary` if session had significant work (>5 tool calls, or any corrections captured)

### `/brain-retro` (git analytics)
- Analyze git log for configurable time window (default 7 days)
- Metrics:
  - Commits by type (feat/fix/refactor/docs)
  - LOC changed
  - Test ratio (test files changed / total files changed)
  - Hotspot files (most-changed)
  - Learnings captured this period
  - Skills used this period
- Save snapshot to `projects/<name>/retros/YYYY-MM-DD.json`
- Week-over-week comparison when previous snapshot exists

### Skill usage logging
- Append to `~/.claude/brain/.local/analytics/skill-usage.jsonl`:
  ```json
  {"skill": "spike", "project": "gt-rag-baseline-service", "ts": "2026-03-24T10:30:00Z"}
  ```

### Deliverables
- `shared/skills/retro/SKILL.md`
- Session tracking in `.local/sessions/`
- Analytics in `.local/analytics/`
- Updated skill SKILL.md files to log usage

---

## Phase 5: Workflow Pipeline

**Goal:** Chain skills together for common workflows.

### `/brain-pipeline`
- Configurable skill chains:
  - `research`: spike -> api-design -> review
  - `build`: (work) -> review -> session-summary
  - `ship`: review -> (commit) -> session-summary
- Auto-advances between steps unless human decision needed
- Each step logs to pipeline state file

### Repo mode detection
- Analyze 90-day git history
- If top author >= 80% of commits: solo mode (proactively fix)
- Otherwise: collaborative mode (ask before fixing)
- Cache result in `projects/<name>/repo-mode.json` (7-day TTL)

### Project auto-detection
- On session start, detect project from cwd
- Auto-load matching `projects/<name>/context.md`
- If no project exists, suggest `init-project.sh`

### Deliverables
- `shared/skills/pipeline/SKILL.md`
- `scripts/repo-mode.sh`
- Updated `init-project.sh` with auto-detection logic

---

## Explicitly NOT building

| gstack feature | Why not |
|---|---|
| Browser daemon (Chromium + Playwright) | 58MB binary, overkill for our needs |
| Telemetry backend (Supabase) | Unnecessary infrastructure |
| 250-line preamble per skill | Prompt bloat |
| "Boil the Lake" philosophy | Onboarding friction |
| Contributor mode | Self-referential, no user value |
| Template generation system (SKILL.md.tmpl) | Brain is small enough to maintain by hand |
| Cross-tool session discovery | Only supporting Claude Code |
| Cookie decryption / SQLite | No browser = no cookies |

---

## Implementation Order

| Phase | Effort | Impact | Dependencies |
|---|---|---|---|
| 1. Safety Hooks | ~2 hours | High (prevents damage) | None |
| 2. Code Review | ~3 hours | High (enforces quality) | Phase 1 (uses freeze during review) |
| 3. Smarter Learning | ~4 hours | Medium (compounds over time) | None |
| 4. Session Analytics | ~3 hours | Medium (visibility) | Phase 3 (tracks learnings) |
| 5. Workflow Pipeline | ~4 hours | Medium (automation) | Phase 1-4 (chains them) |
