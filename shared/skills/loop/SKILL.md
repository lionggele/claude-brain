---
name: brain-loop
description: "Iterative agent harness. Plan work, build it one task at a time in isolated iterations, and auto-optimize prompts with autoresearch. Use when: brain loop, plan this, build it, autoresearch, optimize prompt, loop plan, loop build."
---

# Brain Loop

Plan-to-execute iterative harness. Each iteration runs Claude in a fresh context; file system + IMPLEMENTATION_PLAN.md is the memory.

## Modes

| Mode | Command | What it does |
|------|---------|-------------|
| plan | `brain-loop.sh plan` | Interactive. Asks questions until >= 95% confident, writes IMPLEMENTATION_PLAN.md |
| plan-work | `WORK_SCOPE="Add auth" brain-loop.sh plan-work` | Scoped 3-7 step plan |
| build | `brain-loop.sh [max]` | Picks one open task, completes, verifies, exits. Loop restarts. |
| auto | `brain-loop.sh auto [max]` | Fully unattended build |
| autoresearch | `brain-loop.sh autoresearch <target>` | Optimize a prompt with binary evals |

## Setting up in a project

Copy the harness and templates into the project directory:

```bash
SKILL_DIR="$HOME/.claude/brain/shared/skills/loop"
cp "$SKILL_DIR/brain-loop.sh" ./brain-loop.sh
chmod +x ./brain-loop.sh
cp "$SKILL_DIR/templates/PROMPT_plan.md" ./PROMPT_plan.md
cp "$SKILL_DIR/templates/PROMPT_plan_work.md" ./PROMPT_plan_work.md
cp "$SKILL_DIR/templates/PROMPT_build.md" ./PROMPT_build.md
cp "$SKILL_DIR/templates/AGENTS.md" ./AGENTS.md
mkdir -p skills
cp "$SKILL_DIR/templates/skills-README.md" ./skills/README.md
```

For autoresearch, also copy eval templates:

```bash
mkdir -p evals
cp "$SKILL_DIR/evals/"*.yaml ./evals/
```

## Running

```bash
# Plan (interactive TUI)
./brain-loop.sh plan

# Build 10 iterations
./brain-loop.sh 10

# Build fully unattended
./brain-loop.sh auto 20

# Optimize a prompt
./brain-loop.sh autoresearch plan
```

## Key concepts

- **IMPLEMENTATION_PLAN.md** is the agent's memory across iterations.
- **brain-loop.sh is immutable** at runtime (checksum + backup self-protection).
- **PROMPT files are mutable.** Customize or autoresearch them.
- **Role-aware.** Active brain role is injected into every iteration.
- **Domain-agnostic.** Code, research, creative, file tasks — anything.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| RALPH_AGENT | claude | Agent command to use |
| RALPH_AGENT_ARGS | (empty) | Extra args. Auto mode adds --dangerously-skip-permissions |
| WORK_SCOPE | (required for plan-work) | Scope string |
| RALPH_MAX_AUTO | 20 | Safety cap for auto mode |

## References

- [references/eval-guide.md](references/eval-guide.md) — How to write good binary evals
- [references/quick-start.md](references/quick-start.md) — End-to-end walkthrough
