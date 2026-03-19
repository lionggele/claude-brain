---
name: session-summary
description: Generate a session summary before the session ends. Captures what was done, key decisions, and learnings for future sessions.
---

# Session Summary

When the user says "done", "that's it for now", "wrap up", or when a major task completes:

1. Write a brief summary covering:
   - **What was done**: 2-3 bullet points of key accomplishments
   - **Learnings**: Any corrections or patterns discovered
   - **To remember**: Context or decisions that future sessions should know
2. Save it by running:
   ```bash
   bash ~/.claude/brain/scripts/session-summary.sh "## What was done
   - Built X
   - Fixed Y

   ## Learnings
   - Use batch inserts for performance

   ## To remember
   - Project uses AlloyDB via SSH tunnel on port 5433"
   ```
3. Confirm the summary was saved and suggest running `bash ~/.claude/brain/scripts/sync.sh` to push it

## Keep summaries concise — 5-10 lines max.
