---
title: Concepts
nav_order: 3
description: "How Canopy thinks about skills — the tree, ops, subagents, the execution model, and the runtime/authoring split."
permalink: /concepts/
---

# Concepts

This page explains the model behind Canopy: what a skill is structurally, why it's shaped that way, and what happens when one runs. You don't need to read it to use the `canopy` agent — `/canopy create`, `/canopy scaffold`, and `/canopy improve` will produce spec-compliant skills without you knowing any of this. But if you want to author by hand, debug execution, or extend the framework, the concepts below are the ones that matter.

For the formal grammar and field-level reference, see [Framework Spec](FRAMEWORK.html). For one-page lookup, see [Cheatsheet](CHEATSHEET.html).

---

## The tree as source of truth

Most "AI skill" formats are prose: a paragraph telling the agent what to do, in what order, with what guardrails. Prose is interpreted — by a model, every time, slightly differently. Two runs of the same skill can take different paths because the model parsed the same paragraph two different ways.

Canopy replaces the paragraph with a **tree**: a sequence of named operations, with explicit branching. The tree is the source of truth. The runtime walks it top-to-bottom; the model only fills in *what* each leaf does, never *which* leaf to pick next.

```
release
├── EXPLORE >> current_version | version_files
├── SHOW_PLAN >> new_version | files | changelog
├── ASK << Proceed? | Yes | No
├── IF << Yes
│   └── BUMP_FILES << version_files | new_version
└── ELSE
    └── natural language: Cancelled by user.
```

Every node is either an **op call** (`ALL_CAPS` name) or natural-language prose. Op calls are deterministic — the runtime resolves the name, runs the op's body, and binds outputs to context. Natural-language nodes are one-shot: the model executes the prose with whatever context is in scope, then moves to the next sibling.

`<<` is input, `>>` is output, `|` separates options or fields. Two equivalent surface syntaxes are accepted — markdown lists (nested `*`) or box-drawing (the fenced tree characters above). Pick whichever reads more clearly for the skill.

---

## Skill anatomy

Every skill is a single `SKILL.md` file (uppercase, exact spelling — the agentskills.io spec is case-sensitive). The file has frontmatter, a safety preamble for canopy-flavored skills, then named sections in this order:

```markdown
---
name: skill-name
description: One-line description shown in the skill picker.
compatibility: Requires the canopy-runtime skill (published at github.com/kostiantyn-matsebora/claude-canopy). Install with any agentskills.io-compatible tool — e.g. `gh skill install`, `git clone`, the repo's `install.sh`/`install.ps1`, or the Claude Code plugin marketplace. Supports Claude Code and GitHub Copilot.
metadata:
  argument-hint: "<required-arg> [optional-arg]"
---

> **Runtime required.** This skill uses Canopy tree notation; canopy-runtime must be active.
> [...safety preamble guard block...]

Preamble: $ARGUMENTS — parse and set context variables here.

---

## Agent          ← optional; declares an explore subagent
## Tree           ← execution pipeline (required)
## Rules          ← invariants and safety constraints
## Response:      ← output format declaration
```

**`compatibility`** is required for every `## Tree` skill — it tells an agent that's never seen Canopy before how to install the runtime. It's free-text (≤500 chars per the agentskills.io spec), names canopy-runtime + a source repo, and lists install tools as alternatives. Don't structure it as `{ requires: [...] }` — that's non-spec and `gh skill install` rejects it.

**The safety preamble** halts execution on agents without canopy-runtime active. `/canopy create` and `/canopy scaffold` insert it automatically.

**`metadata`** is the spec-compliant home for non-spec frontmatter fields like `argument-hint` and `user-invocable`. They go inside `metadata:`, not at the frontmatter root.

For full field tables, frontmatter validation rules, and the safety-preamble exact text, see [Framework Spec](FRAMEWORK.html).

### `## Tree`

The execution pipeline. Nodes run top-to-bottom; `IF`/`ELSE_IF`/`ELSE`, `SWITCH`/`CASE`/`DEFAULT`, and `FOR_EACH` give branching. Required for canopy-flavored skills.

