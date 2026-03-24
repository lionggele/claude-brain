---
name: brain-retro
description: Git-based retrospective for a time window. Shows commit stats, type breakdown, hotspots, learnings captured, and week-over-week trends.
---

# Retro (Session/Week Analytics)

Analyze recent git history and brain activity for a time window.

## Usage

User says: "retro" or "retro 7d" or "retro 30d"

Default: 7 days.

## Process

1. Run git analytics:
```bash
SINCE="7 days ago"  # or user-specified
echo "=== Commits ==="
git log --since="$SINCE" --oneline --no-merges | wc -l
echo "=== By type ==="
git log --since="$SINCE" --oneline --no-merges | grep -oE '^[a-f0-9]+ (feat|fix|refactor|docs|test|chore):' | awk '{print $2}' | sort | uniq -c | sort -rn
echo "=== Files changed ==="
git log --since="$SINCE" --name-only --no-merges | grep -v '^$' | grep -v '^[a-f0-9]' | sort | uniq -c | sort -rn | head -10
echo "=== LOC ==="
git log --since="$SINCE" --shortstat --no-merges | grep 'insertions\|deletions' | awk '{ins+=$4; del+=$6} END {print ins " added, " del " removed"}'
```

2. Check brain activity:
```bash
echo "=== Learnings captured ==="
grep "last:.*$(date +%Y-%m)" ~/.claude/brain/shared/memory/corrections.md 2>/dev/null | wc -l
for f in ~/.claude/brain/roles/*/memory/corrections.md; do
    grep "last:.*$(date +%Y-%m)" "$f" 2>/dev/null
done
echo "=== Sessions ==="
ls -la ~/.claude/brain/shared/memory/sessions/ 2>/dev/null | tail -5
```

3. Present summary:
```markdown
## Retro: <date range>

**Commits:** 23 (12 feat, 6 fix, 3 refactor, 2 docs)
**LOC:** +1,245 / -380
**Hotspots:** app/adapters/parser.py (8 changes), app/api/routes.py (5)
**Test ratio:** 4 test files / 18 total changed = 22%
**Learnings captured:** 3 new, 1 bumped
**Sessions:** 5

### Patterns
- Heavy work on parser adapter this week
- Test coverage lagging behind feature work
- 2 learnings about connection pooling -- consider promoting
```

4. Save snapshot (optional):
```bash
PROJECT=$(basename "$(pwd)")
mkdir -p ~/.claude/brain/projects/$PROJECT/retros
# Save as JSON for future comparison
```
