#!/usr/bin/env bash
set -e

LOCAL=false
SRC_DIR=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -l|--local) LOCAL=true ;;
        -p|--path) SRC_DIR="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# 1. Prerequisites Check
echo "Checking prerequisites..."
if ! command -v git &> /dev/null; then
    echo "Error: git is required to use this skill."
    exit 1
fi
if ! command -v gh &> /dev/null; then
    echo "Warning: gh CLI was not found. Issue refinement write-backs will fallback to copy/paste."
fi

# 2. Path Setup
CENTRAL_DIR="$HOME/.config/skills/us-refinement"
AGENT_PATHS=(
    "$HOME/.gemini/skills/us-refinement"
    "$HOME/.claude/skills/us-refinement"
    "$HOME/.config/opencode/skills/us-refinement"
)

if [ -z "$SRC_DIR" ]; then
    SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# 3. Symlink Helper
create_symlink() {
    local target="$1"
    local source="$2"
    mkdir -p "$(dirname "$target")"
    
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            local current_target
            current_target=$(readlink "$target")
            if [ "$current_target" = "$source" ]; then
                echo "Link already exists and points to the correct target: $target -> $source"
                return
            fi
            echo "Link points to a different target ($current_target). Recreating..."
            rm "$target"
        else
            echo "Physical folder found at $target. Removing to replace with symlink..."
            rm -rf "$target"
        fi
    fi
    
    echo "Creating Symlink: $target -> $source"
    ln -s "$source" "$target"
}

# 4. Installation Logic
if [ "$LOCAL" = true ]; then
    echo "Installing us-refinement in LOCAL Mode..."
    for agent in "${AGENT_PATHS[@]}"; do
        create_symlink "$agent" "$SRC_DIR"
    done
else
    echo "Installing us-refinement in GLOBAL Mode..."
    rm -rf "$CENTRAL_DIR"
    mkdir -p "$CENTRAL_DIR"
    
    # Copy essential skill items
    cp "$SRC_DIR/SKILL.md" "$CENTRAL_DIR/"
    if [ -d "$SRC_DIR/scripts" ]; then
        cp -r "$SRC_DIR/scripts" "$CENTRAL_DIR/"
    fi
    if [ -d "$SRC_DIR/docs" ]; then
        cp -r "$SRC_DIR/docs" "$CENTRAL_DIR/"
    fi
    if [ -d "$SRC_DIR/tests" ]; then
        cp -r "$SRC_DIR/tests" "$CENTRAL_DIR/"
    fi
    
    for agent in "${AGENT_PATHS[@]}"; do
        create_symlink "$agent" "$CENTRAL_DIR"
    done
fi

echo "Installation completed successfully!"
