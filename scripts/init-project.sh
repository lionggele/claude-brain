#!/bin/bash
# Bootstrap a project with brain integration
# Usage: bash init-project.sh <name> [--role <role>] [--mode symlink|copy]
#
# Modes:
#   symlink (default) - Personal use. CLAUDE.md imports from ~/.claude/brain/
#   copy              - Team use. Copies brain into .claude/skills/brain/ in the project

set -e

BRAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME=""
ROLE="backend"
MODE="symlink"

while [[ $# -gt 0 ]]; do
    case $1 in
        --role) ROLE="$2"; shift 2;;
        --mode) MODE="$2"; shift 2;;
        *) PROJECT_NAME="$1"; shift;;
    esac
done

if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME=$(basename "$(pwd)")
fi

if [ ! -d "$BRAIN_DIR/roles/$ROLE" ]; then
    echo "Error: Role '$ROLE' not found"
    echo "Available: $(ls "$BRAIN_DIR/roles/" | tr '\n' ' ')"
    exit 1
fi

echo "=== Init Project: $PROJECT_NAME ==="
echo "  Role: $ROLE"
echo "  Mode: $MODE"

# --- 1. Create project directory in brain ---
PROJECT_DIR="$BRAIN_DIR/projects/$PROJECT_NAME"
mkdir -p "$PROJECT_DIR/artifacts"

# Create context.md if it doesn't exist
if [ ! -f "$PROJECT_DIR/context.md" ]; then
    DATE=$(date +%Y-%m-%d)
    cat > "$PROJECT_DIR/context.md" << EOF
# Project: $PROJECT_NAME
Last updated: $DATE

## Stack
- (Describe your stack here)

## Key Decisions
- (Decisions will be saved here by /brain-spike and /brain-api-design)

## Active Work
- (What are you working on now?)

## Gotchas
- (Things to watch out for)
EOF
    echo "[ok] Created project context: $PROJECT_DIR/context.md"
fi

# --- 2. Create CLAUDE.md in the current directory ---
if [ -f "CLAUDE.md" ]; then
    echo "[skip] CLAUDE.md already exists"
else
    if [ "$MODE" = "symlink" ]; then
        cat > CLAUDE.md << EOF
# Project: $PROJECT_NAME

## Brain
@~/.claude/brain/shared/CLAUDE.md
@~/.claude/brain/roles/$ROLE/CLAUDE.md

## Project Context
@~/.claude/brain/projects/$PROJECT_NAME/context.md

## Project-Specific Rules
- (Add your project-specific rules here)

## Key Commands
- Build: \`(command)\`
- Test: \`(command)\`
- Deploy: \`(command)\`
EOF
    else
        # Copy mode: reference local copy
        cat > CLAUDE.md << EOF
# Project: $PROJECT_NAME

## Brain
@.claude/skills/brain/shared/CLAUDE.md
@.claude/skills/brain/roles/$ROLE/CLAUDE.md

## Project-Specific Rules
- (Add your project-specific rules here)

## Key Commands
- Build: \`(command)\`
- Test: \`(command)\`
- Deploy: \`(command)\`
EOF
    fi
    echo "[ok] Created CLAUDE.md (mode: $MODE)"
fi

# --- 3. Copy brain into project (team mode only) ---
if [ "$MODE" = "copy" ]; then
    DEST=".claude/skills/brain"
    mkdir -p "$DEST"
    cp -R "$BRAIN_DIR/shared" "$DEST/"
    cp -R "$BRAIN_DIR/roles" "$DEST/"
    echo "[ok] Copied brain to $DEST/ (committed to repo for teammates)"
    echo ""
    echo "Team members get brain on git clone. No install needed."
fi

echo ""
echo "=== Done! ==="
echo "  Project context: $PROJECT_DIR/context.md"
echo "  Artifacts dir:   $PROJECT_DIR/artifacts/"
echo ""
echo "Save decisions with: /brain-spike"
echo "Show brain status:   /brain-status"
