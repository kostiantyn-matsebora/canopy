---
title: Terminology
nav_order: 4
description: "Quick-lookup glossary of Canopy terms — one-sentence definitions, each linked to the full reference."
permalink: /terminology/
---

# Terminology

One-sentence definitions of the vocabulary used throughout the Canopy docs. Each entry links to the section that covers it in depth — start here when a term shows up in [Concepts](concepts/) or [Reference](reference/) and you want a quick anchor before diving in.

---

## Skills & spec

- **Agent Skill** — a `SKILL.md` package distributed per the [agentskills.io](https://agentskills.io) standard. → [Reference — Framework Skills](reference/FRAMEWORK_SPEC.md#framework-skills)
- **Canopy-flavored skill** — an Agent Skill that uses Canopy's `## Tree` section; requires `canopy-runtime` to execute. → [Concepts — The tree as source of truth](concepts/#the-tree-as-source-of-truth)
- **agentskills.io** — the cross-vendor Agent Skill specification Canopy is layered on top of. Same `SKILL.md`, same install tooling. → [Concepts — agentskills.io alignment](concepts/#agentskillsio-alignment)
- **SKILL.md** — the required entry-point file at the root of a skill directory; case-sensitive, uppercase. → [Reference — Framework Skills](reference/FRAMEWORK_SPEC.md#framework-skills)
- **Frontmatter** — YAML metadata block at the top of `SKILL.md` (`name`, `description`, `compatibility`, `metadata`, etc.). → [Concepts — Skill anatomy](concepts/#skill-anatomy)
- **Compatibility field** — frontmatter free-text declaration (≤500 chars) naming runtime dependencies and install tools. → [Reference — Compatibility Field](reference/FRAMEWORK_SPEC.md#compatibility-field)
- **Safety preamble** — runtime-required guard block at the top of a `## Tree` skill's body that halts execution on agents without canopy-runtime. → [Concepts — Skill anatomy](concepts/#skill-anatomy)
- **metadata** — frontmatter sub-object that holds non-spec fields like `argument-hint` and `user-invocable`. → [Reference — Framework Skills](reference/FRAMEWORK_SPEC.md#framework-skills)

---

## Tree & ops

- **Tree** — the sequential execution pipeline under `## Tree`; nodes run top-to-bottom with explicit branching. → [Reference — Tree Execution Model](reference/FRAMEWORK_SPEC.md#tree-execution-model)
- **Tree notation** — the `<<` (input), `>>` (output), `|` (separator) symbols used in tree nodes. → [Reference — Notation](reference/FRAMEWORK_SPEC.md#notation)
- **Op** — a named, reusable step identified by an `ALL_CAPS` name (`DEPLOY`, `VERIFY`, `ROLLBACK`). → [Concepts — Ops](concepts/#ops)
- **Op call** — a tree node that invokes an op by name with optional `<<` inputs and `>>` outputs. → [Reference — Tree Execution Model](reference/FRAMEWORK_SPEC.md#tree-execution-model)
- **Op definition** — the body that implements an op, written as prose or as a sub-tree, in `references/ops.md` or `references/ops/<name>.md`. → [Reference — Skill-Local references/ops.md](reference/FRAMEWORK_SPEC.md#skill-local-referencesopsmd)
- **Primitive** — a built-in op (`IF`, `SWITCH`, `FOR_EACH`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`, etc.) provided by canopy-runtime; never overridable. → [Reference — Primitives](reference/PRIMITIVES.md)
- **Op lookup chain** — the resolution order for an `ALL_CAPS` identifier: skill-local → consumer-defined → framework primitives. → [Reference — Op Lookup Order](reference/FRAMEWORK_SPEC.md#op-lookup-order)

---

## Subagents

- **Subagent** — an isolated context window invoked from the parent skill; reads files, distills results, and returns a schema-shaped summary. → [Concepts — Subagents](concepts/#subagents)
- **`## Agent`** — the declaration block in `SKILL.md` that describes the explore subagent's task. → [Concepts — Subagents](concepts/#subagents)
- **EXPLORE** — the runtime-injected primitive that invokes the declared `## Agent` subagent; required as the first tree node when `## Agent` is present. → [Concepts — Subagents](concepts/#subagents)
- **Schema** — JSON contract at `assets/schemas/<name>.json` defining the shape of a subagent's output. → [Reference — Category Resource Subdirectories](reference/FRAMEWORK_SPEC.md#category-resource-subdirectories)

---

## Framework skills

- **canopy-runtime** — execution engine; interprets canopy-flavored skills, owns the primitives spec, ships the per-platform runtime rules. Always required. → [Reference — Framework Skills](reference/FRAMEWORK_SPEC.md#framework-skills)
- **canopy** — authoring agent invoked as `/canopy`; create / modify / scaffold / validate / improve / advise / refactor / convert. Depends on `canopy-runtime`. → [Reference — Framework Skills](reference/FRAMEWORK_SPEC.md#framework-skills)
- **canopy-debug** — optional trace wrapper invoked as `/canopy-debug <skill>`; adds phase banners and per-node tracing. → [Reference — Debug Mode](reference/FRAMEWORK_SPEC.md#debug-mode)

---

## Activation & runtime

- **Activation** — the one-time process that registers canopy-runtime with the host platform by writing the marker block to its ambient instructions file. → [Reference — Activation](reference/FRAMEWORK_SPEC.md#activation)
- **Marker block** — the canopy-runtime activation block written into `CLAUDE.md` (Claude Code) or `.github/copilot-instructions.md` (Copilot). → [Reference — Activation](reference/FRAMEWORK_SPEC.md#activation)
- **Skills root** — the directory holding installed skills; resolved at runtime as `.agents/skills/` → `.claude/skills/` → `.github/skills/`. → [Reference — Skills Root Resolution](reference/FRAMEWORK_SPEC.md#skills-root-resolution)
- **Runtime spec** — the per-platform execution rules loaded by canopy-runtime based on the active host (Claude Code or GitHub Copilot). → [Reference — Runtimes](reference/RUNTIMES.md)
- **Interpreter model** — Canopy's cross-platform approach: `SKILL.md` is the single source of truth, the runtime walks the tree at execution time and adapts to the active host. → [Reference — Runtime Model](reference/FRAMEWORK_SPEC.md#runtime-model)

---

## Resources & layout

- **Standard layout** — the agentskills.io directory layout: only `SKILL.md` at root, with `scripts/`, `references/`, and `assets/` as the three top-level subdirectories. → [Reference — Framework Skills](reference/FRAMEWORK_SPEC.md#framework-skills)
- **Category resource** — a structured file inside a category subdir (`assets/templates/`, `assets/constants/`, `assets/schemas/`, etc.); referenced from the tree by `Read \`<category>/<file>\``. → [Reference — Category Resource Subdirectories](reference/FRAMEWORK_SPEC.md#category-resource-subdirectories)
- **Legacy flat layout** — older skills with category dirs at the skill root (`schemas/`, `templates/`, `commands/`, …) instead of nested under `assets/`; still fully supported. → [Reference — Framework Skills](reference/FRAMEWORK_SPEC.md#framework-skills)
