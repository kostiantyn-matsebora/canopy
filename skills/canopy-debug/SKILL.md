---
name: canopy-debug
description: Trace any Canopy skill with live phase banners and per-node tree tracing. Respects the current mode — in plan mode no changes are applied; in edit mode the skill executes normally.
license: MIT
compatibility: Requires canopy-runtime for Claude Code (`gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`) or GitHub Copilot (`--agent github-copilot`). Execution on other platforms is not supported.
metadata:
  version: "0.18.0"
  author: kostiantyn-matsebora
  argument-hint: "<skill-name> [skill-arguments]"
---

> **Runtime required:** This skill uses Canopy tree notation and requires the
> canopy-runtime execution engine. If canopy-runtime is not active in your
> current context, **stop immediately** — do not attempt to execute this skill.
> Inform the user: "canopy-runtime must be installed and activated first.
> Run: `gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`"

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
