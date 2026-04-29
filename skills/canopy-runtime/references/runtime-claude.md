# Claude Code Runtime

Defines how Canopy skill constructs execute on the Claude Code platform.

---

## Base Paths

- Skills: `.claude/skills/<name>/SKILL.md`
- Canopy framework primitives: `.claude/skills/canopy/references/framework-ops.md`

## Agent Execution (`## Agent` section)

Native explore subagent is supported. When a skill declares `## Agent`:

- Launch an Explore subagent with the task described in the `## Agent` body
- Do NOT inline-read files yourself — the subagent handles all file access
- Output contract is defined in `assets/schemas/explore-schema.json` (or `schemas/explore-schema.json` for legacy-layout skills)
- First tree node must be `EXPLORE >> context`

If the `## Agent` body uses shape (C) — `**explore** — execute NAMED_OP` — resolve `NAMED_OP` via the standard op lookup chain (skill-local `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md`, falling back to `<skill>/ops.md` for legacy skills → consumer-defined cross-skill ops if any → `.claude/skills/canopy/references/framework-ops.md` for primitives) and inject the op body as the subagent's task.

## Invocation

- Wrapper skill: `/canopy <request>` — invokes `.claude/skills/canopy/SKILL.md`, which delegates to `.claude/skills/canopy/SKILL.md`
- Direct skill: `Follow .claude/skills/canopy/SKILL.md and <request>` — bypasses the wrapper
- Other skills: `/skill-name` — resolved from `.claude/skills/<name>/SKILL.md`

## Op Lookup

1. `.claude/skills/<skill>/references/ops.md` or `.claude/skills/<skill>/references/ops/<name>.md` — skill-local. Backward-compatible fallback: `.claude/skills/<skill>/ops.md` at root.
2. Consumer-defined cross-skill ops (optional; consumers may package these as their own skill)
3. `.claude/skills/canopy/references/framework-ops.md` — framework primitives (always available when `canopy` is installed). canopy-runtime exposes the same `references/framework-ops.md`.
