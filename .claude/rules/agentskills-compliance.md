---
paths:
  - "**/SKILL.md"
---

# Rule: agentskills.io compliance for SKILL.md

## Invariants

Every skill produced by `/canopy create` or `/canopy scaffold` enforces these invariants. `/canopy validate` and `/canopy improve` enforce them on existing skills and gap-fix where missing:

1. **Skill file is exactly `SKILL.md`** (uppercase) — case-sensitive filesystems require this exact name
2. **Frontmatter root contains only spec-allowed fields**: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Non-spec fields like `argument-hint` and `user-invocable` go inside `metadata`.
3. **Every `## Tree` skill has a `compatibility` field** declaring canopy-runtime requirement.
4. **Every `## Tree` skill has a safety preamble guard block** at the top of the body — halts execution on agents without canopy-runtime active.
5. **Cross-skill shared logic** (extracted via `/canopy refactor`) becomes a named, installable skill — never a bare shared file (a `..` reference disappears when only the dependent is installed, breaking agentskills.io autonomy).
6. **canopy-runtime self-activates** the first time an agent loads it — `/canopy activate` is mostly redundant since v0.18.0. See `runtime-activation` guidance under Install / Distribute in `CLAUDE.md` for who writes the marker block per install path.

## SKILL.md content constraints

`SKILL.md` must contain **only** orchestration:

- Frontmatter
- Safety preamble (for `## Tree` skills)
- Optional `## Agent` section
- `## Tree` (the execution pipeline)
- `## Rules` (skill-wide invariants)
- `## Response:` (output format declaration)

`SKILL.md` MUST NOT contain:

- Tables, JSON/YAML blocks, scripts, inline examples, or templates
- Op definitions (those live in `references/ops.md` or `references/ops/<name>.md`)
- Schema bodies (those live in `assets/schemas/<name>.json`)
- Lookup data, constants, mapping tables (those live in `assets/constants/`)
- Active rules / guardrails as inline content (those live in `assets/policies/`)

Structured content belongs in the appropriate category subdirectory. See `skills/canopy/assets/policies/authoring-rules.md` for the full rule set.

## Compatibility field

The `compatibility` field is **free text, max 500 characters**. It declares what the skill needs to run. For canopy-flavored skills it must mention canopy-runtime as a requirement.

Example:

```yaml
compatibility: Requires the canopy-runtime skill (published at github.com/kostiantyn-matsebora/claude-canopy). Install with any agentskills.io-compatible tool — e.g. `gh skill install`, `git clone`, the repo's `install.sh`/`install.ps1`, or the Claude Code plugin marketplace. Supports Claude Code and GitHub Copilot.
```

**Avoid `: ` inside unquoted YAML scalars** — it breaks `gh skill install`. Use comma, em-dash, or quote the whole value.

## Safety preamble (canonical text)

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

The preamble is inserted automatically by `/canopy create` and `/canopy scaffold`. It prevents silent wrong execution on agents without canopy-runtime active.

## Verification

`/canopy validate <skill>` checks all invariants and reports Errors / Warnings / Optimizations. CI also runs `scripts/validate.sh` which applies the same checks repo-wide.
