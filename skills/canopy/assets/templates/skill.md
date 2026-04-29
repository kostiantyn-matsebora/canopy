---
name: <skill-name>
description: <one-line description>
compatibility: Requires canopy-runtime for Claude Code (`gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`) or GitHub Copilot (`--agent github-copilot`). Execution on other platforms is not supported.
metadata:
  argument-hint: "<required-arg> [optional-arg]"
---

> **Runtime required:** This skill uses Canopy tree notation and requires the
> canopy-runtime execution engine. If canopy-runtime is not active in your
> current context, **stop immediately** — do not attempt to execute this skill.
> Inform the user: "canopy-runtime must be installed and activated first.
> Run: `gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`"

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
