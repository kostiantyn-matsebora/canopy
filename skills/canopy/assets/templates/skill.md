---
name: <skill-name>
description: <one-line description>
compatibility: Requires the canopy-runtime skill (published at github.com/kostiantyn-matsebora/claude-canopy). Install with any agentskills.io-compatible tool — e.g. `gh skill install`, `git clone`, the repo's `install.sh`/`install.ps1`, or the Claude Code plugin marketplace. Supports Claude Code and GitHub Copilot.
metadata:
  argument-hint: "<required-arg> [optional-arg]"
---

> **Runtime required:** This skill uses Canopy tree notation and depends on the
> canopy-runtime skill. If canopy-runtime is not installed in the active
> workspace (no `canopy-runtime/SKILL.md` under `.claude/skills/`,
> `.github/skills/`, or `.agents/skills/`, and no canopy-runtime marker block
> in `CLAUDE.md` or `.github/copilot-instructions.md`), install it first using
> any tool available to you (see this skill's `compatibility` field for the
> source). Do not interpret the tree without canopy-runtime active.

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
