---
name: brain-pipeline
description: Chain brain skills together for common workflows. Runs skills in sequence, auto-advancing unless human decision needed.
---

# Pipeline (Skill Chains)

Run multiple brain skills in sequence for common workflows.

## Built-in Pipelines

### Research -> Design
```
/brain-spike -> /brain-api-design -> /brain-review
```
Use when: exploring a technology choice then designing an API around it.

### Build -> Ship
```
(implement) -> /brain-review -> /brain-session-summary
```
Use when: finishing a feature and wrapping up.

### Full Cycle
```
/brain-spike -> /brain-api-design -> (implement) -> /brain-review -> /brain-session-summary
```
Use when: starting a new feature from scratch.

## How It Works

When user says "run pipeline <name>" or "research pipeline" or "build pipeline":

1. Announce which skills will run in order
2. Run each skill sequentially
3. Between skills, briefly confirm with user: "Moving to <next skill>. Continue?"
4. If user says stop, pause the pipeline
5. At the end, summarize what each step produced

### Task Execution
```
brain-task-runner -> brain-smart-capture -> brain-session-summary
```
Use when: executing tasks from a project task queue (docs/superpowers/tasks/).

## Custom Pipelines

User can say: "run spike then api-design then review"

Parse the skill names and run them in order.

## Repo Mode Detection

Before starting any pipeline, check if solo or collaborative:

```bash
# Count unique authors in last 90 days
AUTHORS=$(git log --since="90 days ago" --format="%aN" | sort -u | wc -l | tr -d ' ')
TOP_AUTHOR_PCT=$(git log --since="90 days ago" --format="%aN" | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')
TOTAL=$(git log --since="90 days ago" --oneline | wc -l | tr -d ' ')

if [ "$AUTHORS" -le 1 ] || [ "$(echo "$TOP_AUTHOR_PCT * 100 / $TOTAL" | bc)" -ge 80 ]; then
    echo "SOLO mode: proactively fix issues"
else
    echo "COLLABORATIVE mode: ask before fixing"
fi
```

In solo mode: auto-fix obvious review issues without asking.
In collaborative mode: always ask before making changes.
