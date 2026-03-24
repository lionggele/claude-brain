---
name: brain-project-context
description: Automatically load project-specific artifacts (past decisions, architecture docs, spike results) when working in a project. Saves and retrieves context across sessions so decisions persist.
---

# Project Context

Manages persistent artifacts for each project so decisions survive across sessions.

## When Starting Work on a Project

1. Check if the project has artifacts:
   ```bash
   ls ~/.claude/brain/projects/<project-name>/artifacts/ 2>/dev/null
   ```

2. If artifacts exist, read the most recent ones to understand past decisions:
   ```bash
   ls -t ~/.claude/brain/projects/<project-name>/artifacts/ | head -5
   ```

3. Read `context.md` if it exists — this is the project's living memory:
   ```bash
   cat ~/.claude/brain/projects/<project-name>/context.md 2>/dev/null
   ```

## Saving Artifacts

When the user makes a significant decision, save it:

### Types of Artifacts

| Type | When to Save | Filename Pattern |
|------|-------------|-----------------|
| API design | After /brain-api-design | `YYYY-MM-DD-api-<name>.md` |
| Spike result | After /brain-spike | `YYYY-MM-DD-spike-<topic>.md` |
| Architecture decision | Major design choice | `YYYY-MM-DD-adr-<topic>.md` |
| Debug finding | Hard-to-find bug resolved | `YYYY-MM-DD-debug-<issue>.md` |
| Schema change | After migration design | `YYYY-MM-DD-schema-<name>.md` |

### Save Command

```bash
PROJECT=$(basename "$(pwd)")
ARTIFACTS_DIR="$HOME/.claude/brain/projects/$PROJECT/artifacts"
mkdir -p "$ARTIFACTS_DIR"
# Write the artifact content to the file
```

## context.md (Living Memory)

Each project has a `context.md` that gets updated as the project evolves:

```markdown
# Project: <name>
Last updated: YYYY-MM-DD

## Stack
- Backend: FastAPI + PostgreSQL
- Frontend: Next.js + TypeScript
- Infra: Docker + GCP Cloud Run

## Key Decisions
- Using pgvector for embeddings (see spike-vector-store.md)
- JWT auth with refresh tokens (see adr-auth.md)

## Active Work
- Building document ingestion pipeline
- Next: add reranking to search

## Gotchas
- PostgreSQL on port 5433 (not default 5432)
- Must strip NUL bytes before insert
```

## Updating context.md

At the end of a significant session, update the project context:

1. Read current context.md
2. Update "Last updated" date
3. Add/modify relevant sections
4. Keep it concise (under 50 lines)

```bash
PROJECT=$(basename "$(pwd)")
CONTEXT_FILE="$HOME/.claude/brain/projects/$PROJECT/context.md"
# Update the file
```

## Registering a New Project

When working in a new project for the first time:

```bash
bash ~/.claude/brain/scripts/init-project.sh <project-name> --role <role>
```

This creates:
- `~/.claude/brain/projects/<name>/context.md`
- `~/.claude/brain/projects/<name>/artifacts/`
- CLAUDE.md in the project directory (if not exists)

## Key Rule

Never lose a decision. If someone asks "why did we choose X?", the artifact should answer that question even months later.
