#!/usr/bin/env bash
# us-refinement Auto-Updater for macOS and Linux
set -euo pipefail

CENTRAL_DIR="$HOME/.hjagar/skills/us-refinement"
LOCAL_SKILL="$CENTRAL_DIR/SKILL.md"
REPO="hjagar/us-refinement"

echo "Checking for updates..."

# 1. Read local version
if [ ! -f "$LOCAL_SKILL" ]; then
    echo "Error: us-refinement is not installed globally at $CENTRAL_DIR. Run install.sh first." >&2
    exit 1
fi

local_version=$(grep -oE '<!-- version: v[0-9.]* -->' "$LOCAL_SKILL" | sed -E 's/<!-- version: (v[0-9.]*) -->/\1/' || echo "v0.0.0")
echo "Local version: $local_version"

# 2. Fetch latest remote version from GitHub
latest_version=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' || true)

if [ -z "$latest_version" ]; then
    echo "Warning: Failed to fetch latest version info from GitHub API. Check connection." >&2
    exit 1
fi

echo "Latest remote version: $latest_version"

# 3. Compare versions
if [ "$local_version" = "$latest_version" ]; then
    echo "You are already on the latest version: $local_version"
    exit 0
fi

echo "New version $latest_version is available! Updating..."

# 4. Perform download and safe update
ZIP_URL="https://github.com/$REPO/releases/latest/download/us-refinement.zip"
TEMP_ZIP=$(mktemp --suffix=.zip 2>/dev/null || mktemp /tmp/us-refinement-XXXXXX.zip)
TEMP_EXTRACT_DIR=$(mktemp -d /tmp/us-refinement-extract-XXXXXX)

cleanup() {
    rm -f "$TEMP_ZIP"
    rm -rf "$TEMP_EXTRACT_DIR"
}
trap cleanup EXIT

echo "Downloading release archive..."
if ! curl -sSL -o "$TEMP_ZIP" "$ZIP_URL"; then
    echo "Error: Failed to download release ZIP from GitHub." >&2
    exit 1
fi

echo "Extracting archive..."
if ! unzip -o "$TEMP_ZIP" -d "$TEMP_EXTRACT_DIR" &>/dev/null; then
    echo "Error: Extraction failed." >&2
    exit 1
fi

echo "Updating central files..."
# Clear stale central-store dirs first: a plain merge-copy below would leave behind
# files removed/renamed in the new release, and those orphans would then be
# re-propagated to every agent path.
for dir in scripts tests; do
    rm -rf "${CENTRAL_DIR:?}/$dir"
done
cp -R "$TEMP_EXTRACT_DIR"/. "$CENTRAL_DIR/"

# 5. Propagate SKILL.md + scripts/ + tests/ to all agents
echo "Updating agents..."
AGENT_PATHS=(
    "$HOME/.gemini/skills/us-refinement"
    "$HOME/.config/opencode/skills/us-refinement"
    "$HOME/.copilot/skills/us-refinement"
    "$HOME/.agents/skills/us-refinement"
    "$HOME/.claude/skills/us-refinement"
    "$HOME/.cursor/skills/us-refinement"
)

# Multi-account support
for d in "$HOME"/.claude-*; do
    if [ -d "$d" ]; then
        AGENT_PATHS+=("$d/skills/us-refinement")
    fi
done

for agent in "${AGENT_PATHS[@]}"; do
    if [ -d "$agent" ] || [ -f "$agent" ]; then
        # Stage into a sibling dir and swap it into place only after every copy
        # succeeds (caught by `set -e`), so a mid-copy failure leaves the
        # previously-installed agent payload untouched instead of wiped-and-broken.
        staging="${agent}.staging"
        rm -rf "$staging"
        mkdir -p "$staging"
        cp "$CENTRAL_DIR/SKILL.md" "$staging/"
        for dir in scripts tests; do
            if [ -d "$CENTRAL_DIR/$dir" ]; then
                cp -r "$CENTRAL_DIR/$dir" "$staging/"
            fi
        done
        rm -rf "$agent"
        mv "$staging" "$agent"
        echo "Updated agent skill path: $agent"
    fi
done

# Kiro is a special case: a single generated steering file at
# ~/.kiro/steering/us-refinement.md (SKILL.md's frontmatter with `inclusion: always`
# injected), not a folder+SKILL.md copy - no scripts/ or tests/ payload.
KIRO_TARGET="$HOME/.kiro/steering/us-refinement.md"
if [ -f "$KIRO_TARGET" ]; then
    # Checked via a pipe (never captured into a shell variable) so a CRLF-terminated
    # source line's trailing \r survives intact for the comparison below.
    if ! sed -n '1p' "$CENTRAL_DIR/SKILL.md" | grep -Eq $'^---\r?$'; then
        echo "Error: SKILL.md at $CENTRAL_DIR does not start with a '---' YAML frontmatter delimiter - cannot update Kiro steering file." >&2
        exit 1
    fi
    kiro_staging="${KIRO_TARGET}.staging"
    # Match the injected line's terminator to the source file's own EOL style (CRLF vs LF),
    # detected from line 1, so the output doesn't end up with mixed line endings.
    injected_line="inclusion: always"$'\n'
    if sed -n '1p' "$CENTRAL_DIR/SKILL.md" | grep -q $'\r$'; then
        injected_line="inclusion: always"$'\r\n'
    fi
    # Every other line is streamed straight through via sed (never captured into a shell
    # variable), so it reaches the output byte-for-byte regardless of its EOL style.
    {
        sed -n '1p' "$CENTRAL_DIR/SKILL.md"
        printf '%s' "$injected_line"
        sed -n '2,$p' "$CENTRAL_DIR/SKILL.md"
    } > "$kiro_staging"
    rm -f "$KIRO_TARGET"
    mv "$kiro_staging" "$KIRO_TARGET"
    echo "Updated agent skill path: $KIRO_TARGET"
fi

echo "Update completed successfully to version $latest_version!"
