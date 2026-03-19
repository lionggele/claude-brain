# Claude Brain

Portable, evolving Claude Code brain with role-based profiles, custom skills, hooks, and a learning system that gets smarter over time.

## Quick Setup

```bash
git clone https://github.com/lionggele/claude-brain.git ~/Projects/claude-brain
cd ~/Projects/claude-brain
bash install.sh
```

## Switch Roles

```bash
bash ~/.claude/brain/scripts/activate-role.sh data-engineer
```

## Use in a Project

Add to your project's CLAUDE.md:

```
@~/.claude/brain/roles/data-engineer/CLAUDE.md
```

Or as a submodule:

```bash
git submodule add https://github.com/lionggele/claude-brain.git .claude/brain
```

## Roles

| Role | Focus |
|------|-------|
| devops | Infrastructure, CI/CD, cloud, monitoring |
| backend | APIs, databases, Python/Node |
| frontend | React, UI, CSS, design systems |
| data-engineer | Migrations, ETL, embeddings, vector DBs |
| research | ML experiments, notebooks, evaluation |
| fullstack | Frontend + Backend combined |
| tech-lead | Architecture, reviews, mentoring |
| security | Vulnerability scanning, audit, pen testing |
| mobile | React Native, Flutter, iOS/Android |
| writer | Technical writing, API docs |

## Scripts

| Script | Purpose |
|--------|---------|
| `activate-role.sh <role>` | Switch active role + hooks |
| `init-project.sh <role>` | Bootstrap CLAUDE.md in a new project |
| `capture-learning.sh "text"` | Save a correction to memory |
| `list-learnings.sh` | Show all learnings across roles |
| `sync.sh` | Commit + push memory changes |
