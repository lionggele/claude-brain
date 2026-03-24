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
3. Symlinks all 10 skills to `~/.claude/skills/brain-*` (auto-discovered by Claude Code)
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
| `/brain-brain-status` | Show active role, skills, learnings | Start of session, after role switch |
| `/brain-spike` | Time-boxed research with decision doc | Before choosing a technology or pattern |
| `/brain-smart-capture` | Save correction with confidence score | When Claude makes a mistake you want remembered |
| `/brain-session-summary` | Save what was done + learnings | End of session |
| `/brain-project-context` | Load/save project artifacts | Start of session in a project |

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
# Simple capture
bash ~/.claude/brain/scripts/capture-learning.sh --role backend "Use execute_values for batch inserts. Why: 10x faster"

# Smart capture with confidence
bash ~/.claude/brain/scripts/smart-capture.sh --role backend --confidence 0.3 --seen 1 "Always use connection pooling"

# Bump existing learning
bash ~/.claude/brain/scripts/smart-capture.sh --role backend --confidence 0.6 --seen 3 "Always use connection pooling"

# Promote to permanent rule
bash ~/.claude/brain/scripts/smart-capture.sh --role backend --promote "Always use connection pooling"
```

### View Learnings (Terminal)

```bash
bash ~/.claude/brain/scripts/list-learnings.sh
```

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
    skills/                              <- 10 skill definitions
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
    hooks/
      block-secrets.sh
      notify-done.sh
  roles/
    backend/
      CLAUDE.md                          <- backend-specific rules
      hooks.json                         <- backend-specific hooks
      memory/corrections.md              <- backend learnings
    frontend/...
    devops/...
    (10 roles total)
  projects/
    my-project/
      context.md                         <- project living memory
      artifacts/                         <- decision docs
  scripts/
    install.sh
    activate-role.sh
    init-project.sh
    smart-capture.sh
    capture-learning.sh
    session-summary.sh
    list-learnings.sh
    sync.sh
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
| Skills | 10 (domain-focused) | 125 (kitchen sink) | 28 (sprint pipeline) |
| Role switching | 10 roles + composition | No | No |
| Learning system | Confidence-scored corrections | Instincts (complex YAML) | `/retro` (manual) |
| Per-project context | Artifacts + context.md | No | `~/.gstack/projects/` |
| Team sharing | `--mode copy` into repo | Everyone installs npm | `cp -Rf` into repo |
| Gets smarter over time | Yes (auto-promotion) | Yes (instinct evolution) | No |

### What We Took From Each

**From ECC:** Confidence-scored learning (their "instincts" concept, simplified to corrections.md with scores instead of YAML files)

**From gstack:** Artifact persistence per project, copy-into-project mode for teams, sequential pipeline concept (plan -> build -> review)

---

## Quick Reference Card

```
TERMINAL                                    CLAUDE CODE CLI
-------------------------------------      --------------------------------
bash ~/.claude/brain/scripts/               /brain-brain-status
  activate-role.sh <role>                   /brain-spike
  activate-role.sh backend+devops           /brain-api-design
  init-project.sh <name> --role <role>      /brain-rag-pipeline
  smart-capture.sh --role <r> "text"        /brain-agent-design
  list-learnings.sh                         /brain-service-scaffold
  session-summary.sh "text"                 /brain-smart-capture
  sync.sh                                   /brain-session-summary
                                            /brain-project-context
                                            /brain-capture-learning
```

## Typical Session Flow

```
1. Open terminal in project directory
2. Start Claude Code: `claude`
3. Claude auto-loads brain rules + skills
4. Use /brain-brain-status to verify
5. Work normally -- brain rules apply automatically
6. If Claude makes a mistake, correct it -- smart-capture saves it
7. For decisions, use /brain-spike -- saves artifact
8. End session: /brain-session-summary
9. Push memory: bash ~/.claude/brain/scripts/sync.sh
```
