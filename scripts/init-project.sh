#!/bin/bash
# Bootstrap a CLAUDE.md in a new project
# Usage: bash init-project.sh <role>

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROLE="${1:-backend}"

if [ -f "CLAUDE.md" ]; then
    echo "CLAUDE.md already exists. Aborting."
    exit 1
fi

PROJECT_NAME=$(basename "$(pwd)")

cat > CLAUDE.md << EOF
# Project: $PROJECT_NAME

## Brain
@~/.claude/brain/shared/CLAUDE.md
@~/.claude/brain/roles/$ROLE/CLAUDE.md

## Project-Specific Rules
- (Add your project-specific rules here)

## Key Commands
- (Add frequently used commands here)
EOF

echo "Created CLAUDE.md for project '$PROJECT_NAME' with role: $ROLE"
