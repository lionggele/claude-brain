#!/bin/bash
# Show all corrections across all roles
BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Global Learnings ==="
cat "$BRAIN_DIR/shared/memory/corrections.md" 2>/dev/null | grep "^-" || echo "  (none)"

echo ""
for role_dir in "$BRAIN_DIR"/roles/*/; do
    role=$(basename "$role_dir")
    corrections="$role_dir/memory/corrections.md"
    if [ -f "$corrections" ] && grep -q "^-" "$corrections" 2>/dev/null; then
        echo "=== $role ==="
        grep "^-" "$corrections"
        echo ""
    fi
done

total=$(find "$BRAIN_DIR" -name "corrections.md" -exec grep -c "^-" {} + 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
echo "Total learnings: $total"
