# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`us-refinement` is not an application — it's a portable **AI agent skill** (a `SKILL.md` contract) that refines raw user stories into structured, INVEST-checked specs with Given/When/Then acceptance criteria, before they go to technical design or `/sdd-new`. The repo ships the skill itself plus installers that deploy it as a symlinked/junctioned skill directory for multiple AI agents (Claude Code, Gemini/Antigravity, OpenCode).

The actual "product" of this repo is `SKILL.md`. Everything else (installers, validator script, docs) supports authoring, distributing, and verifying that one file.

## Commands

There is no build step, package manager, or test framework — this is a skill + shell scripts repo.

**Validate an AI-DATA block** (the hidden HTML-comment metadata block a refined story must contain):
```bash
python scripts/validate_refinement.py tests/mock_valid_us.md     # expect exit 0
python scripts/validate_refinement.py tests/mock_invalid_us.md   # expect exit 1, prints field errors
```
Run this after editing the `<!-- [AI-DATA] -->` schema in `SKILL.md` (Step 3 output format) or the parser in `scripts/validate_refinement.py` to confirm they stay in sync — there are no automated test files beyond these two mocks.

**Install the skill locally for testing** (creates a junction/symlink, so edits to this repo are picked up live by the installed agent):
```powershell
./install.ps1 -Local
```
```bash
./install.sh --local
```

**Install globally** (copies `SKILL.md`, `scripts/`, `docs/`, `tests/` into `~/.hjagar/skills/us-refinement`, then links each agent's skill dir to that central copy):
```powershell
./install.ps1
```
```bash
./install.sh
```
Use `-Path <dir>` / `--path <dir>` to install from a source directory other than the script's own location.

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

- **Local mode** (`-Local`/`--local`): links each supported agent's skill directory directly to *this* source checkout (Windows: directory **junction**, chosen specifically to avoid requiring admin elevation; Unix: symlink). Live edits in this repo apply immediately to all linked agents.
- **Global mode** (default): copies `SKILL.md`, `scripts/`, `docs/`, `tests/` into a central `~/.hjagar/skills/us-refinement`, then links every agent path to that central copy instead of to the repo. `openspec/`, `.git/`, and `.gitignore` are intentionally excluded from this copy to keep the installed payload minimal.

Agent target paths currently wired into both scripts: `~/.gemini/skills/us-refinement`, `~/.claude/skills/us-refinement`, `~/.config/opencode/skills/us-refinement`. Both scripts re-link idempotently — if a link already points at the correct target, they no-op; if it points elsewhere or is a real directory, they remove and recreate it.

### `docs/*-skills.md` — per-agent porting notes

`docs/agy-skills.md`, `docs/codex-skills.md`, `docs/copilot-skills.md`, `docs/opencode-skills.md`, and `docs/claude-skills.md` each document how a *different* AI agent's skill system discovers/loads/executes skills, plus a critique of this skill's own design from that agent's perspective. When porting `SKILL.md` behavior to a new agent or changing the skill's structure, check whether these notes already flag the tradeoff (e.g. `docs/claude-skills.md` calls out that the "Technical scope" output section arguably belongs to `/sdd-new`'s design phase, not refinement).

### SDD history (`openspec/changes/`)

This repo uses its own SDD workflow (proposal → spec → design → tasks → apply → verify → archive) to develop itself — `openspec/changes/us-3-installer/` and `openspec/changes/us-5-ai-context/` are the archived planning artifacts for the installer feature and the AI-DATA block feature respectively. Treat these as historical design records, not live documentation — `SKILL.md` and the installer scripts are the source of truth for current behavior.
