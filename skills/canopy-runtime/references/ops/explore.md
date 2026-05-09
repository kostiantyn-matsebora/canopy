# Explore Primitive — EXPLORE + `## Agent` Soft-Compat

Pre-canopy-S2 sugar for a single-element subagent that gathers context. Loaded when the skill's manifest declares `canopy-features: [..., explore, ...]`.

Notation: `<<` input source or options, `>>` captured output or displayed fields, `|` item separator.

---

## EXPLORE \>\> context

The first tree node when `## Agent` declares an `**explore**` subagent.

`EXPLORE` is **not a free-standing primitive** — it only has meaning paired with a `## Agent` section. The runtime treats this shape as syntactic sugar for an implicit single-element marked subagent op named `EXPLORE`:

- Launch an Explore subagent with the task described in the `## Agent` body.
- Do NOT inline-read files yourself — the subagent handles all file access.
- Output contract is `assets/schemas/explore-schema.json` (or legacy `schemas/explore-schema.json`).
- First tree node must be `EXPLORE >> context` (or another `>>` name; the binding sets the context variable).

Skills authored after canopy v0.20.0 should prefer the explicit subagent dispatch form (see [`subagent.md`](subagent.md)) — declare a real op (e.g. `EXPLORE_TARGET`) with a `> **Subagent.**` marker and call it as `**EXPLORE_TARGET** >> context`. The legacy `## Agent` + `EXPLORE` shape continues to work for backward compatibility; `/canopy improve` proposes migration when it encounters the legacy form.

## `## Agent` body shapes (legacy / soft-compat)

Three shapes the runtime accepts under `## Agent`:

**Shape A — minimal:**
```markdown
## Agent

**explore** — read all files under `$ARGUMENTS` and return a context object.
```

**Shape B — bullet sub-tasks:**
```markdown
## Agent

**explore** — gather review context.

Sub-tasks:
- Read all files under `$ARGUMENTS`
- Detect lint/type-check config files
```

**Shape C — op reference:**
```markdown
## Agent

**explore** — execute EXPLORE_TARGET.
```

Shape (C) resolves `EXPLORE_TARGET` via the standard op lookup chain and dispatches its body as the subagent task.

Hard removal of the legacy `## Agent` path is deferred to a pre-1.0 cleanup. Until then, this slice loads only when the skill's manifest declares `explore` (or has no manifest, so the runtime falls back to load-everything for back-compat).
