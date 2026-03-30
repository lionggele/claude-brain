---
name: brain-task-runner
description: Execute self-contained task files from a project task queue. Picks up next pending task, executes it, self-evaluates, commits on success, retries or blocks on failure. Inspired by autoresearch experiment loop + ralph-loop iteration pattern.
---

# Task Runner

Autonomous task execution system. Each task is a self-contained .md file with everything needed for a fresh session. Tasks live in the project's `docs/superpowers/tasks/` folder.

## When to Use

- User says "run next task", "pick up next task", "continue tasks"
- User runs `bash ~/.claude/brain/scripts/run-task.sh`
- Ralph-loop feeds this skill repeatedly in `--auto` mode

## Core Loop (One Task Per Session)

```
1. READ  → docs/superpowers/tasks/TRACKER.md
2. PICK  → First task with status "pending"
3. READ  → The task's .md file
4. EXEC  → Follow the task's steps exactly
5. TEST  → Run acceptance criteria checks
6. EVAL  → Pass? commit + mark done. Fail? retry or block.
7. LOG   → Update TRACKER.md with results
```

## Step 1: Read TRACKER.md

```bash
cat docs/superpowers/tasks/TRACKER.md
```

Find the first row where Status = `pending` AND Blocked By = `-` (no blockers) or all blocker tasks are `completed`.

**Dependency check:** If a task has `Blocked By: T04`, verify T04's status is `completed` before starting. Skip blocked tasks and pick the next unblocked one.

If no pending unblocked tasks exist, output:
```
<promise>ALL TASKS COMPLETE</promise>
```

## Step 2: Claim the Task

Update TRACKER.md: change the task's status from `pending` to `in_progress`.

## Step 3: Read and Execute the Task File

Each task file (e.g., `T01-ifctester.md`) contains:

```markdown
# T01: [Title]

## Context
[What this task is about, why it matters]

## Files
- Modify: `exact/path/to/file.py`
- Create: `exact/path/to/new_file.py`
- Test: `tests/path/to/test.py`

## Research (auto)
[Optional: context7 queries to run before starting]
- context7: <library> "<query>"

## Steps
- [ ] Step 1: ...
- [ ] Step 2: ...
- [ ] Step 3: ...

## Acceptance Criteria
- [ ] Tests pass: `pytest tests/path/ -v`
- [ ] Build passes: `cd backend && python -c "from app.main import app"`
- [ ] [Feature-specific check]

## Commit
message: "feat: [description]"
files: [list of files to stage]
```

**Execute in order:**
1. If `## Research (auto)` section exists, call context7 MCP tools for each query
2. Follow each step in `## Steps`
3. After all steps, run `## Acceptance Criteria` checks

## Step 4: Self-Evaluate

Run every acceptance criteria check. Track results:

```
- Tests: PASS/FAIL
- Build: PASS/FAIL
- Feature check: PASS/FAIL
```

### If ALL PASS:
1. Stage and commit the files listed in `## Commit`
2. Update TRACKER.md:
   - Status: `completed`
   - Result: `success`
   - Attempts: increment
   - Notes: brief summary of what was done
3. Output: `<promise>TASK COMPLETE</promise>`

### If ANY FAIL (attempt < 3):
1. Read the error output carefully
2. Fix the issue
3. Re-run acceptance criteria
4. Increment attempt counter
5. Loop back to self-evaluate

### If STILL FAILING (attempt >= 3):
1. `git stash` uncommitted changes (save work for next session)
2. Update TRACKER.md:
   - Status: `blocked`
   - Result: `failed`
   - Attempts: 3
   - Notes: what failed and why (detailed enough for next session to pick up)
3. Output: `<promise>TASK BLOCKED</promise>`

## Step 5: Retrospective (Failure-Triggered)

Run a retrospective when you encounter **2+ consecutive BLOCKED tasks** (not on a cadence).

1. Review all blocked tasks in TRACKER.md
2. Identify patterns: missing context? wrong file paths? dependency issues?
3. If learnings found, save via smart-capture:
   ```bash
   bash ~/.claude/brain/scripts/smart-capture.sh \
     --role fullstack --confidence 0.3 --seen 1 \
     "<learning>. Why: <reason>"
   ```
4. Update remaining task files to fix the pattern (add missing context, fix paths)

## TRACKER.md Format

```markdown
# Task Tracker
Project: [project name]
Updated: [date]

## Summary
| Metric | Value |
|--------|-------|
| Total | N |
| Completed | N |
| In Progress | N |
| Blocked | N |
| Pending | N |
| Avg Attempts | N.N |

## Tasks
| ID | Task | Status | Track | Attempts | Result | Notes |
|----|------|--------|-------|----------|--------|-------|
| T01 | Description | pending | backend | 0 | - | - |
```

Valid statuses: `pending`, `in_progress`, `completed`, `blocked`, `skipped`
Valid results: `-`, `success`, `failed`

## Task File Template

When creating new task files, use this template:

```markdown
# [ID]: [Title]

## Context
[2-3 sentences: what this does and why it matters]
[Reference to master plan section if applicable]

## Prerequisites
[Other task IDs that must be completed first, or "none"]

## Files
- Modify: `path/to/file.py`
- Create: `path/to/new.py`
- Test: `tests/path/test.py`

## Research (auto)
- context7: <library> "<specific query>"

## Steps
- [ ] Step 1: [action with code block]
- [ ] Step 2: [action with code block]
- [ ] ...

## Acceptance Criteria
- [ ] `command to run` passes
- [ ] [Specific behavioral check]

## Commit
message: "type: description"
files:
  - path/to/file1.py
  - path/to/file2.py
```

## Auto Mode (Ralph Loop Integration)

When running with `--auto` flag, the task runner operates in ralph-loop style:
- Same prompt repeated each iteration
- Each iteration picks up next pending task from TRACKER.md
- Self-evaluates and commits on success
- Continues until all tasks done or max iterations reached
- Use `<promise>ALL TASKS COMPLETE</promise>` to signal completion

## Key Rules

1. **Never skip acceptance criteria.** If tests aren't defined, the task is incomplete.
2. **Never force-push or amend.** Each task = new commit.
3. **Always update TRACKER.md.** It's the source of truth.
4. **Respect prerequisites.** Don't start a task if its prereqs aren't completed.
5. **Log failures honestly.** A blocked task with good notes is more valuable than a falsely-completed one.
