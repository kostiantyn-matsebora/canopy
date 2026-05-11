# GitHub Copilot Runtime

Defines how Canopy skill constructs execute on the GitHub Copilot platform.

`<skills-root>` resolves to whichever recognized skills directory canopy-runtime was installed into — `.agents/skills/`, `.claude/skills/`, or `.github/skills/` (see `SKILL.md` → Skills root resolution). Copilot reads skills from `.github/skills/` natively; gh skill install on recent gh CLI versions defaults to `.agents/skills/` for cross-agent compatibility.

---

## Base paths

- Skills: `<skills-root>/<name>/SKILL.md`
- Primitive slices: `<skills-root>/canopy-runtime/references/ops.md` (index) → `<skills-root>/canopy-runtime/references/ops/<slice>.md`

## Dispatch path resolution

All subagent dispatch — whether from a marked op call, a `PARALLEL` block child, or a soft-compat `## Agent` section — uses the same four-path chain (first match wins):

1. **`/fleet` orchestration** — when fleet mode or autopilot is active, the orchestrator handles fan-out; each op or child runs in its own context window.
2. **`@CUSTOM-AGENT-NAME` reference** — invoke a pre-defined custom agent inline by name; the result populates the call-site `>>` binding.
3. **Native Copilot subagent dispatch** — Copilot's agent engine natively supports spawning subagents in parallel via its built-in subagent capability (e.g. `runSubagent`). **This is the default path** when fleet and named custom agents are not configured. Dispatch all subagents simultaneously; each runs in its own context window.
4. **Sequential inline fallback** — only when native dispatch is explicitly unavailable (e.g. tool disabled by the user). Before falling back, **ask the user**: "Parallel subagent dispatch is unavailable. These steps are intended to run in parallel — proceeding sequentially will be slower. Continue sequentially? | Yes | No". Halt if the user says No. If Yes, evaluate each op body sequentially inline. Correctness is preserved; parallelism is lost.

**Failure semantics**: paths 1–3 follow `Promise.allSettled` — a single child failure does not abort siblings. Path 4 (sequential) short-circuits on first failure.

## Subagent dispatch

Native subagent invocation is supported via per-op markers (preferred) and via the legacy `## Agent` section (soft-compat).

### Marker-based dispatch (preferred)

When a tree node is `**OP_NAME** << input >> output` (bold around the op name), dispatch the resolved op's body as a subagent using the **Dispatch path resolution** chain above.

Resolution: standard op lookup chain (skill-local `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`, falling back to `<skill>/ops.md` for legacy skills → consumer-defined cross-skill ops if any → canopy-runtime's primitive slices). The resolved op definition must carry the marker `> **Subagent.** Output contract: <schema-path>` as the first content under its heading; if missing, halt with a contract-mismatch diagnostic.

See [`ops/subagent.md`](ops/subagent.md) for the full marker contract.

### Soft-compat: `## Agent` + `EXPLORE`

Existing skills with `## Agent` declaring `**explore**` + `EXPLORE >> context` as the first tree node keep working — runtime treats this as a single-element marked op named `EXPLORE`. Apply the **Dispatch path resolution** chain above. In all cases the result populates `context` shaped to `assets/schemas/explore-schema.json` (or legacy `schemas/explore-schema.json`).

Output contract is identical across all paths.

If the `## Agent` body uses shape (C) — `**explore** — execute NAMED_OP` — resolve `NAMED_OP` via the standard op lookup chain and dispatch the resolved op body via the selected path.

See [`ops/explore.md`](ops/explore.md) for the soft-compat shapes.

## Parallel subagent invocation

When a tree node says "spawn N subagents in parallel," apply the **Dispatch path resolution** chain above to all children simultaneously.

- **Bind by name** — assign each result to the `>>` name the prose specifies.
- **Heterogeneous fan-out only** — data-parallel iteration over a list is not yet specified.
- **`PARALLEL` block** — when a `PARALLEL` node is the current tree position, dispatch each child simultaneously via the resolved path. Each child's `>>` becomes its binding handle.
- **Marker-based subagent calls inside `PARALLEL`** — when children are `**OP_NAME** << ... >> ...` (bold around op name), each child dispatches the resolved op's body as a subagent and binds the schema-shaped result. See `## Subagent dispatch` above for the contract.

## Invocation

- Wrapper skill: `/canopy <request>` — invokes `<skills-root>/canopy/SKILL.md`
- Direct skill: `Follow <skills-root>/canopy/SKILL.md and <request>` — bypasses the wrapper
- Other skills: `/skill-name` — resolved from `<skills-root>/<name>/SKILL.md`

## Op lookup

1. `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` — skill-local. Backward-compatible fallback: `<skill>/ops.md` at root.
2. Consumer-defined cross-skill ops (optional; consumers may package these as their own skill).
3. canopy-runtime's primitive slices — `<skills-root>/canopy-runtime/references/ops.md` indexes the per-feature slice files.