### `## Rules`

Skill-wide invariants — short bullet list. These are guardrails the runtime keeps in scope for the entire execution, not per-op behavior. Don't repeat op-level checks here.

### `## Response:`

Declares the output shape as pipe-separated field names — e.g. `## Response: version | files updated`. The model fills the named fields when the tree finishes.

---

## Subagents — the `## Agent` block

When a skill needs to gather context before deciding what to do, it declares a subagent in `## Agent`. The subagent runs in its own context window — file reads, deep analysis, and large prose summaries happen *there*, and only a schema-shaped JSON summary returns to the parent. This keeps the parent's context window small and predictable.

The subagent is invoked by `EXPLORE >> context` as the first tree node. Its output contract is `assets/schemas/explore-schema.json`.

There are three canonical shapes — pick the one matching subagent complexity.

**(A) Minimal** — one concern:

```markdown
## Agent

**explore** — reads the files for `<service-name>` under `services/`,
including configs, templates, and existing deployment manifests.
```

**(B) Sub-task bullets** — ≥2 parallel concerns (no ordering between them). Each bullet = one concern + one `assets/constants/<file>.md` reference:

```markdown
## Agent

**explore** — resolve operation dispatch context. Output contract: `assets/schemas/dispatch-schema.json`.

Sub-tasks:
- Classify intent from `$ARGUMENTS` — see `assets/constants/operation-detection.md`
- Detect execution platform — see `assets/constants/platform-detection.md`
- Resolve explicit target platform — see `assets/constants/target-platform-triggers.md`
```

**(C) Op reference** — procedure has ordering, branching, or data flow between steps:

```markdown
## Agent

**explore** — execute `FETCH_DISPATCH_CONTEXT`. Output contract: `assets/schemas/dispatch-schema.json`.
```

The op lives in `references/ops.md` (or `references/ops/<name>.md` for complex skills) as a normal tree-form op. The runtime resolves the name and injects the op body as the subagent's task.

**Multi-concern rule:** when the subagent performs ≥2 concerns, shape (B) or (C) is required. Concerns joined by commas, semicolons, ` — `, or sentences in a single paragraph are not allowed — same rule as multi-clause tree-node steps. Each concern gets its own bullet or its own op step.

**The `## Agent` body must not contain** inline mappings, enumerations, quoted examples, or schema-field lists (`Return: X, Y, Z` — the schema is authoritative). Structured content goes in category subdirs and is referenced by `Read \`<path>\``.

---

## Ops — what they are and where they live

An **op** is a named, reusable step. Anywhere the tree has an `ALL_CAPS` identifier, that's an op call. The runtime resolves the name and executes the op's body.

**Simple op** — prose body for linear behavior:

```markdown
## FETCH_DEFAULTS

Fetch the chart's upstream default values from the internet.
```

**Branching op** — tree-form body for control flow inside the op itself:

```markdown
## EDIT_TAG << image_defined_in | target_tag

* EDIT_TAG << image_defined_in | target_tag
  * IF << image_defined_in = chart-defaults-only
    * CREATE_ENV_OVERRIDE
  * ELSE — edit tag in-place at the path from image_defined_in
```

The op signature line declares inputs (`<<`) and outputs (`>>`). Skill-local ops live in `references/ops.md` (one file, all ops) or `references/ops/<name>.md` (one file per op — preferred for complex skills with >5 ops).

### Op lookup order

When the runtime sees an `ALL_CAPS` identifier in a tree node, it resolves the name in this order:

1. **Skill-local** — `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`
2. **Consumer-defined cross-skill ops** (optional) — declared via `compatibility`, packaged as a separate skill
3. **Framework primitives** — `IF`, `ELSE_IF`, `ELSE`, `SWITCH`, `CASE`, `DEFAULT`, `FOR_EACH`, `BREAK`, `END`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`. Defined in `canopy-runtime/references/framework-ops.md` and never overridden.

For the full primitives table with signatures and examples, see [Framework Spec — Op Registries](FRAMEWORK.html#op-registries).

---

## Category resources

Structured content — JSON, tables, scripts, schemas, templates — does **not** belong inline in `SKILL.md`. `SKILL.md` is orchestration only. Structured content lives in subdirectories alongside `SKILL.md` and is loaded at point-of-use via `Read \`<path>\`` references.

