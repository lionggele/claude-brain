---
name: brain-status
description: Show the current state of the claude-brain system including active role, installed skills, learning counts, and project context. Use when asking "what's my brain status", "show brain", or "brain info".
---

# Brain Status

When the user asks about their brain status, show a dashboard:

## Gather Information

Run these commands to collect status:

```bash
# Active role
grep '@roles/' ~/.claude/brain/CLAUDE.md 2>/dev/null | sed 's/.*@roles\///' | sed 's/\/CLAUDE.md//'

# Count learnings
wc -l ~/.claude/brain/shared/memory/corrections.md 2>/dev/null
for role_dir in ~/.claude/brain/roles/*/; do
    role=$(basename "$role_dir")
    count=$(grep -c '^\- ' "$role_dir/memory/corrections.md" 2>/dev/null || echo 0)
    echo "  $role: $count"
done

# List skills
ls ~/.claude/brain/shared/skills/

# Current project
basename "$(pwd)"

# Project artifacts
ls ~/.claude/brain/projects/$(basename "$(pwd)")/artifacts/ 2>/dev/null | wc -l
```

## Display Format

```
=== Claude Brain Status ===

Role:     backend
Skills:   8 (api-design, rag-pipeline, agent-design, service-scaffold,
              spike, smart-capture, project-context, brain-status)

Learnings:
  Global:           3 entries
  Backend:          5 entries (2 confident, 1 rule)
  Data-engineer:    1 entry

Project:  cad2bim
  Artifacts:   4 decisions saved
  Last updated: 2026-03-24

High-confidence learnings (0.7+):
  - [0.8 confident] Use execute_values for batch inserts. (seen 5x)
  - [0.7 confident] Always log structured JSON. (seen 4x)

Recently promoted rules:
  - Strip NUL bytes before PostgreSQL insert (promoted 2026-03-20)
```

## When to Show

- User says "brain status", "show brain", "brain info"
- Start of a new session (briefly, 2-3 lines)
- After switching roles
- After promoting a learning to a rule
