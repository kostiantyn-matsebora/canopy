---
name: canopy-debug
description: Trace any Canopy skill with live phase banners and per-node tree tracing. Respects the current mode — in plan mode no changes are applied; in edit mode the skill executes normally.
license: MIT
compatibility: Requires the canopy-runtime skill (published at github.com/kostiantyn-matsebora/claude-canopy). Install with any agentskills.io-compatible tool — e.g. `gh skill install`, `git clone`, the repo's `install.sh`/`install.ps1`, or the Claude Code plugin marketplace. Supports Claude Code and GitHub Copilot.
metadata:
  version: "0.18.0"
  author: kostiantyn-matsebora
  argument-hint: "<skill-name> [skill-arguments]"
---

> **Runtime required:** This skill uses Canopy tree notation and depends on the
> canopy-runtime skill. If canopy-runtime is not installed in the active
> workspace (no `canopy-runtime/SKILL.md` under `.claude/skills/`,
> `.github/skills/`, or `.agents/skills/`, and no canopy-runtime marker block
> in `CLAUDE.md` or `.github/copilot-instructions.md`), install it first using
> any tool available to you (see this skill's `compatibility` field for the
> source). Do not interpret the tree without canopy-runtime active.

Preamble: parse $ARGUMENTS — first token is `target_skill`, remainder is `skill_args`.

---

## Tree

* canopy-debug
  * IF << $ARGUMENTS is empty or skill name is missing
    * END Usage: /canopy-debug <skill-name> [skill-arguments]
  * bind target_skill = first token of $ARGUMENTS
  * bind skill_args = remainder of $ARGUMENTS (may be empty)
  * detect platform: `.claude/skills/` present → claude; `.github/skills/` present → copilot
  * IF << platform == "claude"
    * Read `../canopy-runtime/SKILL.md` for the canopy execution engine overview
    * Read `../canopy-runtime/references/runtime-claude.md` for Claude Code runtime rules
    * Read `../canopy-runtime/references/framework-ops.md` for primitive spec
    * Read `../canopy-runtime/references/skill-resources.md` for category semantics, op lookup chain, tree format
  * ELSE
    * Read `../canopy-runtime/SKILL.md` for the canopy execution engine overview
    * Read `../canopy-runtime/references/runtime-copilot.md` for Copilot runtime rules
    * Read `../canopy-runtime/references/framework-ops.md` for primitive spec
    * Read `../canopy-runtime/references/skill-resources.md` for category semantics, op lookup chain, tree format
  * Read `assets/policies/debug-output.md` for debug rendering and animation protocol
  * EMIT_PHASE_BANNER << phase=Initialize | skill=target_skill | args=skill_args
  * EXECUTE_WITH_TRACE << target_skill | skill_args

## Rules

- Load `assets/policies/debug-output.md` before any output — never emit debug output without it
- Respect the current Claude Code mode — plan mode means simulate mutations; edit mode means execute normally
- Emit banners and tree-state blocks to the stream as Claude narrates; never buffer and emit at end

## Response: target_skill | phases_executed | nodes_executed | final_status
