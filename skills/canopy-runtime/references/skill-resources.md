# Skill Resource Conventions

Reference documentation describing how Canopy resolves resource references inside skills. Shared between the runtime (for interpretation at execution time) and the canopy authoring agent (for VALIDATE/IMPROVE/SCAFFOLD/CONVERT_TO_CANOPY at authoring time).

This file covers **skill anatomy**: layout, category behavior, op lookup, tree format, safety preamble, and the per-skill `canopy-features` manifest. Primitive definitions live in [`ops.md`](ops.md) and the slices it points at (`ops/core.md`, `ops/interaction.md`, etc.). Subagent dispatch lives in [`ops/subagent.md`](ops/subagent.md).

---

## Skill layout

A canopy skill aligns with the agentskills.io standard. Only `SKILL.md` lives at the root; everything else is grouped under three standard top-level directories:

```
skill-name/
├── SKILL.md          # required — frontmatter + body
├── scripts/          # executable code (.ps1, .sh)
├── references/       # docs loaded on demand
│   ├── ops.md        # skill-local op definitions (simple skills)
│   └── ops/          # one-file-per-op definitions (complex skills)
└── assets/           # static resources
    ├── templates/    # fillable output documents with <token> placeholders
    ├── constants/    # read-only lookup data
    ├── schemas/      # structure definitions (subagent contracts, data shapes)
    ├── checklists/   # evaluation criteria (- [ ] ...)
    ├── policies/     # behavioural constraints
    └── verify/       # VERIFY_EXPECTED checklists
```

### Backward compatibility

Older skills may use a flat layout (`schemas/`, `templates/`, `commands/`, `constants/`, `checklists/`, `policies/`, `verify/`, `ops.md` all at the root). The runtime continues to honour `Read \`<dir>/<file>\`` instructions exactly as written, so old skills execute unchanged. New skills should adopt the standard layout above.

---

## Category behavior

When a skill step says `Read <category>/<file>`, the directory determines behavior. Categories are listed by their canonical (new-layout) location:

| Category | New-layout location | Old-layout fallback | File types | Behavior |
|----------|--------------------|--------------------|------------|----------|
| Executable code | `scripts/` | `commands/` | `.ps1`, `.sh` | Invoked by name via a named section (`# === Section Name ===`); output captured into context |
| Op definitions | `references/ops.md` or `references/ops/<name>.md` | `ops.md` or `ops/<name>.md` | `.md` | Skill-local op definitions; resolved before consumer cross-skill ops and framework primitives |
| References | `references/` | `references/` | `.md` | Supporting documentation loaded on demand (per the agentskills.io progressive-disclosure pattern) |
| Templates | `assets/templates/` | `templates/` | `.yaml`, `.md`, `.yaml.gotmpl` | Fillable output documents with `<token>` placeholders substituted from context and written to a target path |
| Constants | `assets/constants/` | `constants/` | `.md` | Read-only lookup data referenced by ops: mapping tables, enum-like value lists, fixed configuration values |
| Schemas | `assets/schemas/` | `schemas/` | `.json`, `.md` | Structure definitions: subagent output contracts, input/config file shapes, report template skeletons |
| Checklists | `assets/checklists/` | `checklists/` | `.md` | Evaluation criteria lists (`- [ ] ...`) that ops iterate over to assess compliance or correctness |
| Policies | `assets/policies/` | `policies/` | `.md` | Behavioural constraints governing skill execution: what the skill must/must not do, consent requirements, output rendering protocols |
| Verify | `assets/verify/` | `verify/` | `.md` | Expected-state checklists consumed exclusively by `VERIFY_EXPECTED` |

**Reference line pattern:** `Read \`<category-path>/<file>\` for <brief description>.` Load at point of use in the tree — never front-load all reads at the top.

---

## Skills root

`<skills-root>` is the directory containing `canopy-runtime/SKILL.md`. Recognized roots, first match wins:

- `.agents/skills/` — cross-agent install (gh skill install default on Copilot and other hosts since gh 2.91)
- `.claude/skills/` — Claude Code
- `.github/skills/` — GitHub Copilot

