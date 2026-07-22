---
name: us-refinement
description: "Trigger: /refine, /refinar, pasted As a/Como... stories, or GitHub issue refinement. Refines a raw user story into an INVEST-checked spec with Given/When/Then acceptance criteria before technical design or /sdd-new."
license: MIT
metadata:
  author: hjagar
  version: "1.3.0"
---

# User Story Refinement

IMPORTANT: This skill's instructions are written in English to be token-efficient and unambiguous for the model. Always respond to the user in the language they are using in the conversation (Spanish, English, etc.) — never respond in English just because this file is in English.

This skill turns a raw user story into a refined version ready for technical design or `/sdd-new`. The goal is to resolve ambiguity BEFORE it reaches the spec or the code — not after.

## When to activate

- The user types the manual shortcuts `/refine` or `/refinar` (optionally followed by the `--deep` flag, issue number, or story draft, e.g., `/refine --deep 22` or `/refinar --deep`).
- The user pastes a story draft containing Spanish agile structure elements (e.g., `Como [rol]`, `Quiero [acción]`, `Quiero poder [acción]`, `Para [beneficio]`).
- The user pastes a story draft containing English agile structure elements (e.g., `As a [role]`, `I want to [action]`, `So that [value]`).
- The user references a GitHub issue by number for refinement (e.g., "refinar la issue #123", "let's refine issue 45").
- The user asks whether a story is "ready for dev" or "lista para desarrollo".
- The user mentions agile terms such as "criterios de aceptación", "acceptance criteria", "INVEST", "definición de terminado", or "definition of done".

## Step 0: Determine the source of the user story

Two possible sources — detect which one applies:

**A. Pasted text** — the user already gave you the story content. Use it directly, skip to Step 1.

**B. GitHub issue reference** — the user says something like "vamos a refinar la issue #123" or "refine issue 45 from github". In this case:

1. Identify the repo. If the user is working inside a repo (check current directory with `git remote -v` or ask if ambiguous), use it. If multiple repos are plausible, ask which one.
2. Fetch the issue with the `gh` CLI:
   ```
   gh issue view <number> --json title,body,url,labels,comments
   ```
3. Use the issue's title + body as the raw user story input for Step 1.
4. If `gh` is not authenticated or the command fails, tell the user clearly and ask them to paste the story manually instead — do not guess the content.

## Step 0.5: Environment and Storage Setup (flexible gate, NOT blocking)

Before starting the refinement analysis, check the available tools and configure the storage mode:
1. **Detect Engram**: Check if the `engram` MCP server is active in the current session.
   - **If active**: Prompt the user to choose their preferred storage mode (with `engram` as the recommended default). Present the following options:
     - `engram` (memory-only, no local files created)
     - `openspec` (local files only under the `openspec/changes/` directory)
     - `hybrid` (both: save to memory and local files in real time)
     - `hybrid-delayed` (use local files for visualization during the session, saving everything to Engram at the end of the session).

     **This gate is flexible.** After presenting the options, explicitly offer: "If you'd rather not choose right now, I can continue with `engram` as the default." If the user says "go ahead anyway", "skip it", "doesn't matter" or similar instead of picking one, proceed using `engram` as the storage mode, without blocking the flow.
   - **If inactive**: Check if the workspace contains an active SDD structure (presence of `.agents/` or `openspec/` folders). If yes, default to `openspec` local file storage. Otherwise, default to standard console log output. No question is asked in this case, so there is nothing to bypass.

## Step 1: Analyze against INVEST criteria

Check the story against these six axes and silently note gaps (don't show this raw analysis to the user — use it to build Step 2's questions):

- **Independent**: does it depend on another unresolved story?
- **Negotiable**: is it over-specified (dictates implementation) or under-specified (says nothing)?
- **Valuable**: is the value to the user/business explicit?
- **Estimable**: is there enough info to estimate effort?
- **Small**: is it scoped to a reasonable cycle, or should it be split? Unlike the other five axes, don't fold this one silently into Step 2 — see the scope pre-check below.
- **Testable**: can "done" be objectively verified?

### Scope pre-check: stories that bundle multiple features

If the story clearly describes two or more independent, separately shippable features or functionalities (a "Small" violation), warn the user before moving to Step 2: point out which parts look divisible, and offer to split the story into separate ones. If the user prefers to keep it as a single story, respect that and continue refining it whole — don't force a split. If the story describes a single cohesive functionality, skip this warning entirely and proceed straight to Step 1.5/Step 2.

