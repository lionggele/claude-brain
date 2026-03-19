#!/bin/bash
# Install claude-brain globally
# Usage: bash install.sh
set -e

BRAIN_DIR="$HOME/.claude/brain"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Claude Brain Installer ==="

# If already installed as symlink or clone, update
if [ -L "$BRAIN_DIR" ] || ([ -d "$BRAIN_DIR" ] && [ -d "$BRAIN_DIR/.git" ]); then
    echo "Brain already installed at $BRAIN_DIR"
    if [ -d "$BRAIN_DIR/.git" ]; then
        cd "$BRAIN_DIR" && git pull 2>/dev/null
    fi
    echo "Updated!"
else
    # Symlink this repo to ~/.claude/brain
    mkdir -p "$(dirname "$BRAIN_DIR")"
    ln -sf "$SCRIPT_DIR" "$BRAIN_DIR"
    echo "Linked: $SCRIPT_DIR -> $BRAIN_DIR"
fi

# Add import to global CLAUDE.md
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
if [ ! -f "$GLOBAL_CLAUDE" ]; then
    cat > "$GLOBAL_CLAUDE" << 'EOF'
# Global Claude Config
@~/.claude/brain/CLAUDE.md
EOF
    echo "Created $GLOBAL_CLAUDE"
elif ! grep -q "brain/CLAUDE.md" "$GLOBAL_CLAUDE"; then
    echo "" >> "$GLOBAL_CLAUDE"
    echo "@~/.claude/brain/CLAUDE.md" >> "$GLOBAL_CLAUDE"
    echo "Added brain import to $GLOBAL_CLAUDE"
else
    echo "Brain import already in $GLOBAL_CLAUDE"
fi

# Copy skills to ~/.claude/skills/ (Claude Code auto-discovers these)
SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"
for skill_dir in "$SCRIPT_DIR"/shared/skills/*/; do
    skill_name=$(basename "$skill_dir")
    target="$SKILLS_DIR/$skill_name"
    if [ ! -L "$target" ]; then
        ln -sf "$skill_dir" "$target"
        echo "Linked skill: $skill_name"
    fi
done

echo ""
echo "=== Installed! ==="
echo "Brain:  $BRAIN_DIR"
echo "Skills: $SKILLS_DIR"
ACTIVE=$(grep '@roles/' "$BRAIN_DIR/CLAUDE.md" 2>/dev/null | head -1 | sed 's/.*@roles\///' | sed 's/\/CLAUDE.md//')
echo "Active: $ACTIVE"
echo ""
echo "Commands:"
echo "  Switch role:  bash ~/.claude/brain/scripts/activate-role.sh <role>"
echo "  New project:  bash ~/.claude/brain/scripts/init-project.sh <role>"
echo "  Learnings:    bash ~/.claude/brain/scripts/list-learnings.sh"
echo "  Sync memory:  bash ~/.claude/brain/scripts/sync.sh"
