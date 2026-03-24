#!/bin/bash
# PreToolUse hook: restrict Edit/Write to a frozen directory
INPUT=$(cat)

FREEZE_FILE="$HOME/.claude/brain/.local/freeze-dir.txt"

[ ! -f "$FREEZE_FILE" ] && echo '{"decision": "approve"}' && exit 0

FREEZE_DIR=$(cat "$FREEZE_FILE" 2>/dev/null)
[ -z "$FREEZE_DIR" ] && echo '{"decision": "approve"}' && exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" != "Edit" ] && [ "$TOOL" != "Write" ] && echo '{"decision": "approve"}' && exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && echo '{"decision": "approve"}' && exit 0

REAL_FREEZE=$(cd "$FREEZE_DIR" 2>/dev/null && pwd)
if [ -z "$REAL_FREEZE" ]; then
    rm "$FREEZE_FILE" 2>/dev/null
    echo '{"decision": "approve"}'
    exit 0
fi

case "$FILE_PATH" in
    "$REAL_FREEZE"*) echo '{"decision": "approve"}' ;;
    *) echo "{\"decision\": \"block\", \"reason\": \"[freeze] Edits restricted to $FREEZE_DIR. Run /brain-safe unfreeze to remove.\"}" ;;
esac
