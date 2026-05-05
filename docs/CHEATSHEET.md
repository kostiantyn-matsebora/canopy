---
title: Cheatsheet
nav_order: 2
description: "One-page reference: skill anatomy, primitives, op syntax, category dirs, agent operations, debug mode."
---

# Canopy Cheatsheet

Quick reference. Full spec: [Reference](reference/) · Concepts: [CONCEPTS.md](CONCEPTS.md)

---

## Skill anatomy

`frontmatter` (incl. `compatibility`) → safety preamble → `## Agent` (optional) → `## Tree` → `## Rules` → `## Response:`

```
skill-name/
├── SKILL.md              ← only file at root (uppercase, exact spelling)
├── scripts/              ← executable code (.ps1, .sh)
├── references/           ← docs loaded on demand
│   ├── ops.md            ← simple skills
│   └── ops/<name>.md     ← per-op definitions (complex skills)
└── assets/               ← static resources
    ├── templates/
    ├── constants/
    ├── schemas/
    ├── checklists/
    ├── policies/
    └── verify/
```

Use `/canopy scaffold <skill-name>` to generate a blank skill, or see [Concepts — Skill anatomy](CONCEPTS.md#skill-anatomy) for the full annotated template.

### Frontmatter (agentskills.io spec)

Allowed at root: `name`, `description` (required); `license`, `compatibility`, `metadata`, `allowed-tools` (optional). Anything else (like `argument-hint`, `user-invocable`) goes inside `metadata`.

`## Tree` skills MUST declare `compatibility` (canopy-runtime requirement) and open the body with the safety preamble guard block before `$ARGUMENTS`. Both are inserted automatically by `/canopy create` and `/canopy scaffold`.

`compatibility` is **free-text, max 500 chars** (agentskills.io spec). Structured shapes (`{ requires: [...] }`) are non-spec — flagged by `/canopy validate`, migrated by `/canopy improve`. Do not include unquoted `: ` (colon-space) inside the value — YAML parses it as a mapping separator and `gh skill install` rejects the file.

### `## Agent` body shapes

| Shape | Use when | Looks like |
|-------|----------|-----------|
| (A) Minimal | 1 concern | `**explore** — <task>. Output contract: \`assets/schemas/explore-schema.json\`.` |
| (B) Sub-task bullets | ≥2 parallel concerns | Task line + bullets, each = one concern + one `assets/constants/<file>.md` |
| (C) Op reference | Procedure has ordering / data flow / reuse | `**explore** — execute NAMED_OP. Output contract: …` |

**Must not contain:** inline mappings/enumerations, inline quoted examples, schema-field lists (`Return: X, Y, Z`).

---

## Notation

| Symbol | Meaning |
|--------|---------|
| `<<` | Input — condition, source file, or user options |
| `>>` | Output — captured into context or displayed |
| `\|` | Separator — between options, inputs, or output fields |

---

## Framework primitives

Resolved from `skills/canopy-runtime/references/framework-ops.md` (bundled with the `canopy-runtime` skill). Never redefine in skill or project ops.

| Primitive | Signature | Notes |
|-----------|-----------|-------|
| `IF` | `<< condition` | Execute children if true; chain with `ELSE_IF` / `ELSE` |
| `ELSE_IF` | `<< condition` | Continue chain; evaluated only if all prior branches false |
| `ELSE` | — | Close chain; executed if all prior branches false |
| `SWITCH` | `<< expression` | Evaluate once; execute first matching `CASE`; use instead of long `ELSE_IF` chains on one value |
| `CASE` | `<< value` | Branch within `SWITCH`; fires when expression equals value |
| `DEFAULT` | — | Close `SWITCH`; fires if no `CASE` matched |
| `FOR_EACH` | `<< item in collection` | Execute body once per element; empty collection skips body |
| `BREAK` | — | Inside `FOR_EACH`: exit loop. Outside loop: exit current op |
| `END` | `[message]` | Halt entire skill; display message if provided |
| `ASK` | `<< question \| opt1 \| opt2` | Prompt user; halt until response |
| `SHOW_PLAN` | `>> field1 \| field2` | Present plan before any changes |
| `VERIFY_EXPECTED` | `<< assets/verify/verify-expected.md` | Check state against expected-state checklist (or `verify/verify-expected.md` for legacy-layout skills) |

**Examples:**

```
IF << condition          SWITCH << context.type      FOR_EACH << f in files
├── then-branch          ├── CASE << "create"        ├── validate f
ELSE_IF << other         │   └── CREATE_THING        ├── IF << f has errors
├── branch2              ├── CASE << "delete"        │   └── BREAK
ELSE                     │   └── DELETE_THING        └── write f
└── else-branch          └── DEFAULT
                             └── ASK << ...
```

---

## Op lookup order

1. `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` — skill-local. Backward-compatible fallback: `<skill>/ops.md` at root for legacy-layout skills.
2. Consumer-defined cross-skill ops (optional; package as your own skill — declared via `compatibility` on dependents)
3. `skills/canopy-runtime/references/framework-ops.md` — framework primitives

---

## Defining ops

```markdown
## FETCH_DEFAULTS                          ← simple op: prose

Fetch the chart's upstream default values from the internet.

---

## EDIT_TAG << image_defined_in | target_tag    ← branching op: tree notation

* EDIT_TAG << image_defined_in | target_tag
  * IF << image_defined_in = chart-defaults-only
    * CREATE_ENV_OVERRIDE
  * ELSE
    * edit tag in-place at the path from image_defined_in
```

Op names must be `ALL_CAPS`. Ops may call other ops.

---

## Category resource directories (standard layout)

| Path | What |
|------|------|
| `scripts/` | Executable code (`.ps1`, `.sh`) — invoked via named sections (`# === Section Name ===`) |
| `references/ops.md` or `references/ops/<name>.md` | Skill-local op definitions |
| `references/<other>.md` | Supporting documentation loaded on demand |
| `assets/templates/` | Fillable output documents with `<token>` placeholders |
| `assets/constants/` | Read-only lookup tables |
| `assets/schemas/` | Data shape definitions |
| `assets/checklists/` | Evaluation criteria (`- [ ] ...`) |
| `assets/policies/` | Behavioural constraints |
| `assets/verify/` | Expected-state checklists for `VERIFY_EXPECTED` |

Structured content lives in these subdirectories, never inline in the tree.
Reference at point of use — never front-load: `Read \`assets/policies/deploy-rules.md\` for deployment constraints.`

Legacy flat layout (category dirs at the skill root: `schemas/`, `templates/`, `commands/`, etc.) is still fully supported. Full directory reference: [Reference — Category Resource Subdirectories](reference/FRAMEWORK_SPEC.md#category-resource-subdirectories)

---

## Canopy agent operations

Invoke with `/canopy <request>` or natural language. Every operation shows a plan before making changes.

| Operation | Say… | Effect |
|-----------|------|--------|
| `CREATE` | "create a skill that…" | New skill from scratch |
| `SCAFFOLD` | "scaffold a blank skill called…" | Empty `SKILL.md` + `references/ops.md` stubs in standard layout |
| `MODIFY` | "add X to the Y skill" | Edit existing skill (preserves layout) |
| `VALIDATE` | "validate the X skill" | Report errors / warnings / optimizations (incl. agentskills.io compliance gaps) |
| `IMPROVE` | "improve the X skill" | Apply optimizations and style fixes; optionally migrate legacy flat layout to standard |
| `CONVERT_TO_CANOPY` | "convert X to Canopy format" | Rewrite prose skill as tree |
| `CONVERT_TO_REGULAR` | "convert X back to plain markdown" | Unwrap tree to prose; strip `compatibility` and safety preamble |
| `REFACTOR_SKILLS` | "refactor all skills" | Deduplicate ops/resources into a named installable shared skill (with `compatibility` declarations on dependents) |
| `ADVISE` | "advise on…" | Guidance without changes |
| `ACTIVATE` | "activate" | Force re-write of the canopy-runtime marker block. **Mostly redundant since v0.18.0** — canopy-runtime's `## Activation` section self-writes on first agent load (agent-mediated, not install-tool-mediated). Use only to force a re-write after a release that changed the marker block content. |
| `HELP` | "help" | List capabilities |

**Debug:** `/canopy-debug <skill> [args]` — live phase banners and per-node tracing. See [Reference — Debug Mode](reference/FRAMEWORK_SPEC.md#debug-mode).

---

## SKILL.md must NOT contain

Tables · JSON/YAML blocks · scripts · inline templates or examples → extract to category subdirectories.

Hardcoded `.agents/`, `.claude/`, or `.github/` paths → use relative category references only (skills are platform-agnostic; canopy-runtime resolves `<skills-root>` at runtime to one of the three roots).

Skill file must be exactly `SKILL.md` (uppercase) — case-sensitive filesystems require it.
