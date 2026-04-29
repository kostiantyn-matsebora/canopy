# HELP

Present a concise help reference for the Canopy agent — no files are read, no changes are made.

Emit the following output exactly as structured:

---

## What is Canopy?

Canopy is a declarative, tree-structured execution framework for skills following the [Agent Skills](https://agentskills.io) open standard.
A skill is a `SKILL.md` file with a `## Tree` section that defines a named pipeline of steps and named ops (`ALL_CAPS` identifiers resolved from `references/ops.md` or `references/ops/<name>.md`).
Resources (rules, tables, checklists, schemas) live in typed category subdirectories under `assets/` and are loaded at point of use — keeping each context window small.

Framework source: https://github.com/kostiantyn-matsebora/claude-canopy

---

## How to invoke the Canopy agent

### Claude Code

The `/canopy` slash command is auto-registered from the `canopy` skill installed at `.claude/skills/canopy/`:

```
/canopy improve bump-version
/canopy validate review-backend
/canopy convert list-skills to canopy
/canopy create a skill that bumps the version and updates the changelog
```

Or just describe what you want in natural language — Claude will pick up the skill automatically when the request matches its description.

### GitHub Copilot

Same `/canopy` slash command from the skill installed at `.github/skills/canopy/`:

```
/canopy convert list-skills to canopy
```

Explicit form (always works):

```
Follow .github/skills/canopy/SKILL.md and validate review-backend
```

---

## How to use this agent

Invoke with a natural language request directed at the agent. Examples:

```
create a skill that bumps the version and updates the changelog
scaffold my-skill
convert release/SKILL.md to canopy
validate review-backend
improve review-api
help
```

The agent detects the intended operation from your words and loads only the procedure it needs.

---

## Operations

| Operation | What it does | Example invocation |
|-----------|-------------|-------------------|
| `CREATE` | Create a new Canopy skill from a description | `create a skill that ...` |
| `MODIFY` | Make targeted changes to an existing skill | `modify review-backend to also ...` |
| `SCAFFOLD` | Generate a blank skill skeleton with placeholder files | `scaffold my-new-skill` |
| `CONVERT_TO_CANOPY` | Convert a flat prose/numbered-steps skill to Canopy format | `convert release/SKILL.md to canopy` |
| `VALIDATE` | Check a skill for framework errors, warnings, and optimizations | `validate review-api` |
| `IMPROVE` | Fix violations, re-categorise misplaced resources, align with framework (and migrate legacy flat layout to the standard `scripts/`/`references/`/`assets/` layout if the user opts in) | `improve review-backend` |
| `ADVISE` | Answer a "how to" question about a skill — read-only, produces a plan | `how should I add a verify step to review-api?` |
| `REFACTOR_SKILLS` | Find ops/resources duplicated across > 2 skills and extract into a named, installable shared skill (with `compatibility` declarations on dependents) | `refactor skills` |
| `CONVERT_TO_REGULAR` | Flatten a Canopy skill into a plain agentskills.io skill (strips `## Tree`, `compatibility`, safety preamble) | `convert review-backend back to regular` |
| `ACTIVATE` | Write the canopy-runtime marker block to this project's `CLAUDE.md` / `.github/copilot-instructions.md`. Mostly redundant since canopy-runtime self-activates on first load; useful after version bumps or for forced re-activation. | `activate` |
| `HELP` | Show this reference | `help` or `what can you do?` |

---

## Skill anatomy (standard agentskills.io layout)

```
skill-name/
├── SKILL.md              ← only file at root; required (uppercase)
│   ├── --- frontmatter (name, description, compatibility, metadata)
│   ├── Safety preamble — runtime-required guard block
│   ├── Preamble — parse $ARGUMENTS
│   ├── ## Tree — execution pipeline (* list or box-drawing)
│   ├── ## Rules — skill-wide invariants
│   └── ## Response: — output format declaration
│
├── scripts/              ← executable code (.ps1, .sh)
├── references/           ← docs loaded on demand
│   ├── ops.md            ← named op definitions (simple skills)
│   └── ops/<name>.md     ← per-op definitions (complex skills)
└── assets/               ← static resources
    ├── templates/        ← fillable output documents
    ├── constants/        ← read-only lookup tables
    ├── schemas/          ← data shape definitions
    ├── checklists/       ← evaluation criteria (- [ ] items)
    ├── policies/         ← behavioural must/must-not rules
    └── verify/           ← expected-state checklists for VERIFY_EXPECTED
```

Op lookup order: `<skill>/references/ops.md` (or `references/ops/<name>.md`; legacy `ops.md` at root supported) → consumer-defined cross-skill ops (optional) → `canopy-runtime/references/framework-ops.md`

Older skills using a flat layout (category dirs at the skill root) continue to work — canopy-runtime resolves `Read` references literally. `/canopy improve` can migrate them to the standard layout on request.

## Compatibility & safety

Every skill with a `## Tree` section declares `compatibility` (canopy-runtime requirement) and includes a safety preamble at the top of the body that halts execution on agents without canopy-runtime. `/canopy create` and `/canopy scaffold` add both automatically.
