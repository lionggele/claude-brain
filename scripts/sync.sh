#!/bin/bash
# Auto-commit and push memory changes
BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BRAIN_DIR"

# Only commit memory files
CHANGES=$(git diff --name-only -- '*/memory/*' '*/sessions/*' 2>/dev/null)
UNTRACKED=$(git ls-files --others --exclude-standard -- '*/memory/*' '*/sessions/*' 2>/dev/null)

if [ -z "$CHANGES" ] && [ -z "$UNTRACKED" ]; then
    echo "No memory changes to sync."
    exit 0
fi

git add -- '*/memory/*' '*/sessions/*'
git commit -m "chore: sync learnings $(date +%Y-%m-%d)"
git push 2>/dev/null && echo "Synced to remote." || echo "Committed locally (push manually)."
