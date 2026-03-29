# Ralph Loop — Quick Start

## 1. Set up a new project

```bash
# Create your project directory
mkdir my-project && cd my-project
git init

# Copy Ralph Loop files from the skill
SKILL_DIR="$HOME/.claude/skills/ralph-loop"
cp "$SKILL_DIR/loop.sh" ./loop.sh && chmod +x ./loop.sh
cp "$SKILL_DIR/templates/PROMPT_plan.md" ./
cp "$SKILL_DIR/templates/PROMPT_plan_work.md" ./
cp "$SKILL_DIR/templates/PROMPT_build.md" ./
cp "$SKILL_DIR/templates/AGENTS.md" ./
mkdir -p skills && cp "$SKILL_DIR/templates/skills-README.md" ./skills/README.md
```

Or just tell Claude: "set up ralph loop in this project"

## 2. Plan your work

```bash
./loop.sh plan
```

Claude opens in interactive TUI mode. It will:
1. Ask you clarification questions until it's >= 95% confident
2. Write `IMPLEMENTATION_PLAN.md` with tasks, acceptance criteria, and verification plan

## 3. Build it

```bash
./loop.sh           # build until all tasks done (live output)
./loop.sh 10        # build max 10 iterations
./loop.sh auto 20   # fully unattended, 20 iteration safety cap
```

Each iteration picks ONE task, completes it, verifies, updates the plan, and exits. The loop restarts automatically.

## 4. Optimize your prompts (optional)

```bash
# Copy eval templates
mkdir -p evals
cp "$SKILL_DIR/evals/"*.yaml ./evals/

# Edit evals to match YOUR project's quality standards
# Then run autoresearch
./loop.sh autoresearch plan       # optimize the plan prompt
./loop.sh autoresearch build      # optimize the build prompt
```

A live dashboard opens in your browser showing score progression.

## Example: Full workflow

```bash
# 1. Plan
./loop.sh plan
# Answer clarification questions -> IMPLEMENTATION_PLAN.md created

# 2. Build (10 iterations max)
./loop.sh 10
# Agent works through tasks one by one, exits when done

# 3. Scoped follow-up
WORK_SCOPE="Add error handling to the API endpoints" ./loop.sh plan-work
./loop.sh 5

# 4. Optimize prompts for this project
./loop.sh autoresearch build 10
# Runs 10 experiments to improve PROMPT_build.md
```

## Tips

- **IMPLEMENTATION_PLAN.md is the agent's memory.** It has no memory between iterations — the plan IS the state.
- **loop.sh is protected.** It checksums itself and auto-restores if the agent modifies it.
- **Prompts are customizable.** Edit PROMPT_*.md to change agent behavior. Use autoresearch to optimize.
- **Works for anything.** Code, research, creative projects, file tasks, docs — not just software.
