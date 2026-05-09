# Framework Primitives — Index

Control-flow and interaction primitives available in every skill tree. Sliced into feature groups so a skill loads only what it uses.

Notation: `<<` input source or options, `>>` captured output or displayed fields, `|` item separator.

## Slice index

| Slice file | Primitives | Always loaded |
|---|---|:---:|
| [`ops/core.md`](ops/core.md) | `IF`, `ELSE_IF`, `ELSE`, `END`, `BREAK` | ✓ |
| [`ops/interaction.md`](ops/interaction.md) | `ASK`, `SHOW_PLAN` | |
| [`ops/control-flow.md`](ops/control-flow.md) | `SWITCH`, `CASE`, `DEFAULT`, `FOR_EACH` | |
| [`ops/parallel.md`](ops/parallel.md) | `PARALLEL` | |
| [`ops/subagent.md`](ops/subagent.md) | Subagent dispatch — marker + bold call-site (no new primitive) | |
| [`ops/explore.md`](ops/explore.md) | `EXPLORE` + `## Agent` soft-compat | |
| [`ops/verify.md`](ops/verify.md) | `VERIFY_EXPECTED` | |

## Loading rules

The runtime loads slices on demand based on the skill's manifest:

- **Always loaded:** `ops/core.md` (universal control flow — every non-trivial tree uses it).
- **Loaded per `metadata.canopy-features`:** when the skill declares `canopy-features: [interaction, parallel]`, the runtime additionally loads `ops/interaction.md` and `ops/parallel.md`.
- **Manifest absent (back-compat):** load all slices. The skill is treated as feature-unknown, so the full primitive surface is loaded conservatively. `/canopy validate` warns; `/canopy improve` proposes adding the manifest.

Primitives are never overridden by skill-local or project ops.

## Slice values (for `metadata.canopy-features`)

`core` is implicit-always-loaded — never list it in the manifest. Other valid values:

- `interaction`
- `control-flow`
- `parallel`
- `subagent`
- `explore`
- `verify`

`/canopy validate` enforces drift between declared features and tree usage (warning here; vscode error in the follow-up extension PR).
