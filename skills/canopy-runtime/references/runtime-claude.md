# Claude Code Runtime

Defines how Canopy skill constructs execute on the Claude Code platform.

`<skills-root>` resolves to whichever recognized skills directory canopy-runtime was installed into — `.agents/skills/`, `.claude/skills/`, or `.github/skills/` (see `SKILL.md` → Skills root resolution). Claude Code natively reads from `.claude/skills/`; cross-agent installs at `.agents/skills/` are exposed to Claude when the workspace mirrors them or the install script writes to `.claude/skills/` directly.

---

## Base paths

- Skills: `<skills-root>/<name>/SKILL.md`
- Primitive slices: `<skills-root>/canopy-runtime/references/ops.md` (index) → `<skills-root>/canopy-runtime/references/ops/<slice>.md`

## Subagent dispatch

Native subagent invocation is supported via per-op markers (preferred) and via the legacy `## Agent` section (soft-compat).

### Marker-based dispatch (preferred)

When a tree node is `**OP_NAME** << input >> output` (bold around the op name), launch a subagent with the body of `OP_NAME` as its task:

- Resolve `OP_NAME` via the standard op lookup chain (skill-local `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`, falling back to `<skill>/ops.md` for legacy skills → consumer-defined cross-skill ops if any → canopy-runtime's primitive slices).
- Verify the resolved op definition carries the marker `> **Subagent.** Output contract: <schema-path>` as the first content under its heading; if missing, halt with a contract-mismatch diagnostic.
- Launch the subagent via the `Task` tool, passing the bound `<<` values as the subagent's inputs; the subagent body uses only those inputs + static skill assets.
- Bind the subagent's schema-shaped result to the call-site `>>` name; surface in the parent context.

Multiple bold-marked op calls inside a single `PARALLEL` block emit multiple `Task` tool calls in one assistant message — heterogeneous parallel fan-out. Sibling failures don't abort each other (`Promise.allSettled`).

See [`ops/subagent.md`](ops/subagent.md) for the full marker contract.

### Soft-compat: `## Agent` + `EXPLORE`

Existing skills with `## Agent` declaring `**explore**` + `EXPLORE >> context` as the first tree node keep working — runtime treats this as a single-element marked op named `EXPLORE`:

- Launch an Explore subagent with the task described in the `## Agent` body.
- Do NOT inline-read files yourself — the subagent handles all file access.
- Output contract is `assets/schemas/explore-schema.json` (or legacy `schemas/explore-schema.json`).
- First tree node must be `EXPLORE >> context`.

If the `## Agent` body uses shape (C) — `**explore** — execute NAMED_OP` — resolve `NAMED_OP` via the standard op lookup chain and inject the op body as the subagent's task.

See [`ops/explore.md`](ops/explore.md) for the soft-compat shapes.

## Parallel subagent invocation

When a tree node says "spawn N subagents in parallel," fan out by emitting N `Task` tool calls in a single assistant message. The harness runs them concurrently; each subagent has its own context window.

- **Bind by name** — assign each result to the `>>` name the prose specifies; outputs return in completion order.
- **One assistant turn, N Task calls** — preferred over N serial messages: keeps the prompt-cache prefix stable and avoids `(N − 1) × R` inter-turn reasoning overhead.
- **`Promise.allSettled` semantics** — a single failure does not abort siblings; surface all outcomes and let downstream nodes branch via `IF`.
- **Heterogeneous fan-out only** — different tasks, independent inputs. Data-parallel iteration over a list is not yet specified.
- **`PARALLEL` block** — when a `PARALLEL` node is the current tree position, emit one `Task` call per child in this assistant turn. Deterministic fan-out shape — no prose detection needed. Each child's `>>` becomes its binding handle.
- **Marker-based subagent calls inside `PARALLEL`** — when children are `**OP_NAME** << ... >> ...` (bold around op name), each Task call uses the resolved op's body as the subagent task and binds the schema-shaped result. See `## Subagent dispatch` above for the contract.

## Invocation

- Wrapper skill: `/canopy <request>` — invokes `<skills-root>/canopy/SKILL.md`
- Direct skill: `Follow <skills-root>/canopy/SKILL.md and <request>` — bypasses the wrapper
- Other skills: `/skill-name` — resolved from `<skills-root>/<name>/SKILL.md`

## Op lookup

1. `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` — skill-local. Backward-compatible fallback: `<skill>/ops.md` at root.
2. Consumer-defined cross-skill ops (optional; consumers may package these as their own skill).
3. canopy-runtime's primitive slices — `<skills-root>/canopy-runtime/references/ops.md` indexes the per-feature slice files.
