# Claude Brain Cheat Sheet

## Installation (One Time)

```bash
git clone https://github.com/lionggele/claude-brain.git ~/Projects/claude-brain
cd ~/Projects/claude-brain
bash install.sh
```

What `install.sh` does:
1. Symlinks repo to `~/.claude/brain/`
2. Adds `@~/.claude/brain/CLAUDE.md` to your global `~/.claude/CLAUDE.md`
3. Symlinks all 15 skills to `~/.claude/skills/brain-*` (auto-discovered by Claude Code)
4. Creates `.local/` for personal data (gitignored)
5. Creates `projects/` for per-project artifacts

After install, **every Claude Code session** on your machine loads brain rules and has access to brain skills.

---

## How It Works

```
~/.claude/CLAUDE.md                    <-- Claude Code reads this globally
  @~/.claude/brain/CLAUDE.md           <-- your brain entry point
    @shared/CLAUDE.md                  <-- shared rules (all roles)
    @roles/backend/CLAUDE.md           <-- active role rules
    @shared/memory/corrections.md      <-- learnings

~/.claude/skills/brain-*/SKILL.md      <-- skills (auto-discovered as /commands)
```

When you open Claude Code **in any directory**, it:
1. Reads `~/.claude/CLAUDE.md` -> loads brain rules via `@` imports
2. Discovers `~/.claude/skills/brain-*/SKILL.md` -> registers `/brain-*` commands
3. If the project has a local `CLAUDE.md` with `@~/.claude/brain/projects/<name>/context.md`, loads project artifacts too

---

## Daily Workflow

### Switch Role (Terminal)

```bash
# Single role
bash ~/.claude/brain/scripts/activate-role.sh backend

# Compose roles
bash ~/.claude/brain/scripts/activate-role.sh backend+devops

# Without safety hooks
bash ~/.claude/brain/scripts/activate-role.sh backend --no-hooks
```

Available roles: `backend` | `frontend` | `fullstack` | `devops` | `data-engineer` | `research` | `tech-lead` | `security` | `mobile` | `writer`

### Init a New Project (Terminal)

```bash
cd ~/Projects/my-new-api

# Personal use (symlinks to brain)
bash ~/.claude/brain/scripts/init-project.sh my-new-api --role backend

# Team use (copies brain into repo, teammates get it on git clone)
bash ~/.claude/brain/scripts/init-project.sh my-new-api --role backend --mode copy
```

This creates:
- `CLAUDE.md` in your project (imports brain rules + role)
- `~/.claude/brain/projects/my-new-api/context.md` (living memory)
- `~/.claude/brain/projects/my-new-api/artifacts/` (decision docs)

---

## Skills (Slash Commands in Claude Code)

Type these inside Claude Code CLI:

### Core Workflow

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/brain-brain-status` | Show active role, skills, learnings | Start of session |
| `/brain-spike` | Time-boxed research with decision doc | Before choosing a technology |
| `/brain-smart-capture` | Save correction with confidence score | When Claude makes a mistake |
| `/brain-session-summary` | Save what was done + learnings | End of session |
| `/brain-project-context` | Load/save project artifacts | Start of session in a project |

### Safety & Quality

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/brain-safe` | Safety mode: blocks destructive cmds, freeze edits to a dir | Auto-enabled; freeze during debugging |
| `/brain-review` | Two-pass code review (critical + quality checklist) | Before committing/merging |
| `/brain-learning-review` | Batch review/merge/prune learnings | Weekly/monthly cleanup |
| `/brain-retro` | Git analytics: commits, LOC, hotspots, trends | End of week/sprint |
| `/brain-pipeline` | Chain skills together (spike -> design -> review) | Multi-step workflows |

