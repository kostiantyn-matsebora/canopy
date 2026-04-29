# Skill Resource Conventions

Reference documentation describing how Canopy resolves resource references inside skills.

Loaded via ambient instruction at session start (the `canopy-runtime` marker block in `CLAUDE.md` / `.github/copilot-instructions.md`) and by canopy authoring ops when needed. Shared between the runtime (for interpretation at execution time) and the canopy authoring agent (for VALIDATE/IMPROVE/SCAFFOLD/CONVERT_TO_CANOPY/etc. at authoring time).

---

## Skill layout

A canopy skill aligns with the agentskills.io standard. Only `SKILL.md` lives at the root; everything else is grouped under three standard top-level directories:

```
skill-name/
├── SKILL.md          # required — frontmatter + body
├── scripts/          # executable code (.ps1, .sh)
├── references/       # docs loaded on demand
│   ├── ops.md        # skill-local op definitions (simple skills)
│   └── ops/          # one-file-per-op definitions (complex skills)
└── assets/           # static resources
    ├── templates/    # fillable output documents with <token> placeholders
    ├── constants/    # read-only lookup data
    ├── schemas/      # structure definitions (subagent contracts, data shapes)
    ├── checklists/   # evaluation criteria (- [ ] ...)
    ├── policies/     # behavioural constraints
    └── verify/       # VERIFY_EXPECTED checklists
```

### Backward compatibility

Older skills may use a flat layout (`schemas/`, `templates/`, `commands/`, `constants/`, `checklists/`, `policies/`, `verify/`, `ops.md` all at the root). The runtime continues to honour `Read \`<dir>/<file>\`` instructions exactly as written, so old skills execute unchanged. New skills should adopt the standard layout above.

---

## Category behavior

When a skill step says `Read <category>/<file>`, the directory determines behavior. Categories are listed by their canonical (new-layout) location:

| Category | New-layout location | Old-layout fallback | File types | Behavior |
|----------|--------------------|--------------------|------------|----------|
| Executable code | `scripts/` | `commands/` | `.ps1`, `.sh` | Invoked by name via a named section (`# === Section Name ===`); output captured into context |
| Op definitions | `references/ops.md` or `references/ops/<name>.md` | `ops.md` or `ops/<name>.md` | `.md` | Skill-local op definitions; resolved before consumer cross-skill ops and framework primitives |
| References | `references/` | `references/` | `.md` | Supporting documentation loaded on demand (per the agentskills.io progressive-disclosure pattern) |
| Templates | `assets/templates/` | `templates/` | `.yaml`, `.md`, `.yaml.gotmpl` | Fillable output documents with `<token>` placeholders substituted from context and written to a target path |
| Constants | `assets/constants/` | `constants/` | `.md` | Read-only lookup data referenced by ops: mapping tables, enum-like value lists, fixed configuration values |
| Schemas | `assets/schemas/` | `schemas/` | `.json`, `.md` | Structure definitions: subagent output contracts, input/config file shapes, report template skeletons |
| Checklists | `assets/checklists/` | `checklists/` | `.md` | Evaluation criteria lists (`- [ ] ...`) that ops iterate over to assess compliance or correctness |
| Policies | `assets/policies/` | `policies/` | `.md` | Behavioural constraints governing skill execution: what the skill must/must not do, consent requirements, output rendering protocols |
| Verify | `assets/verify/` | `verify/` | `.md` | Expected-state checklists consumed exclusively by `VERIFY_EXPECTED` |

**Reference line pattern:** `Read \`<category-path>/<file>\` for <brief description>.`
Load at point of use in the tree — never front-load all reads at the top.

## Skills root

`<skills-root>` is the directory containing `canopy-runtime/SKILL.md`. Recognized roots, first match wins:

- `.agents/skills/` — cross-agent install (gh skill install default on Copilot and other hosts since gh 2.91)
- `.claude/skills/` — Claude Code
- `.github/skills/` — GitHub Copilot

All path references in this spec use `<skills-root>` as the abstract base. The runtime resolves it to whichever directory contains the running `canopy-runtime/SKILL.md`.

## Named operations

When a step or tree node contains an ALL_CAPS identifier:
1. Look up in `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` (skill-local ops). Backward-compatible fallback: `<skill>/ops.md` at root.
2. Fall back to consumer-defined cross-skill ops (e.g. a dedicated `project-ops` skill the consumer authored, if any)
3. Fall back to `<skills-root>/canopy/references/framework-ops.md` for framework primitives. (canopy-runtime exposes this same `references/framework-ops.md` so consumers without `canopy` installed still get the primitives.)

`IF`, `ELSE_IF`, `ELSE`, `SWITCH`, `CASE`, `DEFAULT`, `FOR_EACH`, `BREAK`, `END`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED` are primitives — always in `framework-ops.md`.

## Tree format

When a skill has `## Tree` instead of `## Steps`: execute the tree top-to-bottom as a sequential pipeline.

Two equivalent syntaxes are accepted:

**Markdown list syntax** — `*` nested lists written directly under `## Tree` (no fenced code block):
```markdown
* skill-name
  * OP_NAME << input >> output
  * IF << condition
    * branch-op
  * ELSE
    * other-op
```

**Box-drawing syntax** — fenced code block with tree characters:
```
skill-name
├── OP_NAME << input >> output
├── IF << condition
│   └── branch-op
└── ELSE
    └── other-op
```

Both syntaxes express the same execution model. Use whichever is easier to read and maintain.

Each node is either an op call (`OP_NAME << inputs >> outputs`) or natural language — both are valid.
`IF` nodes branch on condition; both branches may be op calls or natural language.
Op definitions in `<skill>/references/ops.md` (or `references/ops/<name>.md`) and `framework-ops.md` may also use tree notation internally.

## Safety preamble

Every canopy-flavored skill (any SKILL.md with `## Tree`) must declare its runtime requirement in two places:

1. **`compatibility` field** in frontmatter — a pre-execution gate readable by agents that inspect frontmatter:
   ```yaml
   compatibility: Requires canopy-runtime for Claude Code (`gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`) or GitHub Copilot (`--agent github-copilot`). Execution on other platforms is not supported.
   ```
2. **Safety preamble** at the top of the body, before `$ARGUMENTS` — a fail-fast guard for agents that load the skill body without canopy-runtime active:
   ```markdown
   > **Runtime required:** This skill uses Canopy tree notation and requires the
   > canopy-runtime execution engine. If canopy-runtime is not active in your
   > current context, **stop immediately** — do not attempt to execute this skill.
   > Inform the user: "canopy-runtime must be installed and activated first.
   > Run: `gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`"
   ```

canopy-runtime processes the preamble zone normally during initialization. Agents without canopy-runtime read the preamble as their first instruction and stop, preventing silent wrong execution on unsupported platforms.

## Explore subagent

When a skill has a `## Agent` section declaring `**explore**`:
- Launch an Explore subagent with the task described in that section
- Do NOT inline-read files yourself
- Use `assets/schemas/explore-schema.json` (or `schemas/explore-schema.json` for older skills) as the output contract; return JSON only
