#!/bin/bash
# Smart capture: confidence-scored learning system
# Usage: bash smart-capture.sh --role backend --confidence 0.3 --seen 1 "learning text"
# Usage: bash smart-capture.sh --role backend --promote "rule to promote"

set -e

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROLE=""
CONFIDENCE="0.3"
SEEN="1"
LEARNING=""
PROMOTE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --role) ROLE="$2"; shift 2;;
        --confidence) CONFIDENCE="$2"; shift 2;;
        --seen) SEEN="$2"; shift 2;;
        --promote) PROMOTE=true; shift;;
        *) LEARNING="$1"; shift;;
    esac
done

if [ -z "$LEARNING" ]; then
    echo "Usage: bash smart-capture.sh [--role <role>] [--confidence 0.3] [--seen 1] \"learning text\""
    echo "       bash smart-capture.sh --role <role> --promote \"rule to promote\""
    exit 1
fi

DATE=$(date +%Y-%m-%d)

# Determine target file
if [ -n "$ROLE" ] && [ -d "$BRAIN_DIR/roles/$ROLE" ]; then
    TARGET="$BRAIN_DIR/roles/$ROLE/memory/corrections.md"
    CLAUDE_TARGET="$BRAIN_DIR/roles/$ROLE/CLAUDE.md"
else
    TARGET="$BRAIN_DIR/shared/memory/corrections.md"
    CLAUDE_TARGET=""
fi

# Handle promotion
if [ "$PROMOTE" = true ]; then
    if [ -z "$CLAUDE_TARGET" ]; then
        echo "Error: --promote requires --role"
        exit 1
    fi

    # Add to CLAUDE.md under Auto-Promoted Rules
    if ! grep -q "## Auto-Promoted Rules" "$CLAUDE_TARGET" 2>/dev/null; then
        echo "" >> "$CLAUDE_TARGET"
        echo "## Auto-Promoted Rules" >> "$CLAUDE_TARGET"
        echo "(Automatically promoted from corrections when confidence reached 0.9)" >> "$CLAUDE_TARGET"
    fi
    echo "- $LEARNING" >> "$CLAUDE_TARGET"

    # Remove from corrections.md (find line containing the learning text)
    ESCAPED=$(echo "$LEARNING" | sed 's/[\/&]/\\&/g')
    if [ -f "$TARGET" ]; then
        grep -v "$ESCAPED" "$TARGET" > "$TARGET.tmp" 2>/dev/null || true
        mv "$TARGET.tmp" "$TARGET"
    fi

    echo "PROMOTED to rule: $CLAUDE_TARGET"
    echo "  $LEARNING"
    exit 0
fi

# Determine confidence label
if (( $(echo "$CONFIDENCE < 0.4" | bc -l) )); then
    LABEL="tentative"
elif (( $(echo "$CONFIDENCE < 0.7" | bc -l) )); then
    LABEL="growing"
elif (( $(echo "$CONFIDENCE < 0.9" | bc -l) )); then
    LABEL="confident"
else
    LABEL="rule"
fi

# Check if similar learning exists (update instead of duplicate)
if [ -f "$TARGET" ] && grep -q "$LEARNING" "$TARGET" 2>/dev/null; then
    # Update existing entry: bump confidence and seen count
    ESCAPED=$(echo "$LEARNING" | sed 's/[\/&]/\\&/g')
    # Remove old line
    grep -v "$ESCAPED" "$TARGET" > "$TARGET.tmp" 2>/dev/null || true
    mv "$TARGET.tmp" "$TARGET"
    echo "Updated existing learning (confidence: $CONFIDENCE, seen: ${SEEN}x)"
fi

# Write new/updated entry
ENTRY="- [$CONFIDENCE $LABEL] $LEARNING (seen ${SEEN}x, last: $DATE)"
echo "$ENTRY" >> "$TARGET"
echo "Saved to: $TARGET"
echo "  $ENTRY"

# Check for auto-promotion
if (( $(echo "$CONFIDENCE >= 0.9" | bc -l) )); then
    echo ""
    echo "*** CONFIDENCE >= 0.9 — Ready for promotion! ***"
    echo "Run: bash $0 --role $ROLE --promote \"$LEARNING\""
fi
