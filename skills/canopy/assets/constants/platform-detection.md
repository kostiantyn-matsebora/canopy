# Platform Detection

Used at **authoring time** by the canopy agent to decide which platform a project supports — for SCAFFOLD/CREATE target selection, validation, etc. (Authoring detection is path-based; runtime detection is the agent self-identifying — see `canopy-runtime/SKILL.md` → Platform detection.)

## Skills root candidates

A project may have skills installed at any of these locations. First match wins for `<skills-root>` resolution:

| Directory present | Skills root | Platform served |
|-------------------|-------------|-----------------|
| `.agents/skills/` | Cross-client (single install serves both Claude Code and Copilot) | both |
| `.claude/skills/` | Claude Code native | claude |
| `.github/skills/` | GitHub Copilot native | copilot |

A project may have one, two, or all three roots. They are not mutually exclusive — the canonical example is a project that uses Cross-client (`.agents/skills/`) but also has Claude-specific skills under `.claude/skills/`.

## Authoring-time platform availability

`available_platforms` is the set of platforms this project explicitly supports. Detection rules:

| Directory | Adds platform |
|-----------|---------------|
| `.claude/` | `claude` |
| `.github/` | `copilot` |
| `.agents/` | `claude` AND `copilot` (Cross-client serves both) |

If multiple roots are present, all matching platforms are added (deduplicated). If none are present, SCAFFOLD/CREATE asks which platform(s) to initialise.

## Runtime platform detection

Runtime detection is **not** path-based. The active host self-identifies — Claude Code knows it is Claude Code, Copilot knows it is Copilot. canopy-runtime's `Platform detection` section in `SKILL.md` defines the runtime contract; this constants file is for authoring-time decisions only.
