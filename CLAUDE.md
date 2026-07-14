# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`us-refinement` is not an application — it's a portable **AI agent skill** (a `SKILL.md` contract) that refines raw user stories into structured, INVEST-checked specs with Given/When/Then acceptance criteria, before they go to technical design or `/sdd-new`. The repo ships the skill itself plus installers that copy it into a skill directory for multiple AI agents (Claude Code, Gemini/Antigravity, OpenCode).

The actual "product" of this repo is `SKILL.md`. Everything else (installers, validator script, docs) supports authoring, distributing, and verifying that one file.

## Commands

There is no build step, package manager, or test framework — this is a skill + shell scripts repo.

**Validate an AI-DATA block** (the hidden HTML-comment metadata block a refined story must contain):
```bash
python scripts/validate_refinement.py tests/mock_valid_us.md     # expect exit 0
python scripts/validate_refinement.py tests/mock_invalid_us.md   # expect exit 1, prints field errors
```
Run this after editing the `<!-- [AI-DATA] -->` schema in `SKILL.md` (Step 3 output format) or the parser in `scripts/validate_refinement.py` to confirm they stay in sync — there are no automated test files beyond these two mocks.

**Install the skill locally for testing** (copies `SKILL.md`, `scripts/`, and `tests/` from this checkout directly, so re-running the installer after local edits keeps each agent's copy in sync):
```powershell
./install.ps1 -Local
```
```bash
./install.sh --local
```

**Install globally** (downloads the latest release ZIP — `SKILL.md`, `scripts/`, `tests/` — into `~/.hjagar/skills/us-refinement`, then copies from that central store to each agent's skill dir):
```powershell
./install.ps1
```
```bash
./install.sh
```
Use `-Path <dir>` / `--path <dir>` with local mode to install from a source directory other than the script's own location (global mode always installs from the downloaded release, ignoring this flag).

## Architecture

### The skill contract (`SKILL.md`)

`SKILL.md` is the entire behavioral spec for the agent, structured as a strict step sequence (Step 0 → Step 5). Key invariants to preserve when editing it:

- **English instructions, localized output**: the skill body is written in English for token efficiency, but explicitly instructs the agent to always reply in the user's conversation language. Don't break this separation when adding steps.
- **Step 2 is a flexible gate, not a blocker**: the agent asks clarifying questions but must proceed anyway if the user says to skip them — any unanswered point becomes a documented **assumption** in the output, never a guessed fact.
- **The skill never escalates itself**: it explicitly must not call `/sdd-new` or generate a technical spec — it only produces the refined story and lets the user decide the next step.
- **GitHub write-back (Step 4) is opt-in**: only triggered if the story originated from `gh issue view`, and only writes back (`comment` vs `edit --body-file`) after an explicit user choice — never silently.

### The Invisible AI Zone (hidden AI-DATA block)

Every refined story output ends with a hidden `<!-- [AI-DATA] ... -->` HTML comment containing YAML: `id` (must match `US\d+`), `type` (`feat|fix|refactor|docs|chore`), `breaking`, `dependencies` (each must match `US\d+`), `metadata` (`scope.backend`/`scope.frontend` booleans, `role`, `endpoint`, `auth`, `ui`), and `scenarios` (each needs `name`/`given`/`when`/`then`). This keeps the human-facing markdown clean while giving downstream AI tools (e.g. ones reading issues via the GitHub API) an unambiguous, token-efficient structured payload.

`scripts/validate_refinement.py` implements a **hand-rolled YAML subset parser** (not a real YAML lib — by design, to keep the skill dependency-free) that extracts and validates this block against the schema above. If you change the schema in `SKILL.md`'s output format, update the parser/validator in lockstep, and update `tests/mock_valid_us.md` / `tests/mock_invalid_us.md` to match.

### Installers (`install.ps1` / `install.sh`)

Both scripts implement the same two install modes and must be kept behaviorally identical:

- **Local mode** (`-Local`/`--local`): copies `SKILL.md`, `scripts/`, and `tests/` from *this* source checkout directly into each supported agent's skill directory. `docs/` is intentionally excluded. Re-run the installer after local edits to refresh the copies — there is no live link.
- **Global mode** (default): downloads the latest GitHub release ZIP (built by `Release-Repo.ps1`/`Release-Repo.sh`, which package `SKILL.md`, `scripts/`, `tests/`, `lib/`, plus the update/uninstall scripts) into a central `~/.hjagar/skills/us-refinement`, then copies from that central store to every agent path using the same `SKILL.md` + `scripts/` + `tests/` payload as local mode. `docs/`, `openspec/`, `.git/`, and `.gitignore` are intentionally excluded to keep the installed payload minimal.

Agent target paths currently wired into both scripts: `~/.gemini/skills/us-refinement`, `~/.claude/skills/us-refinement`, `~/.config/opencode/skills/us-refinement`, `~/.copilot/skills/us-refinement`, `~/.agents/skills/us-refinement`, `~/.cursor/skills/us-refinement`, plus any `~/.claude-*/skills/us-refinement` multi-account directories. Both scripts reinstall idempotently — an existing target directory is removed and recreated with a fresh copy on every run.

**Kiro is a special case**, handled outside the agent-path loop: it doesn't read a folder+SKILL.md like the other agents, it reads a single flat steering file at `~/.kiro/steering/us-refinement.md`. Both installers generate that file by copying `SKILL.md`'s content and injecting `inclusion: always` as the first key inside the YAML frontmatter (right after the opening `---`) — no `scripts/`/`tests/` payload, since steering files are plain markdown only. `update.ps1`/`update.sh` regenerate it the same way from the refreshed central `SKILL.md`, but only if the steering file already exists (update never opts a machine into a new agent, only refreshes agents already installed). `us-refinement-uninstall.ps1`/`us-refinement-uninstall.sh` remove only that single file, never the parent `~/.kiro/steering/` directory (other unrelated Kiro skills may live there). Do not assume Kiro follows the shared `Copy-SkillFile`/`copy_skill_file` pattern when touching install/update/uninstall logic.

### `lib/skill-payload.ps1` / `lib/skill-payload.sh` — shared install/update logic

`install.ps1`/`install.sh` and `update.ps1`/`update.sh` used to each independently reimplement the agent-path list, the payload staging/copy/swap logic, and the Kiro frontmatter-injection transform — three copies per language that could drift apart. Those three pieces now live once per language in `lib/skill-payload.ps1` / `lib/skill-payload.sh`:

- `Get-AgentPaths` / `build_agent_paths` — builds the supported agent-path list (the static entries above plus dynamic `.claude-*` multi-account discovery).
- `Copy-SkillFile` / `copy_skill_file` — the staged copy/swap of `SKILL.md` + `scripts/` + `tests/` into a target path, warning (not silently skipping) if `scripts/`/`tests/` is missing at the source. This warning is now identical whether install or update calls it, closing a drift where install used to warn and update used to skip silently.
- `New-KiroSteeringFile` / `new_kiro_steering_file` — the Kiro transform, including its CRLF/LF EOL-detection logic (matches the injected `inclusion: always` line's terminator to the source `SKILL.md`'s own EOL style).

**Why install.ps1/install.sh don't just dot-source/source `lib/` unconditionally**: `install.ps1` is distributed via `irm <url> | iex` and `install.sh` via `curl <url> | bash` — in that flow there is no script file on disk and no sibling files exist until global mode downloads and extracts the release ZIP into the central store. So `install.ps1`/`install.sh` can only dot-source/source `lib/skill-payload.ps1`/`.sh`:
- in **local mode**, directly from `$SrcDir`/`$SRC_DIR` (the local checkout — always a real directory on disk, no timing issue), or
- in **global mode**, from `$CentralDir`/`$CENTRAL_DIR` — but only *after* the ZIP has been downloaded and extracted there, since that's the first point at which `lib/` physically exists. The ZIP download/extraction itself stays exactly as inline/self-contained as before.

`update.ps1`/`update.sh` always run from an existing central-store checkout (never via curl/iex), so they have no such ordering constraint: they refresh `lib/` from the newly-downloaded release ZIP in the same loop that already refreshes `scripts/` and `tests/` (clearing the stale central-store copy first so orphaned files never persist), then dot-source/source the refreshed `$CentralDir/lib/skill-payload.ps1` / `$CENTRAL_DIR/lib/skill-payload.sh` before calling its functions.

`us-refinement-uninstall.ps1`/`us-refinement-uninstall.sh` are intentionally untouched by this — they have their own simpler removal logic and are out of scope for this shared-library refactor.

### `docs/*-skills.md` — per-agent porting notes

`docs/agy-skills.md`, `docs/codex-skills.md`, `docs/copilot-skills.md`, `docs/opencode-skills.md`, and `docs/claude-skills.md` each document how a *different* AI agent's skill system discovers/loads/executes skills, plus a critique of this skill's own design from that agent's perspective. When porting `SKILL.md` behavior to a new agent or changing the skill's structure, check whether these notes already flag the tradeoff (e.g. `docs/claude-skills.md` calls out that the "Technical scope" output section arguably belongs to `/sdd-new`'s design phase, not refinement).

### SDD history (`openspec/changes/`)

This repo uses its own SDD workflow (proposal → spec → design → tasks → apply → verify → archive) to develop itself — `openspec/changes/us-3-installer/` and `openspec/changes/us-5-ai-context/` are the archived planning artifacts for the installer feature and the AI-DATA block feature respectively. Treat these as historical design records, not live documentation — `SKILL.md` and the installer scripts are the source of truth for current behavior.
