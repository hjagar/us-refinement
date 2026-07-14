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
    "$HOME/.cursor/skills/us-refinement"
)

# Dynamic multi-account .claude-* detection
for d in "$HOME"/.claude-*; do
    if [ -d "$d" ]; then
        AGENT_PATHS+=("$d/skills/us-refinement")
    fi
done

if [ -z "$SRC_DIR" ]; then
    SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# 3. Payload Copy Helper (SKILL.md + scripts/ + tests/ - docs/ excluded on purpose)
# Stages the payload in a sibling ".staging" dir and swaps it into place only after every
# copy succeeds, so a mid-copy failure (caught by `set -e`) leaves the existing installed
# payload untouched.
copy_skill_file() {
    local target="$1"
    local source="$2"
    local staging="${target}.staging"

    mkdir -p "$(dirname "$target")"
    rm -rf "$staging"
    mkdir -p "$staging"

    if [ -f "$source/SKILL.md" ]; then
        echo "Copying SKILL.md to: $target"
        cp "$source/SKILL.md" "$staging/"
    else
        echo "Error: SKILL.md not found at $source" >&2
        rm -rf "$staging"
        exit 1
    fi

    for dir in scripts tests; do
        if [ -d "$source/$dir" ]; then
            echo "Copying $dir/ to: $target"
            cp -r "$source/$dir" "$staging/"
        else
            echo "Warning: $dir/ not found at $source - skipping." >&2
        fi
    done

    rm -rf "$target"
    mv "$staging" "$target"
}

# 3b. Kiro Steering File Helper
# Kiro does not use the folder+SKILL.md format other agents use: it reads a single flat
# steering file at ~/.kiro/steering/us-refinement.md with `inclusion: always` injected as
# the first key inside SKILL.md's YAML frontmatter. No scripts/ or tests/ payload - steering
# files are plain markdown only. Stages then swaps into place for the same atomicity
# guarantee as copy_skill_file.
new_kiro_steering_file() {
    local source="$1"
    local steering_dir="$HOME/.kiro/steering"
    local target="$steering_dir/us-refinement.md"
    local staging="${target}.staging"
    local src_file="$source/SKILL.md"

    if [ ! -f "$src_file" ]; then
        echo "Error: SKILL.md not found at $source" >&2
        exit 1
    fi

    # Checked via a pipe (never captured into a shell variable) so a CRLF-terminated
    # source line's trailing \r survives intact for the comparison below.
    if ! sed -n '1p' "$src_file" | grep -Eq $'^---\r?$'; then
        echo "Error: SKILL.md at $source does not start with a '---' YAML frontmatter delimiter - cannot generate Kiro steering file." >&2
        exit 1
    fi

    mkdir -p "$steering_dir"
    echo "Generating Kiro steering file: $target"

    # Match the injected line's terminator to the source file's own EOL style (CRLF vs LF),
    # detected from line 1, so the output doesn't end up with mixed line endings.
    local injected_line="inclusion: always"$'\n'
    if sed -n '1p' "$src_file" | grep -q $'\r$'; then
        injected_line="inclusion: always"$'\r\n'
    fi

    # Insert `inclusion: always` as a new line right after the opening `---` delimiter.
    # Every other line is streamed straight through via sed (never captured into a shell
    # variable), so it reaches the output byte-for-byte regardless of its EOL style.
    {
        sed -n '1p' "$src_file"
        printf '%s' "$injected_line"
        sed -n '2,$p' "$src_file"
    } > "$staging"

    rm -f "$target"
    mv "$staging" "$target"
}

# 4. Installation Logic
if [ "$LOCAL" = true ]; then
    echo "Installing us-refinement in LOCAL Mode..."
    for agent in "${AGENT_PATHS[@]}"; do
        copy_skill_file "$agent" "$SRC_DIR"
    done
    new_kiro_steering_file "$SRC_DIR"
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
        copy_skill_file "$agent" "$CENTRAL_DIR"
    done
    new_kiro_steering_file "$CENTRAL_DIR"
fi

echo "Installation completed successfully!"