## Step 1.5: Technical Feasibility and Component Scan (OPT-IN ONLY)

This step runs ONLY if the user explicitly provided the `--deep` flag in their manual trigger (e.g., `/refine --deep`). If running in Standard Mode (without `--deep`), skip this step entirely and do NOT execute any system or shell commands.

When running in Deep Mode (`--deep`), inspect the system PATH and repository workspace to analyze feasibility before asking questions:
1. **Scan for mentioned tools/runtimes**: Scan the raw user story for external dependencies (e.g., `Docker`, `Python`, `gh`, `unzip`, `shellcheck`, `winget`). Before building any verification command, check each extracted tool name against the safe pattern `^[\w.-]+$` — never build a shell command from free text without this check.
   - **If the name matches the pattern**: run the check (e.g., `where <tool>` on Windows or `command -v <tool>` on Unix/WSL) to see if the tool is installed in the system PATH. If a tool is missing, record a warning to be appended to the final output.
   - **If the name does NOT match the pattern**: do not run any command with that text. Instead, record a warning in the final output stating that the tool name could not be verified due to an invalid format, so the user can check it manually.
2. **Scan for mentioned codebase components/files**: Scan the raw user story for existing files/components (e.g., `installer`, `uninstaller`, `validator`). Search the repository (e.g., via directory list or git searches) to see if matching files exist.
   - If multiple files match (e.g., both `install.ps1` and `install.sh` when "installer" is mentioned), or if no files match, record a warning to ask a clarification question in Step 2.

## Step 2: Ask what's missing (flexible gate, NOT blocking)

