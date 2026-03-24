# Claude Brain

A portable, evolving configuration layer for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Role-based profiles, 15 domain skills, safety hooks, structured code review, and a learning system that gets smarter with every session.

One install. Every project. Every session.

## Why

Claude Code is powerful out of the box, but it starts fresh every time. It doesn't remember your preferences, your stack, your past mistakes, or your team's conventions.

Claude Brain fixes that. It gives Claude Code:

- **Persistent memory** -- corrections and learnings that carry across sessions
- **Role awareness** -- different rules for backend vs frontend vs devops work
- **Domain skills** -- slash commands for API design, RAG pipelines, code review, and more
- **Safety hooks** -- automatic guards against destructive commands
- **Project context** -- per-project artifacts and decision history

## Quick Start

```bash
git clone https://github.com/lionggele/claude-brain.git ~/Projects/claude-brain
cd ~/Projects/claude-brain
bash install.sh
```

That's it. Every Claude Code session now loads brain rules and registers `/brain-*` slash commands automatically.

### Set Up a Project

```bash
cd ~/Projects/my-api
bash ~/.claude/brain/scripts/init-project.sh my-api --role backend
```

### Switch Roles

```bash
bash ~/.claude/brain/scripts/activate-role.sh backend         # single role
bash ~/.claude/brain/scripts/activate-role.sh backend+devops   # compose roles
```

## How It Works

```
~/.claude/CLAUDE.md                         ← Claude Code reads this globally
  └─ @~/.claude/brain/CLAUDE.md             ← brain entry point
       ├─ @shared/CLAUDE.md                 ← shared rules (all roles)
       ├─ @roles/backend/CLAUDE.md          ← active role rules
       └─ @shared/memory/corrections.md     ← accumulated learnings

~/.claude/skills/brain-*/SKILL.md           ← auto-discovered slash commands
```

Open Claude Code in any directory → brain rules load → skills register → safety hooks activate. Zero manual steps.

## Roles

Ten composable roles, each with a thinking style, preferred stack, and coding rules.

| Role | Focus |
|------|-------|
| `backend` | APIs, databases, async Python/Node, SQL safety |
| `frontend` | React, accessibility, bundle size, component design |
| `fullstack` | Frontend + backend combined |
| `devops` | Infrastructure as Code, CI/CD, Docker, Kubernetes |
| `data-engineer` | ETL, batch operations, pgvector, embeddings |
| `research` | ML experiments, reproducibility, evaluation |
| `tech-lead` | Architecture decisions, ADRs, code review |
| `security` | OWASP Top 10, threat modeling, dependency audit |
| `mobile` | React Native, Flutter, platform conventions |
| `writer` | Technical writing, documentation, API docs |

Roles compose with `+`: `activate-role.sh backend+devops` loads both rule sets and merges their hooks.

## Skills

Fifteen slash commands available in every Claude Code session.

### Core Workflow

| Command | Purpose |
|---------|---------|
| `/brain-brain-status` | Show active role, skills, learnings |
| `/brain-spike` | Time-boxed research with decision doc |
| `/brain-smart-capture` | Save correction with confidence scoring |
| `/brain-session-summary` | End-of-session recap and learnings |
| `/brain-project-context` | Load and save project artifacts |

### Safety and Quality

| Command | Purpose |
|---------|---------|
| `/brain-safe` | Destructive command guard + freeze edits to a directory |
| `/brain-review` | Two-pass code review: critical issues then quality |
| `/brain-learning-review` | Batch review, merge, prune accumulated learnings |
| `/brain-retro` | Git analytics: commits, LOC, hotspots, trends |
| `/brain-pipeline` | Chain skills together for multi-step workflows |

### Domain

| Command | Purpose |
|---------|---------|
| `/brain-api-design` | OpenAPI-first API contract design |
| `/brain-rag-pipeline` | RAG architecture: chunking, embedding, retrieval |
| `/brain-agent-design` | Agent systems, MCP servers, orchestration |
| `/brain-service-scaffold` | Bootstrap a FastAPI or NestJS service |

