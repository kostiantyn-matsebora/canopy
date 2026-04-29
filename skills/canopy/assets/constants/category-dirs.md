# Category Directory Reference

Canopy skills follow the agentskills.io standard layout: only `SKILL.md` at the root, with everything else under three top-level directories — `scripts/`, `references/`, `assets/`.

## Standard layout (preferred for new skills)

| Path | File types | Contains | Decision rule |
|------|------------|----------|--------------|
| `scripts/` | `.ps1`, `.sh` | Executable scripts invoked by name via a named section (`# === Section Name ===`); output captured into context | Use when the skill must run a shell command — never for data or rules |
| `references/ops.md` or `references/ops/<name>.md` | `.md` | Skill-local op definitions (single file for simple skills, per-op files under `references/ops/` for complex skills) | Use for conditional branches, multi-step procedures, or decision trees specific to one skill |
| `references/<other>.md` | `.md` | Supporting documentation loaded on demand by tree nodes (per the agentskills.io progressive-disclosure pattern) — e.g. cross-cutting protocol guides, workflow notes |
| `assets/templates/` | `.yaml`, `.md`, `.yaml.gotmpl` | Fillable output documents with `<token>` placeholders substituted from context and written to a target path | Use when the skill generates a file from a pattern — never for static reference data |
| `assets/constants/` | `.md` | Read-only lookup data referenced by ops: mapping tables, enum-like value lists, fixed configuration values, default branch/path names | Use when an op looks up a static value from a table or list — never for behavioural constraints, never for document shapes |
| `assets/schemas/` | `.json`, `.md` | Structure definitions for data the skill reads or writes: subagent output contracts, input/config file shapes, report template skeletons | Use when describing the *shape* of a document or data object — never for rules, never for lookup values |
| `assets/checklists/` | `.md` | Evaluation criteria lists (`- [ ] ...`) that ops iterate over to assess compliance or correctness | Use when an op checks items against a list of criteria — never for static lookup values, never for post-execution state |
| `assets/policies/` | `.md` | Behavioural constraints governing skill execution: what the skill must/must not do, consent requirements, output rendering protocols | Use when answering "what is the skill allowed or required to do?" — never for tables, never for schemas |
| `assets/verify/` | `.md` | Expected-state checklists consumed exclusively by `VERIFY_EXPECTED` | Use only for post-execution verification — nothing else |

## Legacy flat layout (backward compatible)

Older skills place all category directories at the skill root (`schemas/`, `templates/`, `commands/`, `constants/`, `checklists/`, `policies/`, `verify/`, `ops.md`, `ops/`). canopy-runtime continues to honour `Read \`<dir>/<file>\`` instructions exactly as written, so legacy skills execute unchanged. The mapping:

| Legacy path | Standard path |
|-------------|---------------|
| `commands/` | `scripts/` |
| `ops.md` | `references/ops.md` |
| `ops/` | `references/ops/` |
| `templates/` | `assets/templates/` |
| `constants/` | `assets/constants/` |
| `schemas/` | `assets/schemas/` |
| `checklists/` | `assets/checklists/` |
| `policies/` | `assets/policies/` |
| `verify/` | `assets/verify/` |

`/canopy improve` detects legacy layout and offers a migration plan. New skills authored by `/canopy create` or `/canopy scaffold` use the standard layout automatically.

## Rules

One concern per file. Do not bundle unrelated content into a single file.

Reference line pattern in `SKILL.md`: `Read \`<category-path>/<file>\` for <brief description>.`
Load at point of use in the tree — never front-load all reads at the top.
