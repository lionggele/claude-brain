#!/bin/bash
# Usage: bash capture-learning.sh "never use f-string SQL"
# Usage: bash capture-learning.sh --role backend "always use connection pooling"

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROLE=""
LEARNING=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --role) ROLE="$2"; shift 2;;
        *) LEARNING="$1"; shift;;
    esac
done

if [ -z "$LEARNING" ]; then
    echo "Usage: bash capture-learning.sh [--role <role>] \"learning text\""
    exit 1
fi

DATE=$(date +%Y-%m-%d)
ENTRY="- **[$DATE]** $LEARNING"

if [ -n "$ROLE" ] && [ -d "$BRAIN_DIR/roles/$ROLE" ]; then
    TARGET="$BRAIN_DIR/roles/$ROLE/memory/corrections.md"
else
    TARGET="$BRAIN_DIR/shared/memory/corrections.md"
fi

echo "$ENTRY" >> "$TARGET"
echo "Saved to: $TARGET"
echo "  $ENTRY"