## Safety Hooks

Safety hooks activate automatically on every role switch. No setup required.

**Careful mode** blocks destructive commands before they execute:

| Blocked | Examples |
|---------|---------|
| Force delete | `rm -rf /important` |
| Destructive SQL | `DROP TABLE`, `TRUNCATE` |
| Force push | `git push --force` |
| Hard reset | `git reset --hard` |
| Discard changes | `git checkout .`, `git clean -f` |

Safe targets like `node_modules`, `__pycache__`, and `dist/` are whitelisted.

**Freeze mode** restricts file edits to a single directory during debugging. Tell Claude "freeze to app/adapters/" to enable, "unfreeze" to remove.

Disable all hooks with `activate-role.sh backend --no-hooks`.

## Learning System

The brain gets smarter over time through confidence-scored corrections.

```
You correct Claude     →  saved at 0.3 (tentative)
Same correction again  →  bumped to 0.45 (growing)
Third time             →  0.6
Fourth time            →  0.75 (confident)
Sixth time             →  0.9 → auto-promoted to permanent rule
```

| Score | Label | Meaning |
|-------|-------|---------|
| 0.1–0.3 | tentative | Seen once, might be situational |
| 0.4–0.6 | growing | Seen 2–3 times, likely a real pattern |
| 0.7–0.8 | confident | Seen 4+ times, consistent preference |
| 0.9–1.0 | rule | Auto-promoted to role CLAUDE.md |

At 0.9, the learning moves from `corrections.md` into the role's permanent rules. Use `/brain-learning-review` periodically to merge duplicates and prune stale entries.

## Code Review

`/brain-review` runs a structured two-pass checklist against your current diff.

**Pass 1 — Critical** (blocks merge): SQL injection, hardcoded secrets, race conditions, LLM output trust boundaries, error handling gaps, missing input validation.

**Pass 2 — Quality** (informational): scope drift, dead code, test coverage gaps, naming consistency, resource cleanup.

Role-specific checks load automatically. Backend adds migration and async checks. Frontend adds XSS and accessibility checks. Security adds OWASP and auth checks.

## Project Context

Each project gets persistent context that carries across sessions.

```bash
bash ~/.claude/brain/scripts/init-project.sh my-api --role backend
```

Creates:
- `CLAUDE.md` in the project root (imports brain rules)
- `~/.claude/brain/projects/my-api/context.md` (stack, decisions, gotchas)
- `~/.claude/brain/projects/my-api/artifacts/` (spike results, API designs, ADRs)

Decision documents from `/brain-spike` and `/brain-api-design` save here automatically.

For team use, `--mode copy` copies brain files into the repo so teammates get them on `git clone`.

## Scripts

All scripts live in `~/.claude/brain/scripts/`.

| Script | Purpose |
|--------|---------|
| `install.sh` | One-time setup: symlinks, skills, directories |
| `activate-role.sh <role>` | Switch role, merge hooks into settings |
| `init-project.sh <name>` | Bootstrap brain integration in a project |
| `smart-capture.sh` | Save a confidence-scored correction |
| `list-learnings.sh` | Show all learnings across all roles |
| `session-summary.sh` | Save a timestamped session summary |
| `sync.sh` | Commit and push memory changes to git |

## Session Flow

```
1.  cd ~/Projects/my-api && claude          # brain loads automatically
2.  /brain-brain-status                     # verify role + skills
3.  (work normally)                         # rules enforce your standards
4.  Correct Claude when needed              # smart-capture saves it
5.  /brain-spike "pgvector vs pinecone"     # research decisions
6.  /brain-review                           # check before committing
7.  /brain-session-summary                  # save what you did
8.  /brain-retro                            # end-of-week analytics
9.  bash ~/.claude/brain/scripts/sync.sh    # push learnings to git
```

## Acknowledgments

Inspired by ideas from [gstack](https://github.com/garrytan/gstack) (safety hooks, structured review, retro analytics, skill pipelines) and [ECC](https://github.com/ecc-universal) (confidence-scored learning).

## License

MIT
