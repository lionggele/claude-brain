---
name: brain-learning-review
description: Review, merge, prune, or promote accumulated learnings across all roles. Use periodically to keep corrections.md clean and useful.
---

# Learning Review

Batch review of all accumulated learnings. Run periodically (weekly or monthly) to keep the learning system healthy.

## Step 1: Gather All Learnings

Read all corrections files:

```bash
echo "=== Global Learnings ==="
cat ~/.claude/brain/shared/memory/corrections.md

echo "=== Role Learnings ==="
for f in ~/.claude/brain/roles/*/memory/corrections.md; do
    role=$(echo "$f" | sed 's|.*/roles/||; s|/memory/.*||')
    echo "--- $role ---"
    cat "$f"
done
```

## Step 2: Review Each Learning

For each learning, recommend one action:

| Action | When |
|---|---|
| **Keep** | Still relevant and accurate |
| **Bump** | Confirmed multiple times, increase confidence |
| **Merge** | Two learnings say the same thing differently |
| **Prune** | No longer relevant (stack changed, rule is obvious, contradicted) |
| **Promote** | Confidence >= 0.7 and user agrees it's a permanent rule |

Present a table:

```markdown
| # | Learning | Confidence | Action | Reason |
|---|----------|-----------|--------|--------|
| 1 | Use logging not print | 0.6 growing | Bump -> 0.75 | Confirmed again this session |
| 2 | Strip NUL bytes for PG | 0.9 rule | Promote | Seen 8x, should be permanent |
| 3 | Use batch inserts | 0.3 tentative | Keep | Still learning |
| 4 | Never use Django ORM | 0.3 tentative | Prune | Was project-specific, not general |
| 5 | Parameterize queries | 0.7 confident | Merge with #6 | Same as "no f-string SQL" |
```

## Step 3: Execute Actions

After user approves the table, run the actions:

**Bump**: Update confidence and seen count in corrections.md
**Merge**: Remove duplicate, keep the clearer version with combined confidence
**Prune**: Remove the line from corrections.md
**Promote**: Run `bash ~/.claude/brain/scripts/smart-capture.sh --role <role> --promote "<rule>"`

## Step 4: Summary

Report what changed:

```
Learning Review Complete:
  Kept: 5
  Bumped: 2
  Merged: 1 (removed 1 duplicate)
  Pruned: 3
  Promoted: 1 -> backend/CLAUDE.md
  Total: 12 -> 8 learnings
```
