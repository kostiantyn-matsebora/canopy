---
name: <skill-name>
description: <one-line description>
compatibility: Requires the canopy-runtime skill (published at github.com/kostiantyn-matsebora/canopy). Install with any agentskills.io-compatible tool — e.g. `gh skill install`, `git clone`, the repo's `install.sh`/`install.ps1`, or the Claude Code plugin marketplace. Supports Claude Code and GitHub Copilot.
metadata:
  argument-hint: "<required-arg> [optional-arg]"
  canopy-features: [interaction]
---

> **Runtime required.** This skill uses Canopy tree notation; canopy-runtime must be active.
>
> **Detect canopy-runtime** — present if either:
> - `canopy-runtime/SKILL.md` exists under `.claude/skills/`, `.github/skills/`, or `.agents/skills/`, OR
> - a canopy-runtime marker block exists in `CLAUDE.md` or `.github/copilot-instructions.md`.
>
> **If neither is present** — install canopy-runtime first (see the `compatibility` field for the source and install options), then re-invoke this skill.
>
> Do not interpret the `## Tree` without canopy-runtime active.

<Preamble: parse $ARGUMENTS and set context variables here.>

---

## Tree

* <skill-name>
  * SHOW_PLAN >> <field1> | <field2>
  * ASK << Proceed? | Yes | No
  * <do the thing>

## Rules

- <invariant that applies throughout execution>

## Response: Summary / Changes / Notes
