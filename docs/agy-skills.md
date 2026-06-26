# Antigravity CLI Skill Architecture & Evaluation

This document outlines how the **Antigravity CLI (Gentle AI)** ecosystem discovers, loads, and executes custom skills, followed by an architectural critique and opinion of the current [SKILL.md](../SKILL.md) designed for user story refinement.

---

## 1. How Antigravity CLI Handles Skills

Antigravity uses a modular, declarative skill system designed to inject targeted instructions and helper resources into the agent's context window only when relevant. This keeps the active context window token-efficient.

### Discovery & Load Paths
Antigravity searches for skills in two main customization roots:
1. **Global Customizations:** `C:\Users\<username>\.gemini\config\skills/<skill_name>/`
2. **Project/Workspace Customizations:** `.agents/skills/<skill_name>/` (relative to the active workspace).

Additionally, developers can link out-of-tree directories by creating or editing a `skills.json` file in the global config directory:
```json
{
  "entries": [
    { "path": "C:/path/to/custom/git-repo" }
  ]
}
```

### Anatomy of a Skill Directory
A fully featured skill directory follows this structure:
```text
<skill_name>/
├── SKILL.md          # Required: Declarative rules & frontmatter triggers
├── scripts/          # Optional: Executable scripts (Node, Python, PowerShell)
├── references/       # Optional: Dense documentation or specs
└── examples/         # Optional: Reference implementations for the agent
```

### The Triggering Mechanism (Contextual Skill Loading)
The agent performs a **pre-flight self-check** before processing any user prompt:
1. It parses the YAML frontmatter of all registered `SKILL.md` files.
2. It evaluates the `name` and `description` (and optional file triggers) against the current conversation transcript and file context.
3. If a match occurs, the instructions in the body of `SKILL.md` are appended to the agent's working context as `## Project Standards (auto-resolved)`.

---

## 2. Critique and Architectural Opinion of [SKILL.md](../SKILL.md)

Our current user story refinement skill ([SKILL.md](../SKILL.md)) is built on top of classic Agile and behavior-driven development (BDD) patterns. Below is an architectural evaluation of its design:

### What it does right (Strengths)

1. **INVEST-based Silent Analysis (Step 1):**
   * *Opinion:* Doing the INVEST evaluation *silently* before asking questions is a great UX choice. Explaining INVEST criteria to a client-like user adds cognitive load. Using it internally to formulate targeted questions is much more productive.
2. **The Non-Blocking Gate / Flexible Assumptions (Step 2):**
   * *Opinion:* This is the strongest design choice in the file. Traditional refinement tools often block progress if a requirement is missing. By explicitly offering to *"refine with what is here and document assumptions,"* the skill keeps the momentum going without frustrating the user.
3. **Standardized Output Format (Step 3):**
   * *Opinion:* Structuring output with `Given/When/Then` scenarios ensures that the resulting user story is immediately testable. Explicitly including `Technical scope` and `Assumptions` acts as a clear bridge for subsequent steps like `/sdd-new`.
4. **Token-Optimized English Instructions:**
   * *Opinion:* Writing the rule file in English but instructing the model to reply in the user's current language (Spanish in this case) is highly efficient. LLMs process structural instructions more reliably in English, saving tokens and improving adherence.

### Areas for Improvement & Opportunities

1. **GitHub Write-back (Step 4) is CLI-centric:**
   * *Opinion:* The skill relies heavily on the local `gh` CLI tool to fetch and comment on issues. While powerful, this makes the skill less portable for web-based agents (like Cursor or Copilot Chat) that don't have access to a local terminal.
   * *Mitigation:* We should generalize this step. If a terminal `gh` CLI isn't detected, the skill should gracefully fall back to outputting the markdown blocks for the user to copy/paste manually.
2. **Cursor Rule Compatibility:**
   * *Opinion:* The current frontmatter uses `name` and `description`. To make this file directly compatible with Cursor (`.cursor/rules/`), our sync script needs to automatically map these to `description`, `globs`, and `alwaysApply` parameters.

---

## 3. Alignment with Wider AI Ecosystem

The structural design of Antigravity skills directly mirrors the latest updates in tools like **Claude Code** (which parses folder-based `SKILL.md` files under `~/.claude/skills/` identically) and **GitHub Copilot** (which uses `.github/skills/`). 

This standardization validates our approach of keeping `SKILL.md` as our single source of truth, managing it under Git, and using a lightweight compiler script to generate flatter configurations (like `.cursorrules` or `.mdc` files) for editors that do not yet support folder-based skill structures.
