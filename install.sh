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
CENTRAL_DIR="$HOME/.hjagar/skills/us-refinement"
AGENT_PATHS=(
    "$HOME/.gemini/skills/us-refinement"
    "$HOME/.claude/skills/us-refinement"
    "$HOME/.config/opencode/skills/us-refinement"
    "$HOME/.copilot/skills/us-refinement"
    "$HOME/.agents/skills/us-refinement"
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
    
    ZIP_URL="https://github.com/hjagar/us-refinement/releases/latest/download/us-refinement.zip"
    TEMP_ZIP=$(mktemp --suffix=.zip 2>/dev/null || mktemp /tmp/us-refinement-XXXXXX.zip)
    
    DOWNLOAD_SUCCESS=false
    
    # Try downloading via gh CLI first (useful for private repos)
    if command -v gh &>/dev/null; then
        echo "Downloading latest release ZIP using GitHub CLI..."
        if gh release download --repo hjagar/us-refinement --pattern "us-refinement.zip" --output "$TEMP_ZIP" --clobber &>/dev/null; then
            DOWNLOAD_SUCCESS=true
        fi
    fi
    
    # Fallback to curl or wget
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "Downloading latest release ZIP from public GitHub URL..."
        if command -v curl &>/dev/null; then
            if curl -sSL -o "$TEMP_ZIP" "$ZIP_URL"; then
                DOWNLOAD_SUCCESS=true
            fi
        elif command -v wget &>/dev/null; then
            if wget -q -O "$TEMP_ZIP" "$ZIP_URL"; then
                DOWNLOAD_SUCCESS=true
            fi
        fi
    fi
    
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "Error: Failed to download release ZIP. Ensure gh CLI is authenticated or curl/wget is installed and has internet access." >&2
        rm -f "$TEMP_ZIP"
        exit 1
    fi
    
    echo "Extracting release ZIP..."
    if ! command -v unzip &>/dev/null; then
        echo "Error: unzip is required but was not found." >&2
        rm -f "$TEMP_ZIP"
        exit 1
    fi
    if ! unzip -o "$TEMP_ZIP" -d "$CENTRAL_DIR" &>/dev/null; then
        echo "Error: extraction failed." >&2
        rm -rf "$CENTRAL_DIR"
        rm -f "$TEMP_ZIP"
        exit 1
    fi
    rm -f "$TEMP_ZIP"
    
    for agent in "${AGENT_PATHS[@]}"; do
        create_symlink "$agent" "$CENTRAL_DIR"
    done
fi

echo "Installation completed successfully!"
