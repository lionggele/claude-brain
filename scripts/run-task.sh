#!/bin/bash
# Run the next pending task from the project's task queue.
# Usage:
#   bash run-task.sh              # Semi-auto: one task, you review
#   bash run-task.sh --auto       # Fully auto: ralph-loop all tasks
#   bash run-task.sh --task T05   # Run a specific task
#
# Prerequisites:
#   - Must be run from a project root with docs/superpowers/tasks/TRACKER.md
#   - Claude Code CLI must be available as 'claude'

set -e

MODE="semi"
SPECIFIC_TASK=""
MAX_ITERATIONS=20

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto) MODE="auto"; shift;;
        --task) SPECIFIC_TASK="$2"; shift 2;;
        --max-iterations) MAX_ITERATIONS="$2"; shift 2;;
        -h|--help)
            echo "Usage: run-task.sh [--auto] [--task T05] [--max-iterations 20]"
            echo ""
            echo "Options:"
            echo "  --auto              Ralph-loop mode: run all tasks until done"
            echo "  --task T05          Run a specific task instead of next pending"
            echo "  --max-iterations N  Max iterations for auto mode (default: 20)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1;;
    esac
done

# Verify we're in a project with a task tracker
TRACKER="docs/superpowers/tasks/TRACKER.md"
if [ ! -f "$TRACKER" ]; then
    echo "Error: No $TRACKER found. Are you in the right project directory?"
    exit 1
fi

TASK_PROMPT="Read docs/superpowers/tasks/TRACKER.md and find the next task with status 'pending'. Read that task's .md file from docs/superpowers/tasks/ and execute it following the brain-task-runner skill. Self-evaluate against acceptance criteria. On success: commit and update TRACKER.md to 'completed'. On failure after 3 attempts: stash, update TRACKER.md to 'blocked'. Output <promise>TASK COMPLETE</promise> when done with one task."

if [ -n "$SPECIFIC_TASK" ]; then
    TASK_PROMPT="Read docs/superpowers/tasks/${SPECIFIC_TASK}*.md and execute it following the brain-task-runner skill. Self-evaluate against acceptance criteria. On success: commit and update TRACKER.md to 'completed'. On failure after 3 attempts: stash, update TRACKER.md to 'blocked'. Output <promise>TASK COMPLETE</promise> when done."
fi

if [ "$MODE" = "auto" ]; then
    echo "=== Task Runner: AUTO MODE ==="
    echo "Max iterations: $MAX_ITERATIONS"
    echo "Will process all pending tasks sequentially."
    echo "Press Ctrl+C to stop."
    echo ""

    ITERATION=0
    while [ $ITERATION -lt $MAX_ITERATIONS ]; do
        ITERATION=$((ITERATION + 1))
        echo "--- Iteration $ITERATION / $MAX_ITERATIONS ---"

        # Check if any pending tasks remain
        PENDING=$(grep -c "| pending |" "$TRACKER" 2>/dev/null || echo "0")
        if [ "$PENDING" = "0" ]; then
            echo "All tasks complete!"
            break
        fi

        echo "Pending tasks: $PENDING"
        echo "$TASK_PROMPT" | claude --continue 2>&1

        echo ""
        echo "--- Iteration $ITERATION done ---"
        echo ""
    done

    echo "=== Task Runner finished. $ITERATION iterations. ==="
else
    echo "=== Task Runner: SEMI-AUTO MODE ==="
    echo "Will execute one task, then stop for your review."
    echo ""

    echo "$TASK_PROMPT" | claude --continue 2>&1

    echo ""
    echo "=== Task complete. Review the diff with: git diff HEAD~1 ==="
    echo "Run again for next task: bash ~/.claude/brain/scripts/run-task.sh"
fi