### Domain Skills

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/brain-api-design` | OpenAPI-first API contract design | Planning new endpoints |
| `/brain-rag-pipeline` | RAG architecture (chunking, embedding, retrieval) | Building search/Q&A systems |
| `/brain-agent-design` | Agent systems, MCP servers, orchestration | Building agentic workflows |
| `/brain-service-scaffold` | Bootstrap FastAPI/NestJS service | Starting a new microservice |

### Legacy

| Command | What It Does |
|---------|-------------|
| `/brain-capture-learning` | Simple capture (no confidence scoring, use smart-capture instead) |

---

## Safety Hooks

Safety hooks are **auto-enabled** on every role activation. They block destructive commands before they run.

### What Gets Blocked

| Pattern | Example |
|---------|---------|
| rm with force | `rm -rf /important` |
| Destructive SQL | `DROP TABLE users` |
| Force push | `git push --force` |
| Hard reset | `git reset --hard` |
| Discard changes | `git checkout .` |
| K8s delete | `kubectl delete pod` |
| Docker prune | `docker system prune` |

**Safe exceptions** (always allowed): node_modules, __pycache__, dist/, build/, .venv

### Freeze (Debug Mode)

Restrict edits to one directory during debugging:
- **Enable**: Tell Claude "freeze edits to app/adapters/"
- **Disable**: Tell Claude "unfreeze"

### Disable All Safety Hooks

```bash
bash ~/.claude/brain/scripts/activate-role.sh backend --no-hooks
```

---

## Code Review

`/brain-review` runs a structured two-pass review:

**Pass 1 (Critical):** SQL injection, secrets in code, race conditions, LLM trust boundaries, error handling
**Pass 2 (Quality):** Scope drift, dead code, test gaps, naming, resource cleanup

Role-specific checks are loaded automatically (e.g., backend adds migration checks, frontend adds XSS checks).

---

## Learning System

The brain learns from your corrections and gets smarter over time.

### How It Works

```
You correct Claude -> smart-capture detects it -> saves with confidence 0.3
Same correction again -> confidence bumps to 0.45
3rd time -> 0.6
4th time -> 0.75 (confident)
6+ times -> 0.9 (auto-promotes to permanent rule in role CLAUDE.md)
```

### Confidence Levels

| Score | Label | Meaning |
|-------|-------|---------|
| 0.1-0.3 | tentative | Seen once, might be situational |
| 0.4-0.6 | growing | Seen 2-3x, likely real |
| 0.7-0.8 | confident | Seen 4+x, consistent preference |
| 0.9-1.0 | rule | Auto-promoted to CLAUDE.md |

### Manual Capture (Terminal)

```bash
# Smart capture with confidence
bash ~/.claude/brain/scripts/smart-capture.sh --role backend --confidence 0.3 --seen 1 "Always use connection pooling"

# Bump existing learning
bash ~/.claude/brain/scripts/smart-capture.sh --role backend --confidence 0.6 --seen 3 "Always use connection pooling"

# Promote to permanent rule
bash ~/.claude/brain/scripts/smart-capture.sh --role backend --promote "Always use connection pooling"
```

### Review Learnings

```bash
# View all learnings
bash ~/.claude/brain/scripts/list-learnings.sh

# Or use the skill for batch review/merge/prune
/brain-learning-review
```

---

## Pipelines (Skill Chains)

Chain skills for common workflows:

| Pipeline | Skills | When |
|----------|--------|------|
| Research | spike -> api-design -> review | Exploring then designing |
| Build | (implement) -> review -> session-summary | Finishing a feature |
| Full Cycle | spike -> api-design -> (implement) -> review -> session-summary | New feature from scratch |

Usage: Tell Claude "run research pipeline" or "run spike then api-design then review"

---

## Retro (Analytics)

`/brain-retro` analyzes recent git history:

- Commits by type (feat/fix/refactor)
- LOC added/removed
- Hotspot files (most changed)
- Test coverage ratio
- Learnings captured in the period
- Week-over-week trends

Default: 7 days. Say "retro 30d" for monthly.

---

## Project Artifacts

Decisions persist across sessions in `~/.claude/brain/projects/<name>/artifacts/`.

### What Gets Saved

| Source | Filename Pattern | Example |
|--------|-----------------|---------|
| `/brain-spike` | `YYYY-MM-DD-spike-<topic>.md` | `2026-03-24-spike-vector-store.md` |
| `/brain-api-design` | `YYYY-MM-DD-api-<name>.md` | `2026-03-24-api-documents.md` |
| Architecture decisions | `YYYY-MM-DD-adr-<topic>.md` | `2026-03-24-adr-auth-strategy.md` |
| Debug findings | `YYYY-MM-DD-debug-<issue>.md` | `2026-03-24-debug-memory-leak.md` |

### View Artifacts (Terminal)

```bash
ls ~/.claude/brain/projects/my-project/artifacts/
cat ~/.claude/brain/projects/my-project/context.md
```

---

## File Structure

```
~/.claude/brain/                         <- symlink to your cloned repo
  CLAUDE.md                              <- entry point (imports active role)
  shared/
    CLAUDE.md                            <- rules for ALL roles
    memory/corrections.md                <- global learnings
    memory/sessions/                     <- session summaries
    skills/                              <- 15 skill definitions
      api-design/SKILL.md
      rag-pipeline/SKILL.md
      agent-design/SKILL.md
      service-scaffold/SKILL.md
      spike/SKILL.md
      smart-capture/SKILL.md
      project-context/SKILL.md
      brain-status/SKILL.md
      capture-learning/SKILL.md
      session-summary/SKILL.md
      safe/SKILL.md                      <- safety hooks (careful + freeze)
      review/SKILL.md + checklist.md     <- code review
      learning-review/SKILL.md           <- batch learning cleanup
      retro/SKILL.md                     <- git analytics
      pipeline/SKILL.md                  <- skill chains
    hooks/
      block-secrets.sh                   <- blocks committing secrets
      notify-done.sh                     <- macOS notification on finish
      check-careful.sh                   <- blocks destructive commands
      check-freeze.sh                    <- restricts edits to frozen dir
  roles/
    backend/
      CLAUDE.md                          <- backend-specific rules
      hooks.json                         <- backend-specific hooks
      memory/corrections.md              <- backend learnings
      review-checklist.md                <- backend review extras
    frontend/...
    devops/...
    (10 roles total)
  projects/
    my-project/
      context.md                         <- project living memory
      artifacts/                         <- decision docs
  scripts/
    install.sh
    activate-role.sh                     <- switch role + wire hooks
    init-project.sh                      <- bootstrap project integration
    smart-capture.sh                     <- confidence-scored learning
    capture-learning.sh                  <- simple learning capture
    session-summary.sh
    list-learnings.sh
    sync.sh                              <- git push learnings
  .local/                                <- gitignored personal data
    memory/
    sessions/

