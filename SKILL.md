---
name: us-refinement
description: Refines raw user stories before they move to technical design or /sdd-new. Trigger ALWAYS when the user pastes an unrefined user story and asks to refine/clarify/polish it, when the user references a GitHub issue number for refinement (e.g. "refinar la issue #123", "let's refine issue 45"), or when a user story is about to be turned into a technical spec without explicit acceptance criteria. Also trigger on mentions of "criterios de aceptacion", "acceptance criteria", "INVEST", "ready for dev", or "definicion de terminado" in the context of a user story.
---

# User Story Refinement

IMPORTANT: This skill's instructions are written in English to be token-efficient and unambiguous for the model. Always respond to the user in the language they are using in the conversation (Spanish, English, etc.) — never respond in English just because this file is in English.

This skill turns a raw user story into a refined version ready for technical design or `/sdd-new`. The goal is to resolve ambiguity BEFORE it reaches the spec or the code — not after.

## When to activate

- The user pastes a user story (free text, ticket copy, raw description) and asks to refine it.
- The user references a GitHub issue by number for refinement (see "Reading from GitHub" below).
- The user is about to run `/sdd-new` or request a technical design and the story has no explicit acceptance criteria, edge cases, or dependencies.
- The user asks whether a story is "ready for dev" or "lista para desarrollo".

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

## Step 1: Analyze against INVEST criteria

Check the story against these six axes and silently note gaps (don't show this raw analysis to the user — use it to build Step 2's questions):

- **Independent**: does it depend on another unresolved story?
- **Negotiable**: is it over-specified (dictates implementation) or under-specified (says nothing)?
- **Valuable**: is the value to the user/business explicit?
- **Estimable**: is there enough info to estimate effort?
- **Small**: is it scoped to a reasonable cycle, or should it be split?
- **Testable**: can "done" be objectively verified?

## Step 2: Ask what's missing (flexible gate, NOT blocking)

Group clarification questions into these fixed categories, but only include categories where info is actually missing — don't ask about what's already clear:

- **Acceptance criteria** — if there's no Given/When/Then, ask for it.
- **Edge cases / unstated business rules** — unhappy paths, validations, permissions.
- **Dependencies** — other stories, external services, data that must exist beforehand.
- **Technical scope** — backend, frontend, both? New UI or pure logic?

Present the questions clearly and compactly (not as an endless questionnaire). After presenting them, explicitly offer:

> "If you'd rather, I can refine the story with what's here and mark these points as pending assumptions, instead of waiting for answers."

**This gate is flexible.** If the user answers, use those answers. If the user says "go ahead anyway", "skip it", "doesn't matter" or similar, proceed to Step 3 regardless — but document every unresolved point as an explicit **assumption** in the output (see format below). Never invent an answer and present it as a confirmed fact.

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

### Technical scope
- Backend: [yes/no — which parts]
- Frontend: [yes/no — which parts]

### Assumptions / pending
- [Only if the user chose to proceed without answering something: list each unconfirmed point here, clearly marked as an assumption, NOT as fact]
```

## Step 4: Offer to write back to GitHub (only if the source was a GitHub issue)

If the story came from a GitHub issue (Step 0B), after delivering the refined version ask the user how they want to document it — do not write to GitHub without an explicit choice:

- **Comment (default, non-destructive)**: post the refined story as a comment on the issue, preserving the original body untouched. Good when a human reviewer needs to approve the refinement before work starts.
  ```
  gh issue comment <number> --body-file <refined-story.md>
  ```
- **Replace the issue body**: overwrite the original description with the refined version (only if the user explicitly prefers this — it loses the original text from the visible body, though GitHub keeps an edit history).
  ```
  gh issue edit <number> --body-file <refined-story.md>
  ```

If the user wants the refinement to be approved by another human before SDD starts, the comment option is the better default — suggest it but let the user pick.

## Step 5: Closing

Deliver the refined story (and confirm the GitHub write-back if applicable) and ask if the user wants to adjust anything, split the story into several (if Step 1 flagged a "Small" violation), or is satisfied to move on to `/sdd-new` on their own.

## Style notes

- Keep the tone direct, no corporate filler about "the perfect user story".
- If the story already comes in well-formed (clear criteria, no ambiguity), say so and don't invent artificial questions just to follow the flow.
- If the story should be split into two or more (violates "Small" or mixes unrelated features), flag it BEFORE refining, not after.
- Never fabricate GitHub data. If `gh` returns nothing or fails, say so plainly instead of filling gaps from memory.
