# GitHub Copilot Runtime

Defines how Canopy skill constructs execute on the GitHub Copilot platform.

`<skills-root>` resolves to whichever recognized skills directory canopy-runtime was installed into — `.agents/skills/`, `.claude/skills/`, or `.github/skills/` (see `SKILL.md` → Skills root resolution). Copilot reads skills from `.github/skills/` natively; gh skill install on recent gh CLI versions defaults to `.agents/skills/` for cross-agent compatibility.

---

## Base Paths

- Skills: `<skills-root>/<name>/SKILL.md`
- Canopy framework primitives: `<skills-root>/canopy/references/framework-ops.md`

## Agent Execution (`## Agent` section)

Native subagent invocation is supported via two paths; sequential inline reading is the correctness-preserving fallback when neither path is available.

- **`/fleet` orchestration** — when fleet mode or autopilot is active, the orchestrator decomposes the `## Agent` body into parallel subtasks; each subagent runs in its own context window. The first tree node `EXPLORE >> context` is satisfied by the orchestrator's dispatch.
- **`@CUSTOM-AGENT-NAME` reference** — invoke a pre-defined custom agent inline by name; the result populates `context` against `assets/schemas/explore-schema.json` (or `schemas/explore-schema.json` for legacy-layout skills).
- **Sequential inline fallback** — when neither path is available, read the files described in the `## Agent` body sequentially before the first tree node; treat gathered content as `context` shaped to the same schema. Correctness is preserved; parallelism is lost.

Output contract is identical across all three paths.

If the `## Agent` body uses shape (C) — `**explore** — execute NAMED_OP` — resolve `NAMED_OP` via the standard op lookup chain (skill-local `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`, falling back to `<skill>/ops.md` for legacy skills → consumer-defined cross-skill ops if any → `<skills-root>/canopy/references/framework-ops.md` for primitives) and dispatch the resolved op body via the selected path (fleet subtask body, custom-agent invocation prompt, or inline reading procedure).

## Parallel Subagent Invocation

When a tree node says "spawn N subagents in parallel," prefer `/fleet` if active — the orchestrator handles fan-out and per-subagent isolation. Otherwise dispatch via `@CUSTOM-AGENT-NAME` references inside the prompt. If neither is available, fall back to sequential inline reads (correct, but loses parallelism).

- **Bind by name** — assign each result to the `>>` name the prose specifies.
- **Failure semantics follow the underlying mode** — fleet aggregates outcomes; sequential reads short-circuit on first failure.
- **Heterogeneous fan-out only** — data-parallel iteration over a list is not yet specified.

## Invocation

- Wrapper skill: `/canopy <request>` — invokes `<skills-root>/canopy/SKILL.md`
- Direct skill: `Follow <skills-root>/canopy/SKILL.md and <request>` — bypasses the wrapper
- Other skills: `/skill-name` — resolved from `<skills-root>/<name>/SKILL.md`

## Op Lookup

1. `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` — skill-local. Backward-compatible fallback: `<skill>/ops.md` at root.
2. Consumer-defined cross-skill ops (optional; consumers may package these as their own skill)
3. `<skills-root>/canopy/references/framework-ops.md` — framework primitives (always available when `canopy` is installed). canopy-runtime exposes the same `references/framework-ops.md`.
