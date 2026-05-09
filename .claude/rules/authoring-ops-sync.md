---
paths:
  - "skills/canopy-runtime/references/ops.md"
  - "skills/canopy-runtime/references/ops/*.md"
  - "skills/canopy-runtime/references/runtime-claude.md"
  - "skills/canopy-runtime/references/runtime-copilot.md"
  - "skills/canopy-runtime/references/skill-resources.md"
---

# Rule: keep authoring ops in sync with framework changes

Framework changes that add capability — new primitive, new section type, new dispatch mode, new tree-notation convention, new schema-binding convention, new compatibility rule — must be reflected in the canopy authoring skill. Otherwise the agent-driven authoring path (`/canopy create`/`improve`/`advise`/`convert-to-canopy`/`validate`/`scaffold`) is blind to the new feature even though the runtime supports it.

## Why

The Canopy framework has two surfaces:

1. **Runtime** — `skills/canopy-runtime/` defines what the runtime understands and executes.
2. **Authoring agent** — `skills/canopy/` is the agent that helps users *create / modify / improve / convert / validate / scaffold* skills via `/canopy ...` operations.

A change that lands only in the runtime surface is invisible to the agent-driven authoring path. Users who type `/canopy create ...` or `/canopy improve ...` will never be guided toward the new feature even though the runtime supports it. Worse, `/canopy validate` may flag valid uses of the new feature as errors because its enumerations are stale.

The PARALLEL primitive (v0.19.0) is the canonical example of this gap and the reason this rule exists — the framework PR initially missed `improve.md`, `convert-to-canopy.md`, and `advise.md`; only `validate-checks.md` was caught on a second pass.

## What to update — by feature category

| Framework change | Authoring-skill files to update |
|---|---|
| **New primitive** added (in the matching `ops/<slice>.md` slice; index `ops.md` updated) | `assets/constants/validate-checks.md` (primitive enumeration), `assets/constants/control-flow-notation.md` (migration table row), `references/ops/improve.md` (migration audit), `references/ops/convert-to-canopy.md` (prose-pattern → primitive mapping), `references/ops/advise.md` (recommendation phase). Also map the primitive to its slice in the `metadata.canopy-features` mapping inside `create.md`/`improve.md`/`validate.md`. |
| **New section type** added to `SKILL.md` (e.g. `## Agents`) | `assets/policies/authoring-rules.md` (section parsing rules), `references/ops/scaffold.md` (skeleton), `assets/templates/skill.md` (template), `references/ops/validate.md` (section-presence checks), `assets/constants/validate-checks.md` |
| **New dispatch mode** (e.g. inline vs subagent op) | `assets/policies/authoring-rules.md`, `references/ops/improve.md`, `references/ops/convert-to-canopy.md`, `references/ops/advise.md`, `references/ops/validate.md` |
| **New tree-notation convention** (e.g. `**OP**` for subagent dispatch) | `assets/constants/control-flow-notation.md`, `assets/policies/authoring-rules.md`, `references/ops/validate.md` |
| **New schema-binding convention** (e.g. `$ref` composition through `>>`/`<<`) | `assets/constants/validate-checks.md`, `references/ops/validate.md`, `references/ops/improve.md` |
| **New compatibility / frontmatter rule** | `assets/policies/authoring-rules.md`, `references/ops/create.md`, `references/ops/scaffold.md`, `references/ops/validate.md` |

## How to apply

1. Before opening a PR that touches `skills/canopy-runtime/references/{ops,runtime-claude,runtime-copilot,skill-resources}.md`, any file under `skills/canopy-runtime/references/ops/`, or `assets/constants/marker-block.md`, walk the table above and identify which authoring-skill files need updates.
2. Include those updates in the same PR. Do NOT defer to a follow-up — the gap between framework merge and authoring-skill update is exactly when the agent-driven path is broken for users on `master`.
3. The retrofit pattern is concrete: the new feature should be **flagged as a migration target** in `improve.md`/`convert-to-canopy.md`/`advise.md`, **enumerated** in `validate-checks.md`, and **described** in `control-flow-notation.md` (when applicable).
4. Test by invoking `/canopy validate` and `/canopy improve` against an example skill that uses the new feature — they should accept the feature and propose its use, respectively.

## Enforcement

This rule is currently **documentation-only**. There is no automated check that fails CI when a framework-touching PR doesn't also touch authoring ops. If repeated violations recur, consider:

- **Mechanical diff-check** in `scripts/validate.sh`: when a PR touches framework files, require it to also touch at least one authoring-skill file (or carry a `[skip-authoring-ops]` opt-out token in the commit message)
- **`/canopy validate` extension** that compares the framework's primitive list against the authoring-skill enumerations and flags drift at authoring time
- **`/canopy framework-add` op** that walks every keep-in-sync target as a checklist procedure
