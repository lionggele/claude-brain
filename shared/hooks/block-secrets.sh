#!/bin/bash
# PreToolUse hook: block commits with hardcoded secrets
INPUT=$(cat)
cmd=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if echo "$cmd" | grep -q 'git commit'; then
    if git diff --cached 2>/dev/null | grep -iE '(password|secret|api_key|private_key)\s*=' | grep -v '\.gitignore' | grep -v '#'; then
        echo '{"decision": "block", "reason": "Potential secrets detected in staged files. Review before committing."}'
        exit 0
    fi
fi
echo '{"decision": "approve"}'
exit 0
