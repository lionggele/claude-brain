#!/bin/bash
# Called by the session-summary skill with actual content
# Usage: bash session-summary.sh "Summary text from Claude"
# Or without args: creates an empty template

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATE=$(date +%Y-%m-%d_%H%M)
SUMMARY_DIR="$BRAIN_DIR/shared/memory/sessions"
mkdir -p "$SUMMARY_DIR"

SUMMARY_FILE="$SUMMARY_DIR/$DATE.md"
CONTENT="$1"

if [ -n "$CONTENT" ]; then
    # Content provided by the session-summary skill
    cat > "$SUMMARY_FILE" << EOF
# Session Summary — $(date +"%Y-%m-%d %H:%M")

$CONTENT
EOF
else
    # Empty template for manual use
    cat > "$SUMMARY_FILE" << EOF
# Session Summary — $(date +"%Y-%m-%d %H:%M")

## What was done


## Learnings


## To remember

EOF
fi

echo "$SUMMARY_FILE"
