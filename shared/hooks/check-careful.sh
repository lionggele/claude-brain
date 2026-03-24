#!/bin/bash
# PreToolUse hook: warn before destructive commands
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

[ "$TOOL" != "Bash" ] && echo '{"decision": "approve"}' && exit 0

cmd=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Extract the target path (first non-flag argument after the command)
TARGET_ARGS=$(echo "$cmd" | sed 's/^[a-z]* //' | sed 's/-[^ ]* //g')

# Safe targets -- allow destructive ops on build artifacts
for safe in node_modules __pycache__ .pytest_cache .mypy_cache dist/ build/ .venv venv/ .eggs htmlcov .coverage; do
    if echo "$TARGET_ARGS" | grep -q "$safe"; then
        echo '{"decision": "approve"}'
        exit 0
    fi
done

# Destructive patterns
declare -A PATTERNS
PATTERNS['rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|.*-rf\s+|.*-fr\s+)']="rm with force flag"
PATTERNS['(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)']="Destructive SQL"
PATTERNS['git\s+push\s+.*(-f|--force)']="Force push"
PATTERNS['git\s+reset\s+--hard']="git reset --hard discards uncommitted changes"
PATTERNS['git\s+(checkout|restore)\s+\.$']="Discarding all local changes"
PATTERNS['git\s+clean\s+.*-f']="git clean removes untracked files"
PATTERNS['git\s+branch\s+-D']="Force-deleting a branch"
PATTERNS['kubectl\s+delete']="kubectl delete"
PATTERNS['docker\s+(system|volume|container)\s+prune']="Docker prune removes resources"
PATTERNS['chmod\s+777']="chmod 777 world-writable"

for pat in "${!PATTERNS[@]}"; do
    if echo "$cmd" | grep -qE "$pat"; then
        echo "{\"decision\": \"block\", \"reason\": \"[careful] ${PATTERNS[$pat]}. Review and re-run if intentional.\"}"
        exit 0
    fi
done

echo '{"decision": "approve"}'
