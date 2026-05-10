---
title: Cheatsheet
nav_order: 2
description: "One-page reference: skill anatomy, primitives, op syntax, category dirs, agent operations, debug mode."
---

# Canopy Cheatsheet

Quick reference. Full spec: [Reference](reference/) · Concepts: [CONCEPTS.md](CONCEPTS.md)

---

## Skill anatomy

`frontmatter` (incl. `compatibility`, `metadata.canopy-features`) → safety preamble → `## Tree` → `## Rules` → `## Response:`

Subagents are declared per-op via `> **Subagent.**` markers + bold `**OP_NAME**` call sites in the tree (v0.20+). The pre-v0.20 `## Agent` singular section is still supported as soft-compat — see [legacy `## Agent`](#legacy-agent-body-shapes-soft-compat) below.

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

### Subagent dispatch (v0.20+, canonical)

| Where | Marker form |
|---|---|
| Op definition (in `references/ops.md` or `references/ops/<name>.md`) | `> **Subagent.** Output contract: \`assets/schemas/<op>-output.json\`` as the first content under the heading; optional `Input contract: \`<path>\`` |
| Call site (in `## Tree` or in another op body) | `**OP_NAME** << input >> output` (bold around the op name) |

Plain `OP_NAME << ... >> ...` is always inline. Bold `**OP_NAME** << ... >> ...` is always subagent dispatch. The two markers must agree — vscode flags drift.

**Strict-input contract for subagent ops:** body uses only `<<` named inputs and static skill assets. No ambient `context.<name>` reads. If the body legitimately needs ambient state, drop the marker and keep it inline.

**Composition:** bold call sites under `PARALLEL` give multi-typed parallel fan-out, each child running in its own context window.

### Legacy `## Agent` body shapes (soft-compat)

Pre-v0.20 single-subagent form. Still supported — the runtime treats `## Agent` + `EXPLORE >> context` as a single-element marked op named `EXPLORE`. New skills should use the marker dispatch above; the marker form is also the only way to declare more than one subagent.

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

Resolved from canopy-runtime's primitive slices (index at `skills/canopy-runtime/references/ops.md`; per-feature slices under `skills/canopy-runtime/references/ops/`). Never redefine in skill or project ops.

| Primitive | Signature | Slice | Notes |
|-----------|-----------|-------|-------|
| `IF` | `<< condition` | `core` | Execute children if true; chain with `ELSE_IF` / `ELSE` |
| `ELSE_IF` | `<< condition` | `core` | Continue chain; evaluated only if all prior branches false |
| `ELSE` | — | `core` | Close chain; executed if all prior branches false |
| `END` | `[message]` | `core` | Halt entire skill; display message if provided |
| `BREAK` | — | `core` | Inside `FOR_EACH`: exit loop. Outside loop: exit current op |
| `ASK` | `<< question \| opt1 \| opt2` | `interaction` | Prompt user; halt until response |
| `SHOW_PLAN` | `>> field1 \| field2` | `interaction` | Present plan before any changes |
| `SWITCH` | `<< expression` | `control-flow` | Evaluate once; execute first matching `CASE` |
| `CASE` | `<< value` | `control-flow` | Branch within `SWITCH`; fires when expression equals value |
| `DEFAULT` | — | `control-flow` | Close `SWITCH`; fires if no `CASE` matched |
| `FOR_EACH` | `<< item in collection` | `control-flow` | Execute body once per element; empty collection skips body |
| `PARALLEL` | — (children only) | `parallel` | Heterogeneous parallel-subagent fan-out; ≥2 children, no input/output |
| `EXPLORE` | `>> context` | `explore` | Legacy soft-compat with `## Agent` (use marker dispatch for new skills) |
| `VERIFY_EXPECTED` | `<< assets/verify/verify-expected.md` | `verify` | Check state against expected-state checklist (or `verify/verify-expected.md` for legacy-layout skills) |

The "Slice" column maps each primitive to the `metadata.canopy-features` value that loads it. The `core` slice is implicit-always-loaded (never list it). Subagent dispatch via `**OP_NAME**` and `> **Subagent.**` markers belongs to the `subagent` slice — no primitive of its own.

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
3. canopy-runtime's primitive slices (index at `skills/canopy-runtime/references/ops.md` → `references/ops/<slice>.md` per-feature)

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

## Op contracts (v0.22.0+)

Any op (inline or subagent) may declare typed JSON Schema input/output contracts via blockquote markers under its heading.

| Op kind | Marker form |
|---|---|
| Inline op | `> **Input contract:** \`assets/schemas/op-input.json\`` + `> **Output contract:** \`assets/schemas/op-output.json\`` |
| Subagent op | `> **Subagent.** Output contract: \`...\`. Input contract: \`...\`` |
| Schema-less op | (no marker — back-compat default) |

Contracts compose through bindings — when `producer >> ctx.foo` is followed by `consumer << ctx.foo`, vscode walks the binding graph and flags drift between producer's output schema and consumer's input schema as authoring-time diagnostics.

**Strict-contract mode** — opt in via `metadata.canopy-contracts: strict`. Runtime validates each contract-bearing op's input before firing and output before binding. Halts with `[contract-violation]` on drift. Default (omitted): contracts are descriptive only.

**Scaffolding** — `/canopy improve --scaffold-contracts` generates initial schemas from each op's `<<` / `>>` named-field signature. Permissive defaults (`additionalProperties: true`, every property `type: string`) — author refines.

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
