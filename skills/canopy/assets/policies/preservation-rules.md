# Preservation Rules

When modifying an existing Canopy skill:

- Preserve the existing tree syntax — do not switch `*` (Markdown list) ↔ box-drawing characters unless explicitly asked.
- Preserve the existing directory layout (legacy flat vs. standard `scripts/`/`references/`/`assets/`) unless the user explicitly asks for migration via `/canopy improve`. MODIFY does not silently restructure directories.
- Do not change skill logic or intent — only the surface area requested may change.
- Do not remove or reposition existing tree nodes unless the change was explicitly requested.
- Do not merge ops that share a name but have meaningfully different behaviour — flag those as conflicts instead.
- Do not alter `## Rules` or `## Response:` wording unless explicitly requested.
- Preserve the `compatibility` field and safety preamble on `## Tree` skills — never remove them during MODIFY. Add them if missing on `## Tree` skills (gap-fix is allowed because their absence violates compliance).
