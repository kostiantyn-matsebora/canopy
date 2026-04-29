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

Every skill containing a `## Tree` section must declare its canopy-runtime requirement via `compatibility`:

```yaml
compatibility: Requires canopy-runtime for Claude Code (`gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`) or GitHub Copilot (`--agent github-copilot`). Execution on other platforms is not supported.
```

This is the pre-execution gate readable by agents that inspect frontmatter. `/canopy create`, `/canopy scaffold`, `/canopy convert-to-canopy`, and `/canopy modify` insert it automatically when absent.

## Safety preamble (required for canopy-flavored skills)

Every skill with `## Tree` must open its body with a runtime-required guard block, placed before `$ARGUMENTS`:

```markdown
> **Runtime required:** This skill uses Canopy tree notation and requires the
> canopy-runtime execution engine. If canopy-runtime is not active in your
> current context, **stop immediately** — do not attempt to execute this skill.
> Inform the user: "canopy-runtime must be installed and activated first.
> Run: `gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`"
```

canopy-runtime processes the preamble normally during initialization. Agents without canopy-runtime read this as the first instruction in the skill body and stop, preventing silent wrong execution. `/canopy create`, `/canopy scaffold`, `/canopy convert-to-canopy`, and `/canopy modify` insert it automatically when absent.

## Writing style

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

Lookup order: `<skill>/references/ops.md` (or `references/ops/<name>.md`) first, then any consumer-defined cross-skill ops, then `framework-ops.md` from the `canopy-runtime` skill (physical path: `../canopy-runtime/references/framework-ops.md`, loaded up-front by the canopy tree). Backward-compatible fallback: legacy skills with `ops.md` at root continue to resolve correctly.

- Skill-local ops → `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`
- Cross-skill project ops → consumer's own packaging (e.g. a dedicated `project-ops` skill they author); no default location
- Framework primitives → `../canopy-runtime/references/framework-ops.md` (ships with the `canopy-runtime` skill)

Named op notation: `OP_NAME << inputs >> outputs`

Conditional branches, multi-step procedures, and decision trees specific to one skill belong in `<skill>/references/ops.md` (or `<skill>/references/ops/<name>.md` for complex skills with multi-file op libraries). Op definitions use tree notation where branching exists; prose for simple linear ops.

## Cross-skill extraction (REFACTOR_SKILLS)

When `REFACTOR_SKILLS` identifies shared logic across multiple skills, the extracted result MUST be a complete, named, installable skill — not a bare shared file referenced by sibling skills.

- Create a new skill directory with its own `SKILL.md` (e.g. `shared-utils/SKILL.md`)
- Each dependent skill declares the new skill as a requirement via its `compatibility` field
- The new skill is distributable via `gh skill install` independently

Bare shared files referenced from sibling skills break agentskills.io skill autonomy: a skill must be independently installable. A skill referencing `../other-skill/scripts/x.sh` is not — the `..` path disappears when only the dependent is installed.

## Subagent contract

If a skill launches a subagent:
- Schema must exist as `assets/schemas/explore-schema.json` (or `schemas/explore-schema.json` for legacy-layout skills).
- "Do not inline-read" and "return JSON only matching schema" are implicit from `../canopy-runtime/references/skill-resources.md` — do not restate.
- No freeform prose output — every field the skill uses must be declared in the schema.
- First tree node must be `EXPLORE >> context` when `## Agent` declares `**explore**`.

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

Platform-specific execution (native subagent on Claude Code, inline fallback on Copilot) is defined by the runtime spec — see `../canopy-runtime/references/runtime-claude.md` and `../canopy-runtime/references/runtime-copilot.md`.

## Debug meta-skill

The `debug` skill wraps any target skill via `EXECUTE_WITH_TRACE`. It reads the target skill's tree and executes it while emitting phase banners and node-trace output.

- Never insert debug hooks, `IF << debug_mode` branches, or `TRACE_*` op calls into target skills — debug mode must remain a wrapper, never an intrusion.
- The ops `EMIT_PHASE_BANNER`, `EXECUTE_WITH_TRACE`, `TRACE_NODE`, and `TRACE_EXECUTE_NODES` are skill-local to `canopy-debug/references/ops.md` (or legacy `canopy-debug/ops.md`) — do not flag them as unknown ops when validating the `canopy-debug` skill.
- During VALIDATE: if a skill contains `IF << debug_mode` or any `TRACE_*` call, flag it as a **Warning**.

## Skill repo context

Authoring ops detect repo context to choose the target skill location:

- Distribution repo (has `skills/` at repo root, often with `.claude-plugin/`) → write to `skills/<name>/`
- Consumer project — write to one of:
  - `.claude/skills/<name>/` if Claude Code target
  - `.github/skills/<name>/` if Copilot target
  - `.agents/skills/<name>/` for Cross-client (single install serves both Claude Code and Copilot)
- Both / neither → ASK the user

`/canopy create` and `/canopy scaffold` use the `repo_context` field from the dispatch schema to make this choice automatically.
