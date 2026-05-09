# Validate Checks

## Errors (framework violations)

### agentskills.io compliance

- Skill file is not exactly `SKILL.md` (uppercase) — case-sensitive filesystems require this exact name
- Frontmatter contains non-spec fields at root (allowed at root: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`)
  - `argument-hint` at root → must move into `metadata`
  - `user-invocable` at root → must move into `metadata`
- `## Tree` skill missing `compatibility` field (required to declare canopy-runtime requirement)
- `## Tree` skill missing safety preamble (the runtime-required guard block before `$ARGUMENTS` that halts execution on agents without canopy-runtime)
- `compatibility` is a YAML map / list / structured object instead of a string (agentskills.io spec defines `compatibility` as a max-500-char string; structured shapes like `compatibility: { requires: [...] }` are non-spec)
- `compatibility` exceeds 500 characters (spec maximum)
- `## Tree` skill's `compatibility` text does not name `canopy-runtime` and a locatable source (repo URL, install hint, or equivalent) — agents must be able to resolve the dependency from the field alone, with no canopy-specific knowledge
- `compatibility` text prescribes a single install command (e.g. embeds only `gh skill install ...` with no other options) — should list install tools as alternatives so agents pick what their environment supports

### Structural violations

- `SKILL.md` contains inline JSON, YAML, tables, scripts, or code blocks → must extract to category files
- Any tree node (including `Report:`, natural language steps, op descriptions) contains inline fixed text → must extract to `assets/constants/`
- Any tree node (including `Report:`, natural language steps, op descriptions) contains inline parameterised text with `<token>` slots → must extract to `assets/templates/`
- `## Tree` section is missing (skill has only prose or `## Steps`)
- `EXPLORE` is not the first tree node when `## Agent` is present
- `assets/schemas/explore-schema.json` (or legacy `schemas/explore-schema.json`) missing when `## Agent` declares `**explore**`
- A framework primitive (`IF`, `ELSE_IF`, `ELSE`, `SWITCH`, `CASE`, `DEFAULT`, `FOR_EACH`, `PARALLEL`, `BREAK`, `END`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`) is defined in skill-local or project ops
- Tree node uses `→` for output capture instead of `>>`
- Inline branch notation `IF << X → action` instead of `IF << X` with nested child node
- `Ask: "..."` prose pattern instead of `ASK << question | options`
- `Show Plan (...)` or `Show plan:` prose instead of `SHOW_PLAN >> fields`
- `VERIFY_EXPECTED` referenced but `assets/verify/verify-expected.md` (or legacy `verify/verify-expected.md`) absent
- Op calls in tree are not `ALL_CAPS`
- `## Rules` or `## Response:` section missing
- `SKILL.md` tree nodes or `Read` references contain hardcoded platform paths (`.claude/` or `.github/`) — skills must be platform-agnostic; all category file references must be relative to the skill directory
- Tree node contains a complex inline command invocation (multi-flag or multi-argument shell command) → must extract to a `scripts/` script
- `## Agent` body contains an inline mapping, table, or enumeration (e.g. `.claude/ → claude`, `X → Y` pairs, list of filenames) → extract to `assets/constants/`
- `## Agent` body contains inline quoted examples (e.g. `"create for copilot"`) → extract to `assets/constants/`

## Warnings

- Tree node is a long or complex prose sentence that cannot be read at a glance → extract to a named op in `references/ops.md`
- `## Agent` section contains boilerplate ("do not inline-read", "return JSON only") → remove; it's implicit
- Tree nodes with multiple clauses joined by `;` or ` — ` → split into step hierarchy
- Conditional prose in steps (`if X: do Y`) instead of `IF` tree node
- `Read <category>/<file>` references all front-loaded at tree top instead of point-of-use
- `## Steps` section used instead of `## Tree`
- `references/ops.md` (or legacy `ops.md`) has branching prose that should use tree notation internally
- `## Agent` body lists schema fields (`Return: X, Y, Z`) — schema is authoritative; omit the list (or add a policy note if emphasis on specific fields is needed)
- `## Agent` body is a single paragraph with ≥2 concerns joined by commas, semicolons, ` — `, or sentences → split into sub-task bullets (shape B) or extract to a named op (shape C)
- Skill uses legacy flat layout (`schemas/`, `templates/`, `commands/`, etc. at root) — works fine but consider migrating to standard `scripts/`, `references/`, `assets/` layout via `/canopy improve`
- `commands/` directory at root → should be `scripts/` (agentskills.io standard)

## Optimizations

- Inline blocks (> 5 lines) that belong in category files
- Narrative prose paragraphs compressible to step list
- `SKILL.md` exceeds 60 non-frontmatter lines
- Multi-step patterns repeated across skills → candidate for extraction to a consumer-shared skill (run REFACTOR_SKILLS, which produces a named SKILL.md-bearing skill, not a bare shared file)
