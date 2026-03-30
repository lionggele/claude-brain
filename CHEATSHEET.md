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

### Autonomous Building (NEW)

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/brain-loop plan` | Interactive planning (95% confidence gate) | Starting a feature |
| `/brain-loop build 10` | Build 10 tasks autonomously | Implementing a plan |
| `/brain-loop auto 20` | Fully unattended build (AFK) | Going to lunch/overnight |
| `/brain-loop autoresearch <target>` | Optimize a skill/prompt via binary evals | Weekly self-improvement |

### Enhanced Code Review (NEW)

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/brain-review-v2` | 5-agent parallel review with confidence scoring | Before committing (replaces /brain-review) |

Runs 4 agents in parallel (critical, quality, history, silent-failures), then a confidence scorer filters noise. Optional Codex cross-check with `BRAIN_CODEX_REVIEW=1`.

### Self-Improvement (NEW)

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/brain-autoresearch` | Optimize any skill/role via binary evals | Weekly: optimize most-used skill |

Targets: `roles/*/CLAUDE.md`, `skills/*/SKILL.md`, `review-v2/checklist.md`, `hooks/*.sh`

### Legacy

| Command | What It Does |
|---------|-------------|
| `/brain-capture-learning` | Simple capture (no confidence scoring, use smart-capture instead) |
| `/brain-review` | Single-pass review (replaced by review-v2) |

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
    skills/                              <- 18 skill definitions
      loop/SKILL.md + loop.sh + templates/ <- NEW: plan/build/auto harness
      review-v2/SKILL.md + agents/     <- NEW: 5-agent review
      autoresearch/SKILL.md            <- NEW: self-improvement engine
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
    evals/                               <- NEW: binary eval suites
      review/scenarios.json + criteria.json + changelog.md
      roles/backend.yaml + frontend.yaml + fullstack.yaml
  scripts/
    install.sh
    activate-role.sh                     <- switch role + wire hooks
    init-project.sh                      <- bootstrap project integration
    brain-loop.sh                        <- NEW: iterative agent harness
    run-autoresearch.sh                  <- NEW: convenience autoresearch
    codex-session.py                     <- NEW: Codex co-worker manager
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
  brain-loop.sh plan                        /brain-service-scaffold
  brain-loop.sh 10                          /brain-smart-capture
  brain-loop.sh auto 20                     /brain-session-summary
  brain-loop.sh autoresearch <target>       /brain-project-context
  run-autoresearch.sh --target <f>          /brain-safe (freeze/unfreeze)
  smart-capture.sh --role <r> "text"        /brain-review-v2 (NEW)
  list-learnings.sh                         /brain-loop (NEW)
  session-summary.sh "text"                 /brain-autoresearch (NEW)
  sync.sh                                   /brain-review (legacy)
                                            /brain-learning-review
                                            /brain-retro
                                            /brain-pipeline
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
8. Before committing: /brain-review-v2 (multi-agent review)
9. End session: /brain-session-summary
10. End of week: /brain-retro + /brain-autoresearch on most-used skill
11. Push memory: bash ~/.claude/brain/scripts/sync.sh
```

## Autonomous Build Flow (NEW)

```
1. Describe what you want to build
2. brain-loop.sh plan          <- asks questions until 95% confident
3. Review IMPLEMENTATION_PLAN.md
4. brain-loop.sh 5             <- builds 5 tasks, one per iteration
5. brain-loop.sh auto 20       <- go AFK, builds autonomously
6. Come back: git log --oneline -20 + cat IMPLEMENTATION_PLAN.md
7. /brain-review-v2            <- review everything built
8. /brain-session-summary
```

## Self-Improvement Cycle (NEW)

```
Daily:    Corrections accumulate via smart-capture
Weekly:   /brain-autoresearch review-v2/checklist.md (15 experiments, ~$1.50)
Monthly:  /brain-autoresearch roles/backend/CLAUDE.md (20 experiments, ~$2)
Check:    open ~/.claude/brain/shared/evals/<target>/dashboard.html
```

---

## Changelog

### 2026-03-29: Enhancement Library (v2)
- Added: brain-loop (plan/build/auto/autoresearch modes) -- clone of ralph-loop harness
- Added: brain-review-v2 (5-agent parallel review with confidence scoring)
- Added: brain-autoresearch (self-improvement engine with binary evals)
- Added: codex-session.py for optional Codex cross-check in reviews
- Added: evals/ directory for binary eval suites
- Added: new pipeline chains (full autonomous build, enhanced review, self-improvement)
- Moved: /brain-review to legacy (replaced by review-v2)

### 2026-03-24: Initial Release (v1)
- 10 roles, 15 skills, safety hooks, learning system, pipelines, retro analytics