| Directory | Contains |
|---|---|
| `scripts/` | Executable code (`.ps1`, `.sh`) |
| `references/ops.md` or `references/ops/<name>.md` | Skill-local op definitions |
| `references/<other>.md` | Supporting docs loaded on demand |
| `assets/templates/` | Fillable output documents with `<token>` placeholders |
| `assets/constants/` | Read-only lookup data (mapping tables, enum-like value lists) |
| `assets/schemas/` | Structure definitions (subagent contracts, data shapes) |
| `assets/checklists/` | Evaluation criteria lists (`- [ ] ...`) |
| `assets/policies/` | Behavioural constraints |
| `assets/verify/` | Post-execution expected-state checklists for `VERIFY_EXPECTED` |

**One concern per file.** Don't bundle unrelated content into a single resource file — the file is the unit of reuse, and a multi-concern file forces every consumer to load everything.

**`SKILL.md` must NOT contain:** tables, JSON or YAML blocks, scripts, inline templates, or inline examples. If you find yourself writing one of those inline, extract it to the matching category subdir.

For full per-category semantics and read-time behavior, see [Framework Spec — Category Resource Subdirectories](FRAMEWORK.html#category-resource-subdirectories).

---

## Execution model — under the hood

Here's what happens when the runtime executes a canopy-flavored skill:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│  my-skill/SKILL.md                                                         │
│                                                                            │
│  Stage 1: Initialize context                                               │
│  ┌─ Frontmatter + Preamble ───────────────────────────────────────────┐    │
│  │  name, description, compatibility, metadata.argument-hint          │    │
│  │  + safety preamble guard block                                     │    │
│  │  parse $ARGUMENTS, set context variables                           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                            │                                               │
│                            ▼                                               │
│  Stage 2: Detect platform + load runtime                                   │
│  ┌─ canopy skill (## Tree, first steps) ───────────────────────┐    │
│  │  detect platform: .claude/ -> Claude Code | .github/ -> Copilot   │    │
│  │  load references/runtime-claude.md or references/runtime-copilot  │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                            │                                               │
│                            ▼                                               │
│  Stage 3: Explore (optional)                                               │
│  ┌─ ## Agent: explore ────────────────────────────────────────────────┐    │
│  │  Claude Code: run native explore subagent                          │    │
│  │  Copilot:     inline sequential file reading (fallback)            │    │
│  │  capture assets/schemas/explore-schema.json output into context    │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                            │                                               │
│                            ▼                                               │
│  Stage 4: Plan and confirmation gate                                       │
│  ┌─ ## Tree entry steps ──────────────────────────────────────────────┐    │
│  │  SHOW_PLAN >> fields                                               │    │
│  │  ASK << Proceed? | Yes | No                                        │    │
│  │  No -> stop without changes                                        │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                            │ Yes                                           │
│                            ▼                                               │
│  Stage 5: Execute workflow actions (iterative loop)                        │
│  ┌─ ## Tree action steps ─────────────────────────────────────────────┐    │
│  │  run op calls + natural-language nodes top-to-bottom               │    │
│  │  evaluate IF / ELSE_IF / ELSE branches                             │    │
│  │  repeat until no remaining actions                                 │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                            │                                               │
│                            ▼                                               │
│  Stage 6: Verify expected outcomes                                         │
│  ┌─ VERIFY_EXPECTED ──────────────────────────────────────────────────┐    │
│  │  compare resulting state against verify checklist                  │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│  ┌─ ## Rules (guardrails) ────────────────────────────────────────────┐    │
│  │  • Never overwrite without confirmation                            │    │
│  │  • Always show plan before changes                                 │    │
│  │  Enforced for the full duration of skill execution                 │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                            │                                               │
│                            ▼                                               │
│  Stage 7: Respond                                                          │
│  ┌─ ## Response ──────────────────────────────────────────────────────┐    │
│  │  Declares output format: Summary / Changes / Notes                 │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────────┘

Op lookup (ALL_CAPS node -> definition):                         Category resources (standard layout):
1. my-skill/references/ops.md or ops/<name>.md (skill-local)     scripts/                -> run named shell section
2. consumer-defined cross-skill ops          (optional)          assets/schemas/         -> subagent contracts
3. canopy-runtime/references/framework-ops.md (primitives)       assets/policies/        -> active rules / guardrails
   IF, ELSE, SWITCH, FOR_EACH, ASK, SHOW_PLAN, VERIFY...         assets/templates/       -> fill <token> -> write file
                                                                  assets/constants/       -> load named values
Backward-compatible: legacy <skill>/ops.md at root still works.   assets/checklists/      -> evaluation criteria
                                                                  assets/verify/          -> post-run checklist
                                                                  references/<other>.md   -> docs loaded on demand

Runtime specs (loaded at Stage 2):
  canopy-runtime/references/runtime-claude.md   -> .claude/ paths, native subagents
  canopy-runtime/references/runtime-copilot.md  -> .github/ paths, inline subagent fallback
```

The seven stages are not magic — they're just what the tree's first nodes typically look like for a well-formed skill. A trivial skill with no `## Agent`, no `SHOW_PLAN`, no `VERIFY_EXPECTED` skips Stages 3, 4, and 6. The runtime doesn't enforce stages; it walks the tree.

---

## The runtime / authoring split

Canopy ships as **three** separate skills, not one:

| Skill | What it does | When you need it |
|---|---|---|
| `canopy-runtime` | Execution engine — interprets canopy-flavored skills, owns the primitive specs, platform detection, op-lookup chain. | Always. Without it, a `## Tree` skill is just text. |
| `canopy` | Authoring agent — `/canopy create / modify / scaffold / validate / improve / advise / refactor / convert`. Depends on `canopy-runtime` for the framework spec. | Only when authoring. Skip it if you only run skills others wrote. |
| `canopy-debug` | Trace wrapper — runs any canopy-flavored skill with phase banners + per-node tracing. | Only when debugging. Optional. |

The split exists so a consumer who just wants to *execute* canopy skills (someone else's, ones they wrote earlier) can install `canopy-runtime` alone — no authoring agent in their slash menu, no extra context loaded ambiently. Authoring is the heavier role; it gets its own skill that depends on the runtime.

For install paths and how to pick which combination to install, see [Getting Started — Authoring vs. execution](GETTING_STARTED.md#authoring-vs-execution).

---

## agentskills.io alignment

Canopy is a **meta-framework on top of [agentskills.io](https://agentskills.io)**. It doesn't replace the spec; it adds a tree-shaped skill format on top of the existing one.

**What's spec-compliant** (any agentskills.io-aware tool can install + read):

- `SKILL.md` at the skill root (uppercase, exact spelling)
- Frontmatter with `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`
- Standard layout: `scripts/`, `references/`, `assets/{templates,constants,schemas,checklists,policies,verify}/`
- The `compatibility` field as free-text (≤500 chars), naming dependencies + install tools

**What's canopy-specific** (loaded ambiently via `canopy-runtime`):

- The `## Tree` section and its tree-notation grammar
- The `## Agent` declaration and EXPLORE invocation
- The op-lookup chain (skill-local → project → framework)
- Framework primitives (`IF`, `SWITCH`, `FOR_EACH`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`, …)

This split matters because an agent that doesn't have canopy-runtime active will still be able to *parse* a canopy skill (the frontmatter is spec-compliant) and the safety preamble will halt execution before the agent tries to interpret `## Tree` — preventing free-form prose-style misexecution.

---

## Debugging

Use the `canopy-debug` skill to trace any canopy-flavored skill's execution in real time:

```
/canopy-debug <skill-name> [arguments]
```

No changes to the target skill are required. `canopy-debug` wraps the target with phase banners and per-node tracing, so each tree node's execution is visible.

For the full debug-mode reference (output protocol, trace ops, verify steps), see [Framework Spec — Debug Mode](FRAMEWORK.html#debug-mode).