All path references in this spec use `<skills-root>` as the abstract base. The runtime resolves it to whichever directory contains the running `canopy-runtime/SKILL.md`.

---

## Named operations

When a step or tree node contains an ALL_CAPS identifier:

1. Look up in `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` (skill-local ops). Backward-compatible fallback: `<skill>/ops.md` at root.
2. Fall back to consumer-defined cross-skill ops (e.g. a dedicated `project-ops` skill the consumer authored, if any).
3. Fall back to canopy-runtime's primitive slices ([`ops.md`](ops.md) → `ops/core.md`, `ops/interaction.md`, etc.).

`IF`, `ELSE_IF`, `ELSE`, `END`, `BREAK`, `SWITCH`, `CASE`, `DEFAULT`, `FOR_EACH`, `PARALLEL`, `ASK`, `SHOW_PLAN`, `EXPLORE`, `VERIFY_EXPECTED` are framework primitives — never overridden by skill or project ops.

---

## Tree format

When a skill has `## Tree`: execute the tree top-to-bottom as a sequential pipeline.

Two equivalent syntaxes are accepted:

**Markdown list syntax** — `*` nested lists written directly under `## Tree` (no fenced code block):

```markdown
* skill-name
  * OP_NAME << input >> output
  * IF << condition
    * branch-op
  * ELSE
    * other-op
```

**Box-drawing syntax** — fenced code block with tree characters:

```
skill-name
├── OP_NAME << input >> output
├── IF << condition
│   └── branch-op
└── ELSE
    └── other-op
```

Both syntaxes express the same execution model. Use whichever is easier to read and maintain.

Each node is either an op call (`OP_NAME << inputs >> outputs`) or natural language — both are valid. Op definitions in `<skill>/references/ops.md` (or `references/ops/<name>.md`) and the runtime's primitive slices may also use tree notation internally.

---

## Safety preamble

Every canopy-flavored skill (any SKILL.md with `## Tree`) must declare its runtime requirement in two places:

1. **`compatibility` field** in frontmatter — a pre-execution gate readable by agents that inspect frontmatter:
   ```yaml
   compatibility: Requires canopy-runtime for Claude Code (`gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`) or GitHub Copilot (`--agent github-copilot`). Execution on other platforms is not supported.
   ```
2. **Safety preamble** at the top of the body, before `$ARGUMENTS` — a fail-fast guard for agents that load the skill body without canopy-runtime active:
   ```markdown
   > **Runtime required:** This skill uses Canopy tree notation and requires the
   > canopy-runtime execution engine. If canopy-runtime is not active in your
   > current context, **stop immediately** — do not attempt to execute this skill.
   ```

canopy-runtime processes the preamble zone normally during initialization. Agents without canopy-runtime read the preamble as their first instruction and stop, preventing silent wrong execution on unsupported platforms.

---

## Per-skill `canopy-features` manifest

Each canopy-flavored skill should declare which feature slices it uses, so the runtime loads only what's needed:

```yaml
metadata:
  canopy-features: [interaction, control-flow, subagent]
```

Valid values: `interaction`, `control-flow`, `parallel`, `subagent`, `explore`, `verify`. The `core` slice (IF/ELSE_IF/ELSE/END/BREAK) is implicit-always-loaded and must not be listed.

**Auto-generated.** `/canopy create` and `/canopy scaffold` emit the manifest matching the produced tree. `/canopy improve` adds it where missing. `/canopy validate` reports drift between the declared features and actual tree usage.

**Backward compatibility.** Skills without a manifest continue to work — the runtime falls back to loading all slices conservatively. `/canopy validate` warns and `/canopy improve` proposes adding the manifest, but no skill breaks.

**Why.** Without the manifest, each skill execution loads the full primitive surface (~700 lines of canopy-internal text). The manifest cuts the runtime tax to ~150 lines for a typical small skill — proportional to feature usage, not to canopy's total surface.

The runtime's load procedure: read the skill's frontmatter, parse `metadata.canopy-features`, load `ops/core.md` plus the listed slice files. Manifest absent → load every file under `ops/`.