Group clarification questions into these fixed categories, but only include categories where info is actually missing — don't ask about what's already clear. The list below is a priority order, not just a grouping: when more than one category has gaps, present and resolve them in this order (don't jump ahead to a lower-priority category before the higher-priority ones are answered or explicitly skipped), even if the user answers incrementally, one category at a time.

- **Acceptance criteria** — if there's no Given/When/Then, ask for it.
- **Dependencies** — other stories, external services, data that must exist beforehand.
- **Technical scope** — backend, frontend, both? New UI or pure logic?
- **Edge cases / unstated business rules** — unhappy paths, validations, permissions.
- **Technical Feasibility / Ambiguity** — (Only if running in Deep Mode `--deep` and Step 1.5 flagged multiple file matches or zero matches): ask the user to clarify which specific file/component they target. Always presented last. If running in Standard Mode, do not include this category.

Present the questions clearly and compactly (not as an endless questionnaire). After presenting them, explicitly offer:

> "If you'd rather, I can refine the story with what's here and mark these points as pending assumptions, instead of waiting for answers."

**This gate is flexible.** If the user answers, use those answers. If the user says "go ahead anyway", "skip it", "doesn't matter" or similar, proceed to Step 3 regardless.

Every clarification question that remains unanswered or is explicitly skipped by the user must be documented as an individual, unchecked checkbox item (`- [ ]`) in the output's `### Assumptions` section. Never invent an answer and present it as a confirmed fact.

## Step 3: Generate the refined user story

This skill NEVER runs `/sdd-new` or generates the technical spec on its own. It only produces the refined story, ready for the user to decide when and how to proceed.

Output format:

```markdown
## [Story title]

**As a** [role]
**I want** [action]
**So that** [value/benefit]

### Acceptance criteria

**Scenario 1: [scenario name]**
- Given [initial context]
- When [user/system action]
- Then [expected result]

**Scenario 2: [unhappy path / edge case]**
- Given ...
- When ...
- Then ...

(add as many scenarios as needed — always include at least one unhappy path when relevant)

### Dependencies
- [List of stories, services, or prior data required, or "None identified"]
- [WARNING: Any missing tool warnings discovered in Step 1.5, e.g., "Tool 'Docker' is mentioned in the story but is missing from the system PATH."]

### Assumptions
- [ ] [First unconfirmed assumption / skipped question mapping]
- [ ] [Second unconfirmed assumption / skipped question mapping]

<!-- [AI-DATA]
id: [US-{issue_number} if sourced from GitHub (Step 0B), e.g., US-24, OR US{number} if sourced from pasted text (Step 0A) — see "ID Generation for Pasted Stories" below for how to determine {number}, e.g., US12]
type: [feat|fix|refactor|docs|chore]
breaking: [true|false]
dependencies: [list of referenced story IDs in their exact format, matching hyphens if present, e.g., [US-24, US1] or []]
metadata:
  scope:
    backend: [true|false]
    frontend: [true|false]
  role: "[role name]"
  endpoint: "[HTTP method + route, or 'none']"
  auth: "[auth policy, or 'none']"
  ui: "[page|modal|form|action|none]"
scenarios:
  - name: "[Scenario 1 name]"
    given: "[preconditions in English]"
    when: "[actions in English]"
    then: "[expected outcomes in English]"
-->
```

### ID Generation for Pasted Stories (Step 0A only)
When the story source is pasted text (Step 0A), generate the `id` field of the AI-DATA block by following this exact chain, stopping at the first rule that applies:
1. **Explicit ID in the text**: If the pasted text already mentions an identifier matching the `USxx` pattern (e.g., "US12", "US-7"), reuse that number as the `id` — do not generate a new one.
2. **Scan active storage**: If no explicit ID is present, scan the storage mode(s) configured in Step 0.5 (Engram and/or the `openspec/changes/` directory) for previously recorded stories, find the highest `USxx` number in use, and assign the next one (`max + 1`).
3. **Ask the user**: If there is no explicit ID and no storage with history available (Engram inactive, no `openspec/` folder, or storage tools unconfigured), ask the user directly which number/ID to use. Never invent or assume one.

This chain never depends on `gh`/GitHub at any point — Step 0B (GitHub issues) already derives the `id` from the issue number directly and does not use this chain.

### Conditional Rendering Rules for "### Assumptions"

- **Omit section entirely**: If there are no unresolved points (no questions were asked in Step 2, or the user answered all of them), the `### Assumptions` section header and its items must be omitted entirely from the output.
- **Unchecked checkboxes**: All assumptions must be rendered as unchecked checkboxes (`- [ ]`). Never check them in the generated output.
- **Re-refinements**: If you are refining a story that already has an `### Assumptions` section in its current body/file, compare the user's new inputs against the existing checkboxes. Remove any checkbox items that have been resolved, and keep only the ones that remain unresolved. If all items are resolved, remove the section completely.
- **No "### Technical scope" section**: the output never includes a "### Technical scope" section — that decision belongs to whatever technical design step comes next (`/sdd-new`, another SDD/openspec workflow, or a human architect), not to refinement. Keeping it out of the visible markdown keeps the story in pure business language, regardless of which downstream process the user picks. `metadata.scope.backend`/`metadata.scope.frontend` in the hidden AI-DATA block still capture the signal for any tooling that reads it. If you are re-refining a story whose existing body/comment contains a "### Technical scope" section from a previous refinement, omit it from the new output even though it was present before.

### Contextual Hint for Deep Mode (Standard Mode only)
- If running in Standard Mode (without `--deep`) and the raw user story mentions external tools (e.g., Docker, Python, gh, unzip, shellcheck, winget) or codebase files/components (e.g., installer, uninstaller, validator, script), append a non-intrusive GitHub-style tip alert at the very end of the markdown file (after the HTML comments block or as part of the output text):
  ```markdown
  > [!TIP]
  > This story mentions external tools or files (e.g., [tool/file names]). You can run `/refine --deep` or `/refinar --deep` to scan your system PATH and workspace for technical feasibility.
  ```
  This tip must be based solely on a text-only scan of the input story — do NOT execute any system or shell commands to verify their presence when in Standard Mode.

### Local File Persistence for openspec/hybrid/hybrid-delayed Storage
- If the storage mode chosen in Step 0.5 is `openspec`, `hybrid`, or `hybrid-delayed` (any mode that writes a local file), the refined story must be written to `openspec/changes/US{n}-{slug}/story.md`, mirroring this repo's own SDD per-change folder convention (one folder per story), with `US{n}-{slug}` also included as part of the story's title or id inside the file content.
- **If `openspec/changes/US{n}-{slug}/` does not exist yet**: warn the user that it will be created and ask for explicit confirmation before creating it. Never create it silently.
  - **If the user confirms**: create the folder and write `story.md` inside it.
  - **If the user declines, or the folder creation fails** (permissions, read-only disk): fall back to printing the refined story via console output instead. It becomes the user's responsibility to copy it manually if they want to keep it — do not silently retry or pick another location.
- **If the folder already exists**: write directly to `story.md` inside it, without asking for confirmation again.

### Post-Refinement Validation Hint
- If the storage mode chosen in Step 0.5 is `openspec`, `hybrid`, or `hybrid-delayed` (any mode that writes a local file), append a non-intrusive GitHub-style tip alert suggesting the user validate the AI-DATA block against the schema:
  ```markdown
  > [!TIP]
  > You can run `python scripts/validate_refinement.py <path-to-generated-file>` to validate this story's AI-DATA block against the schema.
  ```
  Use the actual path of the file you just wrote to.
- If the storage mode is `engram` (pure memory, no local file), skip this hint entirely — there is no file path to point to.

## Step 4: Offer to write back to GitHub (only if the source was a GitHub issue)

If the story came from a GitHub issue (Step 0B):

1. **Write the refined output to a real file first.** `--body-file` needs an actual file behind it — write the Step 3 output to a real, agent-accessible temporary file (e.g., a scratch/temp location) and use that path as `<refined-story-file>` in every command below. Do this regardless of the storage mode chosen in Step 0.5: this file is only a bridge for the `gh` write-back, not a second copy of the story's persistent record.
2. Verify if the GitHub CLI is available, authenticated, and the repo remote is GitHub-hosted (checking `gh auth status` or its path executable, plus the remote URL detected in Step 0B).
   - **If available, authenticated, and GitHub-hosted**: Ask the user how they want to document it — do not write to GitHub without an explicit choice:
     - **Comment (default, non-destructive)**: post the refined story as a comment on the issue, preserving the original body untouched. Good when a human reviewer needs to approve the refinement before work starts.
       ```
       gh issue comment <number> --body-file <refined-story-file>
       ```
     - **Replace the issue body**: overwrite the original description with the refined version (only if the user explicitly prefers this).
       ```
       gh issue edit <number> --body-file <refined-story-file>
       ```

     Check the command's exit status:
     - **On success**: delete `<refined-story-file>` — its content is now persisted on GitHub (and, if the storage mode is `engram`, still lives in Engram's memory; the file was never the persistent record either way).

       Then inspect the generated refinement text in memory to check for pending assumptions:
       - **If the output contains the `### Assumptions` section with at least one unchecked checkbox (`- [ ]`)**:
         Ensure the label exists and apply it to the issue:
         ```
         gh label create needs-review-assumptions --color FBCA04 --description "Issue has pending assumptions that need business review" --force
         gh issue edit <number> --add-label "needs-review-assumptions"
         ```
       - **If the output does not contain the `### Assumptions` section or has no unchecked checkboxes**:
         Remove the label from the issue (run this non-blockingly, ignoring any warnings if the label is not present):
         ```
         gh issue edit <number> --remove-label "needs-review-assumptions"
         ```
     - **On failure** (network error, permissions, etc.): keep `<refined-story-file>` on disk, and tell the user the write-back failed and why, applying the same manual-copy guidance as the case below.

   - **If `gh` is unavailable/unauthenticated, or the repo host isn't yet supported by this skill's tooling (e.g. GitLab, Bitbucket)**: keep `<refined-story-file>` on disk, and tell the user the automatic write-back can't run — they need to manually copy the content into the issue and delete the file afterward themselves.

## Step 5: Closing

Deliver the refined story (and confirm the GitHub write-back if applicable) and:
1. **Detect SDD Setup**: Check if the current repository contains `.agents/` or `openspec/` folders, or if it is inside an active SDD workspace.
   - **If found**: Suggest continuing directly with the SDD command `/sdd-new <change-name>` or the exploration phase.
   - **If not found**: Ask if the user wants to adjust anything, split the story into several (if Step 1 flagged a "Small" violation), or is satisfied to wrap up.

## Style notes

- Keep the tone direct, no corporate filler about "the perfect user story".
- If the story already comes in well-formed (clear criteria, no ambiguity), say so and don't invent artificial questions just to follow the flow.
- If the story should be split into two or more (violates "Small" or mixes unrelated features), flag it BEFORE refining, not after.
- Never fabricate GitHub data. If `gh` returns nothing or fails, say so plainly instead of filling gaps from memory.
- **Separation of concerns (No implementation code)**: The refined user story must never contain code blocks, scripts, function signatures, directory paths of implementation, or architectural designs. Keep the content strictly focused on what the user/system wants and why, leaving the technical "How" for the design/SDD phase.
