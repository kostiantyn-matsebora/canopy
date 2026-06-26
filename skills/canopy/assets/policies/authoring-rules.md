# Authoring Rules

## Skill structure

Skill file MUST be exactly `SKILL.md` (uppercase). Lowercase `skill.md` is invalid on case-sensitive filesystems and breaks `gh skill install` discovery.

`SKILL.md` must contain:
- Frontmatter — see Frontmatter rules below
- Safety preamble (canopy-flavored skills only — see Safety preamble below)
- `## Agent`, `## Tree`, `## Rules`, `## Response:` sections
- Op calls and natural language in the tree
- `Read <category-path>/<file>` references at point of use

`SKILL.md` must NOT contain:
- Tables
- JSON, YAML, or any structured data blocks
- Scripts, shell commands, or code fences with executable content
- Inline examples or templates
- Phase-by-phase prose when a `## Tree` is possible
- Hardcoded platform-specific paths (`.claude/`, `.github/`, or `.agents/`) in tree nodes or `Read` references — all category file references must be relative to the skill directory (e.g. `assets/policies/rules.md`, not `.claude/skills/my-skill/assets/policies/rules.md`)
- Complex inline command invocations (multi-flag or multi-argument shell commands) — extract to a `scripts/` script and invoke it from the tree

`## Tree`, `## Rules`, and `## Response:` sections are all required.
All structured content must be extracted to the appropriate category subdirectory file.
`references/ops.md` (or `references/ops/<name>.md`) is only written when ops are not already covered by shared.
Category files are only written when content is not already in shared.

## Frontmatter rules (agentskills.io spec compliance)

