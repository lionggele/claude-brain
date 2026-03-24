#!/bin/bash
# Install claude-brain globally
# Usage: bash install.sh
set -e

BRAIN_DIR="$HOME/.claude/brain"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Claude Brain Installer ==="

# --- 1. Link brain repo to ~/.claude/brain ---
if [ -L "$BRAIN_DIR" ] || ([ -d "$BRAIN_DIR" ] && [ -d "$BRAIN_DIR/.git" ]); then
    echo "[ok] Brain already installed at $BRAIN_DIR"
    if [ -d "$BRAIN_DIR/.git" ]; then
        cd "$BRAIN_DIR" && git pull 2>/dev/null || true
    fi
else
    mkdir -p "$(dirname "$BRAIN_DIR")"
    ln -sf "$SCRIPT_DIR" "$BRAIN_DIR"
    echo "[ok] Linked: $SCRIPT_DIR -> $BRAIN_DIR"
fi

# --- 2. Create global CLAUDE.md with brain import ---
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
if [ ! -f "$GLOBAL_CLAUDE" ]; then
    cat > "$GLOBAL_CLAUDE" << 'EOF'
# Global Claude Config

## Brain
@~/.claude/brain/CLAUDE.md
EOF
    echo "[ok] Created $GLOBAL_CLAUDE"
elif ! grep -q "brain/CLAUDE.md" "$GLOBAL_CLAUDE"; then
    echo "" >> "$GLOBAL_CLAUDE"
    echo "## Brain" >> "$GLOBAL_CLAUDE"
    echo "@~/.claude/brain/CLAUDE.md" >> "$GLOBAL_CLAUDE"
    echo "[ok] Added brain import to $GLOBAL_CLAUDE"
else
    echo "[ok] Brain import already in $GLOBAL_CLAUDE"
fi

# --- 3. Symlink ALL brain skills to ~/.claude/skills/ ---
SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"
SKILL_COUNT=0
for skill_dir in "$SCRIPT_DIR"/shared/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target="$SKILLS_DIR/brain-$skill_name"
    # Remove old non-prefixed symlinks if they exist
    old_target="$SKILLS_DIR/$skill_name"
    if [ -L "$old_target" ]; then
        rm "$old_target"
    fi
    # Create/update prefixed symlink
    rm -f "$target" 2>/dev/null
    ln -sf "$skill_dir" "$target"
    SKILL_COUNT=$((SKILL_COUNT + 1))
done
echo "[ok] Linked $SKILL_COUNT brain skills (prefixed with brain-)"

# --- 4. Create .local/ directory for personal data (gitignored) ---
LOCAL_DIR="$SCRIPT_DIR/.local"
mkdir -p "$LOCAL_DIR/memory"
mkdir -p "$LOCAL_DIR/sessions"
if ! grep -q ".local/" "$SCRIPT_DIR/.gitignore" 2>/dev/null; then
    echo "" >> "$SCRIPT_DIR/.gitignore"
    echo "# Personal data (not shared)" >> "$SCRIPT_DIR/.gitignore"
    echo ".local/" >> "$SCRIPT_DIR/.gitignore"
fi
echo "[ok] Personal data dir: $LOCAL_DIR"

# --- 5. Create projects/ directory ---
mkdir -p "$SCRIPT_DIR/projects"
echo "[ok] Projects dir ready"

# --- Summary ---
echo ""
echo "=== Installed! ==="
ACTIVE=$(grep '@roles/' "$BRAIN_DIR/CLAUDE.md" 2>/dev/null | head -1 | sed 's/.*@roles\///' | sed 's/\/CLAUDE.md//')
echo "  Brain:    $BRAIN_DIR"
echo "  Skills:   $SKILLS_DIR/brain-*"
echo "  Role:     ${ACTIVE:-none}"
echo "  Personal: $LOCAL_DIR"
echo ""
echo "Quick start:"
echo "  Switch role:    bash ~/.claude/brain/scripts/activate-role.sh <role>"
echo "  Init project:   bash ~/.claude/brain/scripts/init-project.sh <name> [--mode symlink|copy]"
echo "  Show status:    /brain-status"
echo "  Capture fix:    /brain-smart-capture"
echo "  Spike research: /brain-spike"
echo ""
echo "Domain skills (auto-discovered by Claude Code):"
echo "  /brain-api-design       API contract design"
echo "  /brain-rag-pipeline     RAG architecture patterns"
echo "  /brain-agent-design     Agent/MCP orchestration"
echo "  /brain-service-scaffold Project bootstrap"
echo "  /brain-spike            Time-boxed research"
