# Conversion Expansion Rules

When converting a Canopy skill to regular (plain agentskills.io) format via `CONVERT_TO_REGULAR`, apply these expansions in order:

| Canopy element | Expand to |
|---|---|
| `## Tree` | `## Steps` (numbered list) |
| `IF << condition` / `ELSE_IF` / `ELSE` | Conditional prose: "If `<condition>`: … Otherwise: …" |
| `ASK << question \| opt1 \| opt2` | "Ask the user: `<question>` (`opt1` / `opt2`)" |
| `SHOW_PLAN >> fields` | "Show the user a plan with: `<fields>`" |
| `VERIFY_EXPECTED << file` | "Verify: check the expected-state list in `<file>`" |
| Named op call (e.g. `RESOLVE_SCOPE`) | Inline the full op definition from `references/ops.md` (or legacy `ops.md`) at that position |
| `Read \`<category-path>/<file>\`` | Inline the actual file content as a subsection or code block |
| `## Agent` section | Convert to prose preamble step: "Explore: read X and return Y" |
| `compatibility` field | **Remove** — regular skills do not require canopy-runtime |
| Safety preamble (Runtime required block) | **Remove** — regular skills run on any agent |

After expansion, also:
- Move `metadata.argument-hint` and `metadata.user-invocable` (if present) — `argument-hint` may stay in `metadata`; `user-invocable` is canopy-specific and can be dropped
- Remove `## Rules` / `## Response:` Canopy section markers if their content has been merged into the prose body
- Resulting layout still uses the standard agentskills.io directory structure (`scripts/`, `references/`, `assets/`)

**Note: conversion is lossy.** Op structure and resource separation are not recoverable from the flattened output.