Per the [agentskills.io specification](https://agentskills.io/specification), only these fields are allowed at frontmatter root:
- `name` (required)
- `description` (required)
- `license` (optional)
- `compatibility` (optional, but **required** for `## Tree` skills)
- `metadata` (optional, free-form key-value)
- `allowed-tools` (optional, experimental)

Any other field — including `argument-hint`, `user-invocable`, or custom keys — must go inside `metadata`. For example:

```yaml
---
name: my-skill
description: ...
compatibility: ...
metadata:
  argument-hint: "<required-arg> [optional]"
  user-invocable: "false"
  version: "1.0.0"
---
```

`/canopy validate` and `/canopy improve` flag root-level non-spec fields and migrate them into `metadata`.

## Compatibility field (required for canopy-flavored skills)

Per the [agentskills.io spec](https://agentskills.io/specification), `compatibility` is **free-text, max 500 characters** — a declarative environment-requirements blurb for human and agent readers. It is NOT a structured object: shapes like `compatibility: { requires: [...] }` are non-spec and MUST be migrated to free text.

Every skill containing a `## Tree` section must declare its canopy-runtime requirement via `compatibility` in this canonical form:

```yaml
compatibility: Requires the canopy-runtime skill (published at github.com/kostiantyn-matsebora/canopy). Install with any agentskills.io-compatible tool — e.g. `gh skill install`, `git clone`, the repo's `install.sh`/`install.ps1`, or the Claude Code plugin marketplace. Supports Claude Code and GitHub Copilot.
```

The text is **declarative** (names *what* and *where*), not **prescriptive** (does not pin one install tool). Listing tools as `e.g.` examples lets the agent pick the install method its environment supports — `gh skill install` if available (gh ≥ 2.90), `git clone` otherwise, plugin marketplace inside Claude Code, etc. The canopy framework deliberately does not prescribe an install tool because the agentskills.io spec doesn't either.

`/canopy create`, `/canopy scaffold`, `/canopy convert-to-canopy`, and `/canopy modify` insert this canonical form automatically when absent. `/canopy improve` migrates legacy structured forms.

## Safety preamble (required for canopy-flavored skills)

Every skill with `## Tree` must open its body with a runtime-required guard block, placed before `$ARGUMENTS`:

```markdown
> **Runtime required.** This skill uses Canopy tree notation; canopy-runtime must be active.
>
> **Detect canopy-runtime** — present if either:
> - `canopy-runtime/SKILL.md` exists under `.claude/skills/`, `.github/skills/`, or `.agents/skills/`, OR
> - a canopy-runtime marker block exists in `CLAUDE.md` or `.github/copilot-instructions.md`.
>
> **If neither is present** — install canopy-runtime first (see the `compatibility` field for the source and install options), then re-invoke this skill.
>
> Do not interpret the `## Tree` without canopy-runtime active.
```

canopy-runtime processes the preamble normally during initialization. Agents without canopy-runtime read this as the first instruction in the skill body and stop, preventing silent wrong execution. `/canopy create`, `/canopy scaffold`, `/canopy convert-to-canopy`, and `/canopy modify` insert it automatically when absent.

## Writing style

**Structured, not stream-of-consciousness.** Applies to every markdown surface inside a skill — `SKILL.md` (preamble, tree, rules, response), `references/ops.md` / `references/ops/*.md`, `references/*.md` supporting docs, `assets/policies/*.md`, `assets/constants/*.md`, `assets/checklists/*.md`, `assets/verify/*.md`. A reader should grok the shape in one pass.

- **Lead with the claim, then break out the details.** No multi-clause prose paragraphs that bury the point.
- **Bullets, not run-on sentences.** Anything joined by `;`, ` — `, "and also", "additionally" is a candidate for splitting.
- **Label the bullets.** Short bold labels at the front of each bullet so the eye finds the relevant one fast.
- **Tables for matrices.** When information has two axes, use a table or labeled bulleted list — never inline a 3-way comparison in prose.
- **Cross-reference instead of restating.** Link/point to the canonical location; do not duplicate.
- **Consistent verb mood.** Imperative for instructions, declarative for spec. Don't mix within a single block.

Replace narrative paragraphs with numbered or bulleted steps. Each step: one action, one outcome, optionally one `Read <category-path>/<file>` reference. No multi-sentence explanations inside a step.

Prefer `## Tree` over `## Phase N` sections. Keep phase headings only when steps have complex inter-phase state that cannot be expressed as a flat pipeline. Keep `## Rules` and `## Response:` sections as short bullet lists. Remove subsection headings that are just labels for what follows extracted content.

When `## Steps` is a sequential pipeline with only `IF` branches, replace with `## Tree`.

Steps with multiple clauses joined by `;` or ` — ` must be split into a numbered step header with indented sub-bullets. Each sub-bullet: one action or one condition. No inline chaining.

Standard reference line: `Read \`<category-path>/<file>\` for <brief description>.` Used at the point in the steps where the content is needed — not all at the top. Load only what's needed for the current branch or action.

## Tree nodes

Tree nodes must be short and scannable. A node that cannot be read at a glance must be extracted to a named op in `references/ops.md` (or `references/ops/<name>.md`). The tree should read like a table of contents: short op calls and brief natural-language steps, not verbose inline descriptions.

Tree nodes must not contain inline static or parameterised content:
- Fixed content (no placeholders) → `assets/constants/`
- Parameterised content (contains `<token>` slots) → `assets/templates/`

This applies to all node types — `Report:`, natural language steps, op descriptions, or any other node that embeds literal content inline.

Mechanical behavior (e.g. "patch if path exists, put if new") belongs as a section comment in the resource file itself, not repeated in `SKILL.md` steps. `SKILL.md` states only: which file to read, arguments and captured output values, and exceptions to default behavior (these stay inline).

## Op naming

Replace multi-line blocks expressing a single recognizable operation with a named op.

Lookup order: `<skill>/references/ops.md` (or `references/ops/<name>.md`) first, then any consumer-defined cross-skill ops, then canopy-runtime's primitive slices (index at `../canopy-runtime/references/ops.md`, per-feature slices under `../canopy-runtime/references/ops/`, loaded by the canopy tree per the skill's `metadata.canopy-features` manifest). Backward-compatible fallback: legacy skills with `ops.md` at root continue to resolve correctly.

- Skill-local ops → `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`
- Cross-skill project ops → consumer's own packaging (e.g. a dedicated `project-ops` skill they author); no default location
- Framework primitives → canopy-runtime's primitive slices (index at `../canopy-runtime/references/ops.md`)

Named op notation: `OP_NAME << inputs >> outputs`

Conditional branches, multi-step procedures, and decision trees specific to one skill belong in `<skill>/references/ops.md` (or `<skill>/references/ops/<name>.md` for complex skills with multi-file op libraries). Op definitions use tree notation where branching exists; prose for simple linear ops.

## Cross-skill extraction (REFACTOR_SKILLS)

When `REFACTOR_SKILLS` identifies shared logic across multiple skills, the extracted result MUST be a complete, named, installable skill — not a bare shared file referenced by sibling skills.

- Create a new skill directory with its own `SKILL.md` (e.g. `shared-utils/SKILL.md`)
- Each dependent skill declares the new skill as a requirement via its `compatibility` field
- The new skill is distributable via `gh skill install` independently

Bare shared files referenced from sibling skills break agentskills.io skill autonomy: a skill must be independently installable. A skill referencing `../other-skill/scripts/x.sh` is not — the `..` path disappears when only the dependent is installed.

## Subagent contract

A canopy op runs **inline** by default (in the parent's context). Mark an op as a **subagent** to dispatch it out-of-context — separate context window, schema-anchored output, strict-input contract. The marker is per-op, not per-skill, so a single skill can mix inline and subagent ops freely.

### Op definition marker

Add a blockquote marker as the first content under the op's heading in `references/ops.md` or `references/ops/<name>.md`:

```markdown
## REVIEW_ASPECT << aspect | file_paths >> findings

> **Subagent.** Output contract: `assets/schemas/aspect-findings-schema.json`

REVIEW_ASPECT << aspect | file_paths
├── Read `assets/constants/review-aspects.md` → § matching `aspect`
├── FOR_EACH << path in file_paths
│   └── read the file at `path`
└── apply criteria; return findings shaped per the contract
```

The marker may carry input descriptions when inputs need explanation:

```markdown
> **Subagent.**
> **Inputs:**
> - `aspect` — enum: `"security"`, `"performance"`, `"style"`, `"correctness"`
> - `file_paths` — list of file paths (strings)
>
> **Output contract:** `assets/schemas/aspect-findings-schema.json`
```

For complex / structured inputs, reference a JSON Schema instead:

```markdown
> **Subagent.** Input contract: `assets/schemas/review-aspect-input.json`. Output contract: `assets/schemas/aspect-findings-schema.json`
```

### Call-site marker

Calls to a subagent-marked op use **bold around the op name** in tree notation:

```markdown
* PARALLEL
  * **REVIEW_ASPECT** << "security"    | context.file_paths >> security_findings
  * **REVIEW_ASPECT** << "performance" | context.file_paths >> perf_findings
```

Plain `OP_NAME << ... >> ...` is always inline. Bold `**OP_NAME** << ... >> ...` is always subagent dispatch. The two markers (op-def + call-site) MUST be consistent — a bold call to an unmarked op is a contract mismatch and vice versa.

### Strict-contract rule (subagent ops only)

A subagent op's body may use:
- Names declared in its `<<` signature
- Static skill assets via path (`assets/constants/...`, `assets/templates/...`, `assets/policies/...`)

A subagent op's body MUST NOT use:
- `context.<name>` not in the signature
- Bindings produced by prior tree nodes that weren't passed via `<<`
- Other ambient parent state

If the body legitimately needs ambient state, drop the marker — keep the op inline. Inline ops are exempt from the strict-contract rule.

### When to mark vs keep inline

- **Mark as subagent** when: the op does substantial reading/analysis that would bloat the parent's context; multiple instances run in parallel under `PARALLEL` (each isolated); the output schema is well-defined; the body honors strict `<<` inputs already
- **Keep inline** when: the op is small (template fill, single-line transform); the body legitimately reaches into ambient skill context; the cost of subagent startup outweighs context-isolation benefit

### Composition with `PARALLEL`

`PARALLEL` (S1) is structural. When its children are bold-marked op calls, each runs as a separate parallel subagent:

```markdown
* PARALLEL
  * **EXPLORE_FRONTEND** >> fe_ctx
  * **EXPLORE_BACKEND**  >> be_ctx
  * **EXPLORE_TESTS**    >> tests_ctx
* MERGE_CTX << fe_ctx | be_ctx | tests_ctx >> context
```

Children of `PARALLEL` may also be plain (inline) op calls or natural-language nodes. Mixing is allowed.

---

## Soft-compat: `## Agent` (singular) — legacy form

Skills written before S2 declare a singular explore subagent via the `## Agent` section, with `EXPLORE >> context` as the first tree node. This form continues to work — the runtime treats it as syntactic sugar for a single-element marked op named `EXPLORE`. New skills SHOULD use the marker form above; existing skills MAY migrate via `/canopy improve`.

If launching an explore subagent via `## Agent`:
- Schema must exist as `assets/schemas/explore-schema.json` (or `schemas/explore-schema.json` for legacy-layout skills)
- "Do not inline-read" and "return JSON only matching schema" are implicit from `../canopy-runtime/references/skill-resources.md` → `## Subagent dispatch` — do not restate
- No freeform prose output — every field the skill uses must be declared in the schema
- First tree node must be `EXPLORE >> context`

### `## Agent` body shape

Three canonical shapes — pick the one matching subagent complexity:

**(A) Minimal** — one concern, one task summary line:

```markdown
**explore** — reads the files for <service>. Output contract: `assets/schemas/explore-schema.json`.
```

**(B) Sub-task bullets** — ≥2 parallel concerns (no ordering between them), each with its own lookup file:

```markdown
**explore** — resolve operation dispatch context. Output contract: `assets/schemas/dispatch-schema.json`.

Sub-tasks:
- Classify intent from `$ARGUMENTS` — see `assets/constants/operation-detection.md`
- Detect execution platform — see `assets/constants/platform-detection.md`
- Resolve explicit target platform — see `assets/constants/target-platform-triggers.md`
```

One concern per bullet. One `assets/constants/<file>.md` reference per bullet. Prose *within* a bullet is allowed but must stay short and scannable.

**(C) Op reference** — procedure has ordering, branching, or data flow between steps; or is reusable across skills:

```markdown
**explore** — execute `FETCH_DISPATCH_CONTEXT`. Output contract: `assets/schemas/dispatch-schema.json`.
```

The op lives in `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` as a normal tree-form op. Runtime resolves the name and injects the op body as the subagent's task.

### `## Agent` body MUST NOT contain

- Inline mappings, tables, or enumerations (e.g. `.claude/ → claude`, lists of version-bearing filenames) — extract to `assets/constants/`
- Inline quoted examples (e.g. `"create for copilot"`) — extract to `assets/constants/`
- Schema-field lists (e.g. `Return: field1, field2, ...`) — schema is authoritative; omit

### Multi-concern rule (MUST)

When the subagent performs ≥2 distinct concerns, the body MUST use shape (B) or (C). Concerns joined by commas, semicolons, ` — `, or sentences in a single paragraph are not allowed — this mirrors the existing tree-node rule that multi-clause steps must be split into sub-bullets. Single-concern subagents use shape (A).

Shape selection:
- 1 concern → (A)
- ≥2 parallel concerns with no ordering/data dependencies → (B)
- Procedure has ordering, branching, or data flow → (C)

Platform-specific execution (native subagent on Claude Code, fleet/custom-agent or sequential inline fallback on Copilot) is defined by the runtime spec — see `../canopy-runtime/references/runtime-claude.md` and `../canopy-runtime/references/runtime-copilot.md`.

### Parallel subagent invocation in tree nodes (legacy prose form)

Pre-S2, a tree node could invoke ≥2 subagents in parallel via prose:

> **Spawn three subagents in parallel:**
> - `explore-frontend` — read `.frontend/`; summary into `fe_ctx`
> - `explore-backend` — read `.backend/`; summary into `be_ctx`
> - `explore-tests` — read `tests/`; summary into `tests_ctx`

This still works. New skills should prefer the structural form: `PARALLEL` block with bold-marked op calls as children — see `## Subagent contract` above.

## Debug meta-skill

The `debug` skill wraps any target skill via `EXECUTE_WITH_TRACE`. It reads the target skill's tree and executes it while emitting phase banners and node-trace output.

- Never insert debug hooks, `IF << debug_mode` branches, or `TRACE_*` op calls into target skills — debug mode must remain a wrapper, never an intrusion.
- The ops `EMIT_PHASE_BANNER`, `EXECUTE_WITH_TRACE`, `TRACE_NODE`, and `TRACE_EXECUTE_NODES` are skill-local to `canopy-debug/references/ops.md` (or legacy `canopy-debug/ops.md`) — do not flag them as unknown ops when validating the `canopy-debug` skill.
- During VALIDATE: if a skill contains `IF << debug_mode` or any `TRACE_*` call, flag it as a **Warning**.

## Universal op contracts

Any op definition — inline or subagent — may declare **input** and **output** contracts via blockquote markers placed directly under its heading. Contracts are JSON Schema files under `<skill>/assets/schemas/`.

### Marker forms

**Inline op** — bare contract blockquote, no `**Subagent.**` lead:

```markdown
## RENDER_REPORT << findings | template_path >> report_text

> **Input contract:** `assets/schemas/render-report-input.json`
> **Output contract:** `assets/schemas/render-report-output.json`

(body…)
```

**Subagent op** — contracts ride alongside the dispatch flag (see § "Subagent contract"):

```markdown
> **Subagent.** Output contract: `assets/schemas/aspect-findings.json`. Input contract: `assets/schemas/review-aspect-input.json`
```

Either or both contracts may be declared. An op with no contract markers runs identically to today (back-compat) — contracts are opt-in per op.

### Schema location and shape

- **Location:** `<skill>/assets/schemas/<op-name>-{input,output}.json` is the convention. Cross-skill schemas may `$ref` into framework schemas; cross-skill `$ref` is currently single-skill-only.
- **Shape:** plain JSON Schema (draft-07 or draft-2020-12). Top-level `type: object` with `properties` mirroring the op's `<<` named inputs (input contract) or `>>` named outputs (output contract).
- **Defaults:** `/canopy improve` scaffolds permissive contracts (`additionalProperties: true`) — refine to taste.

### Why declare contracts

- **Static type-flow.** vscode walks the binding graph (`producer >> ctx.foo` → `consumer << ctx.foo`) and flags drift between producer output and consumer input at authoring time.
- **Runtime validation (opt-in).** With `metadata.canopy-contracts: strict`, the runtime validates each op's bound input against its input contract before firing, and validates output before binding into context. Halts on violation with a `[contract-violation]` error.
- **Documentation.** Hover in vscode surfaces the schema; the contract describes intent better than free-text.

### When to skip

- **One-shot template-fill ops** with trivial single-string inputs and outputs.
- **Ops whose body honors strict `<<` already** (subagent ops) but have no downstream consumer that benefits from typed flow.
- **Skills under v0.21.0 idioms** that are stable and not slated for refactor — contracts are an opt-in upgrade, not a breaking requirement.

### Strict-contract mode

```yaml
metadata:
  canopy-features: [...]
  canopy-contracts: strict
```

- **Default (omitted):** contracts are descriptive only — vscode static analysis applies; runtime does not enforce.
- **`strict`:** runtime validates every op's input/output against its declared contracts; emits `[contract-violation]` halt on mismatch. Ops without contracts are skipped (strict mode tightens, doesn't invent).

`/canopy improve` proposes adding `canopy-contracts: strict` once a skill has contracts on all non-trivial ops.

### Migration via `/canopy improve`

`/canopy improve` includes a **contract-scaffolding pass**: for each op without contracts, generate `assets/schemas/<op>-input.json` and `assets/schemas/<op>-output.json` from the op's `<<` / `>>` signature and bound variable names. The author then refines the scaffolds. Skills opt in via the `--scaffold-contracts` flag in the apply prompt.

## Skill repo context

Authoring ops detect repo context to choose the target skill location:

- Distribution repo (has `skills/` at repo root, often with `.claude-plugin/`) → write to `skills/<name>/`
- Consumer project — write to one of:
  - `.claude/skills/<name>/` if Claude Code target
  - `.github/skills/<name>/` if Copilot target
  - `.agents/skills/<name>/` for Cross-client (single install serves both Claude Code and Copilot)
- Both / neither → ASK the user

`/canopy create` and `/canopy scaffold` use the `repo_context` field from the dispatch schema to make this choice automatically.

### Publishing for `gh skill install` consumers

`gh skill install <owner>/<repo> <name>` reads from `<repo>/skills/<name>/` by default. Skills published only at `.claude/skills/<name>/` or `.github/skills/<name>/` are hidden directories — installable only with `gh skill install ... --allow-hidden-dirs`, which is not the canonical flow.

If you want others to install your skill via the canonical command (no flags), publish at `skills/<name>/` at repo root. A repo can host both — `skills/<name>/` for `gh skill install` consumers and `.claude/skills/<name>/` for in-tree Claude Code consumption — but the file content must stay in sync.