~/.claude/skills/brain-*/                <- symlinks (auto-discovered)
```

---

## Comparison with ECC and gstack

| Feature | claude-brain | ECC | gstack |
|---------|-------------|-----|--------|
| Install | `bash install.sh` | `npm install -g ecc-universal` | `git clone + ./setup` |
| Skills | 15 (focused) | 125 (kitchen sink) | 28 (sprint pipeline) |
| Role switching | 10 roles + composition | No | No |
| Learning system | Confidence-scored + auto-promote | Instincts (complex YAML) | `/retro` (manual) |
| Safety hooks | careful + freeze (auto-enabled) | No | `/careful` + `/freeze` |
| Code review | Two-pass checklist, role-aware | No | Staff-eng checklist |
| Analytics | `/brain-retro` git analytics | No | `/retro` (comprehensive) |
| Skill chains | `/brain-pipeline` | No | `/autoplan` |
| Per-project context | Artifacts + context.md | No | `~/.gstack/projects/` |
| Team sharing | `--mode copy` into repo | Everyone installs npm | `cp -Rf` into repo |

### What We Took From Each

**From ECC:** Confidence-scored learning (their "instincts" concept, simplified to corrections.md with scores instead of YAML files)

**From gstack:** Safety hooks (careful/freeze), structured code review checklist, retro analytics, skill pipeline concept, artifact persistence per project, copy-into-project mode for teams

---

## Quick Reference Card

```
TERMINAL                                    CLAUDE CODE CLI
-------------------------------------      --------------------------------
bash ~/.claude/brain/scripts/               /brain-brain-status
  activate-role.sh <role>                   /brain-spike
  activate-role.sh backend+devops           /brain-api-design
  activate-role.sh <role> --no-hooks        /brain-rag-pipeline
  init-project.sh <name> --role <role>      /brain-agent-design
  smart-capture.sh --role <r> "text"        /brain-service-scaffold
  list-learnings.sh                         /brain-smart-capture
  session-summary.sh "text"                 /brain-session-summary
  sync.sh                                   /brain-project-context
                                            /brain-safe (freeze/unfreeze)
                                            /brain-review
                                            /brain-learning-review
                                            /brain-retro
                                            /brain-pipeline
                                            /brain-capture-learning (legacy)
```

## Typical Session Flow

```
1. Open terminal in project directory
2. Start Claude Code: `claude`
3. Claude auto-loads brain rules + skills + safety hooks
4. Use /brain-brain-status to verify
5. Work normally -- brain rules apply, safety hooks protect
6. If Claude makes a mistake, correct it -- smart-capture saves it
7. For decisions, use /brain-spike -- saves artifact
8. Before committing: /brain-review
9. End session: /brain-session-summary
10. End of week: /brain-retro
11. Push memory: bash ~/.claude/brain/scripts/sync.sh
```
