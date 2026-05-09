# GitHub Copilot Runtime

Defines how Canopy skill constructs execute on the GitHub Copilot platform.

`<skills-root>` resolves to whichever recognized skills directory canopy-runtime was installed into — `.agents/skills/`, `.claude/skills/`, or `.github/skills/` (see `SKILL.md` → Skills root resolution). Copilot reads skills from `.github/skills/` natively; gh skill install on recent gh CLI versions defaults to `.agents/skills/` for cross-agent compatibility.

---

## Base Paths

- Skills: `<skills-root>/<name>/SKILL.md`
- Canopy framework primitives: `<skills-root>/canopy/references/framework-ops.md`

## Subagent dispatch

Native subagent invocation is supported via per-op markers (preferred) and via the legacy `## Agent` section (soft-compat).

### Marker-based dispatch (preferred)

When a tree node is `**OP_NAME** << input >> output` (bold around the op name), dispatch the resolved op's body as a subagent. Path selection by available context:

- **`/fleet` orchestration** — when fleet mode or autopilot is active, the orchestrator dispatches each marked op as a subtask; each subagent runs in its own context window
- **`@CUSTOM-AGENT-NAME` reference** — invoke a pre-defined custom agent inline by name; the result populates the call-site `>>` binding shaped to the marker's declared output schema
- **Sequential inline fallback** — when neither path is available, evaluate the resolved op's body sequentially as if it were inline; gather its result into the bound `>>` name. Correctness is preserved; parallelism is lost.

Resolution: standard op lookup chain (skill-local `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`, falling back to `<skill>/ops.md` for legacy skills → consumer-defined cross-skill ops if any → `<skills-root>/canopy/references/framework-ops.md` for primitives). The resolved op definition must carry the marker `> **Subagent.** Output contract: <schema-path>` as the first content under its heading; if missing, halt with a contract-mismatch diagnostic.

### Soft-compat: `## Agent` + `EXPLORE`

Existing skills with `## Agent` declaring `**explore**` + `EXPLORE >> context` as the first tree node keep working — runtime treats this as a single-element marked op named `EXPLORE`:

- **`/fleet`** — orchestrator decomposes the `## Agent` body into parallel subtasks; each subagent runs in its own context window. The first tree node `EXPLORE >> context` is satisfied by the orchestrator's dispatch.
- **`@CUSTOM-AGENT-NAME`** — result populates `context` against `assets/schemas/explore-schema.json` (or legacy `schemas/explore-schema.json`).
- **Sequential inline fallback** — read the files described in the `## Agent` body sequentially before the first tree node; treat gathered content as `context` shaped to the same schema.

Output contract is identical across all paths.

If the `## Agent` body uses shape (C) — `**explore** — execute NAMED_OP` — resolve `NAMED_OP` via the standard op lookup chain and dispatch the resolved op body via the selected path (fleet subtask body, custom-agent invocation prompt, or inline reading procedure).

## Parallel Subagent Invocation

When a tree node says "spawn N subagents in parallel," prefer `/fleet` if active — the orchestrator handles fan-out and per-subagent isolation. Otherwise dispatch via `@CUSTOM-AGENT-NAME` references inside the prompt. If neither is available, fall back to sequential inline reads (correct, but loses parallelism).

- **Bind by name** — assign each result to the `>>` name the prose specifies.
- **Failure semantics follow the underlying mode** — fleet aggregates outcomes; sequential reads short-circuit on first failure.
- **Heterogeneous fan-out only** — data-parallel iteration over a list is not yet specified.
- **`PARALLEL` block** — when a `PARALLEL` node is the current tree position, dispatch each child to the active subagent path (fleet subtask if `/fleet` active; otherwise `@CUSTOM-AGENT-NAME` reference; otherwise sequential inline). Each child's `>>` becomes its binding handle.
- **Marker-based subagent calls inside `PARALLEL`** — when children are `**OP_NAME** << ... >> ...` (bold around op name), each child dispatches the resolved op's body via the active path and binds the schema-shaped result. See `## Subagent dispatch` above for the contract.

## Invocation

- Wrapper skill: `/canopy <request>` — invokes `<skills-root>/canopy/SKILL.md`
- Direct skill: `Follow <skills-root>/canopy/SKILL.md and <request>` — bypasses the wrapper
- Other skills: `/skill-name` — resolved from `<skills-root>/<name>/SKILL.md`

## Op Lookup

1. `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` — skill-local. Backward-compatible fallback: `<skill>/ops.md` at root.
2. Consumer-defined cross-skill ops (optional; consumers may package these as their own skill)
3. `<skills-root>/canopy/references/framework-ops.md` — framework primitives (always available when `canopy` is installed). canopy-runtime exposes the same `references/framework-ops.md`.
