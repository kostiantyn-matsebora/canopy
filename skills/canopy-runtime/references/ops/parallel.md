# Parallel Primitive — PARALLEL

Heterogeneous parallel-subagent fan-out. Loaded when the skill's manifest declares `canopy-features: [..., parallel, ...]`.

Notation: `<<` input source or options, `>>` captured output or displayed fields, `|` item separator.

---

## PARALLEL

```
PARALLEL
├── child-step-1
├── child-step-2
└── child-step-3
```

Heterogeneous parallel block.
Emit children as parallel subagent invocations in a single agent turn; each child runs in its own context window.
`PARALLEL` itself takes no input and produces no aggregate output — the parent merges children's named bindings via subsequent tree nodes (e.g., a custom `MERGE_*` op).
Children may be op calls, prose subagent invocations, or `EXPLORE`; each child binds its result via its own `>>`.

**Marker-based children** (preferred): when a child is `**OP_NAME** << ... >> ...` (bold around the op name) and the resolved op definition carries `> **Subagent.** Output contract: <schema>`, the runtime dispatches the op's body as a subagent with the bound `<<` values as inputs and binds the schema-shaped result. Plain (un-bold) op-call children run inline. See [`subagent.md`](subagent.md) for the full contract.

Failure semantics: `Promise.allSettled` — a single child failure does not abort siblings; downstream nodes branch on outcomes via `IF`.
Use for ≥2 independent fan-out tasks with no ordering dependencies between them.
For data-parallel iteration over a list, use sequential `FOR_EACH` — `PARALLEL_FOR_EACH` is not yet specified.
Platform-specific emission rules: see [`runtime-claude.md`](../runtime-claude.md) and [`runtime-copilot.md`](../runtime-copilot.md).

A skill that uses `PARALLEL` with marker-based children should declare both features in its manifest:

```yaml
metadata:
  canopy-features: [parallel, subagent]
```
