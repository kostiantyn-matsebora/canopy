# GitHub Copilot Runtime

Defines how Canopy skill constructs execute on the GitHub Copilot platform.

`<skills-root>` resolves to whichever recognized skills directory canopy-runtime was installed into — `.agents/skills/`, `.claude/skills/`, or `.github/skills/` (see `SKILL.md` → Skills root resolution). Copilot reads skills from `.github/skills/` natively; gh skill install on recent gh CLI versions defaults to `.agents/skills/` for cross-agent compatibility.

---

## Base Paths

- Skills: `<skills-root>/<name>/SKILL.md`
- Canopy framework primitives: `<skills-root>/canopy/references/framework-ops.md`

## Agent Execution (`## Agent` section)

Native explore subagent is **not supported**. When a skill declares `## Agent`, apply the inline fallback:

- Do NOT launch a subagent
- Read the files described in the `## Agent` task body sequentially at the start of execution, before the first tree node
- Treat all gathered content as `context`, structured to match `assets/schemas/explore-schema.json` (or `schemas/explore-schema.json` for legacy-layout skills)
- The first tree node (`EXPLORE >> context`) is satisfied by this inline reading step

If the `## Agent` body uses shape (C) — `**explore** — execute NAMED_OP` — resolve `NAMED_OP` via the standard op lookup chain (skill-local `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`, falling back to `<skill>/ops.md` for legacy skills → consumer-defined cross-skill ops if any → `<skills-root>/canopy/references/framework-ops.md` for primitives), read the op body, and execute it inline as the fallback procedure.

## Invocation

- Wrapper skill: `/canopy <request>` — invokes `<skills-root>/canopy/SKILL.md`
- Direct skill: `Follow <skills-root>/canopy/SKILL.md and <request>` — bypasses the wrapper
- Other skills: `/skill-name` — resolved from `<skills-root>/<name>/SKILL.md`

## Op Lookup

1. `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` — skill-local. Backward-compatible fallback: `<skill>/ops.md` at root.
2. Consumer-defined cross-skill ops (optional; consumers may package these as their own skill)
3. `<skills-root>/canopy/references/framework-ops.md` — framework primitives (always available when `canopy` is installed). canopy-runtime exposes the same `references/framework-ops.md`.
