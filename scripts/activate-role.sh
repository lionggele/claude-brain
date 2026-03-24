#!/bin/bash
# Usage: bash activate-role.sh <role-name> [--no-hooks]
# Usage: bash activate-role.sh backend+devops  (compose multiple roles)
# Switches the active role in CLAUDE.md AND merges hooks into settings.json

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INPUT=""
SKIP_HOOKS=false

for arg in "$@"; do
    case $arg in
        --no-hooks) SKIP_HOOKS=true ;;
        *) INPUT="$arg" ;;
    esac
done

if [ -z "$INPUT" ]; then
    echo "Available roles:"
    ls "$BRAIN_DIR/roles/" | while read r; do echo "  $r"; done
    echo ""
    echo "Usage: bash activate-role.sh <role-name> [--no-hooks]"
    echo "       bash activate-role.sh backend+devops  (compose multiple)"
    exit 1
fi

# Support composing: backend+devops
IFS='+' read -ra ROLES <<< "$INPUT"

for ROLE in "${ROLES[@]}"; do
    if [ ! -d "$BRAIN_DIR/roles/$ROLE" ]; then
        echo "Error: Role '$ROLE' not found"
        exit 1
    fi
done

# Update CLAUDE.md — replace role import lines
# Remove old role imports, add new ones
CLAUDE_FILE="$BRAIN_DIR/CLAUDE.md"
# Use a temp file for cross-platform sed compatibility
grep -v '@roles/' "$CLAUDE_FILE" > "$CLAUDE_FILE.tmp"

# Find the line after @shared/CLAUDE.md to insert role imports
IMPORT_LINES=""
for ROLE in "${ROLES[@]}"; do
    IMPORT_LINES="${IMPORT_LINES}@roles/$ROLE/CLAUDE.md\n"
done

# Insert after the shared import
awk -v imports="$IMPORT_LINES" '
    /@shared\/CLAUDE.md/ { print; printf imports; next }
    { print }
' "$CLAUDE_FILE.tmp" > "$CLAUDE_FILE"
rm "$CLAUDE_FILE.tmp"

# Merge role hooks into ~/.claude/settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# Build merged hooks from all active roles
MERGED_HOOKS='{}'
for ROLE in "${ROLES[@]}"; do
    HOOK_FILE="$BRAIN_DIR/roles/$ROLE/hooks.json"
    if [ -f "$HOOK_FILE" ] && [ "$(cat "$HOOK_FILE")" != "{}" ]; then
        # Deep merge hooks using jq
        MERGED_HOOKS=$(echo "$MERGED_HOOKS" | jq -s '.[0] * .[1]' - "$HOOK_FILE")
    fi
done

# Inject safety hooks (careful + freeze) unless --no-hooks
if [ "$SKIP_HOOKS" = false ]; then
    CAREFUL_HOOK="$BRAIN_DIR/shared/hooks/check-careful.sh"
    FREEZE_HOOK="$BRAIN_DIR/shared/hooks/check-freeze.sh"

    SAFETY_HOOKS=$(cat <<EOJSON
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "bash $CAREFUL_HOOK"}]
    },
    {
      "matcher": "Edit",
      "hooks": [{"type": "command", "command": "bash $FREEZE_HOOK"}]
    },
    {
      "matcher": "Write",
      "hooks": [{"type": "command", "command": "bash $FREEZE_HOOK"}]
    }
  ]
}
EOJSON
)

    MERGED_HOOKS=$(echo "$MERGED_HOOKS" | jq -s '.[0] as $role | .[1] as $safety |
      ($role // {}) * ($safety // {}) |
      .PreToolUse = (($role.PreToolUse // []) + ($safety.PreToolUse // []))
    ' - <(echo "$SAFETY_HOOKS"))
fi

# Update settings.json with merged hooks (preserve other settings)
jq --argjson hooks "$MERGED_HOOKS" '.hooks = $hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

echo "Activated role(s): ${ROLES[*]}"
echo "Hooks merged into: $SETTINGS_FILE"
if [ "$SKIP_HOOKS" = false ]; then
    echo "  Safety: careful (destructive cmd guard) + freeze (edit boundary)"
else
    echo "  Safety hooks: SKIPPED (--no-hooks)"
fi
for ROLE in "${ROLES[@]}"; do
    echo "  Config: $BRAIN_DIR/roles/$ROLE/CLAUDE.md"
done
