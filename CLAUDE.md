# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What Canopy Is

Canopy is a declarative framework for writing skills as **syntax trees of named operations**, distributed as [agentskills.io](https://agentskills.io)-format Agent Skills. A skill is a `SKILL.md` (uppercase, exact spelling) file with these sections:

1. **Frontmatter** — `name`, `description` (required); optional `license`, `compatibility`, `metadata`, `allowed-tools`. Non-spec fields like `argument-hint` and `user-invocable` go inside `metadata`.
2. **Safety preamble** — for canopy-flavored skills (any skill with `## Tree`); a runtime-required guard block at the top of the body that halts execution on agents without canopy-runtime
3. **`## Agent`** (optional) — declares an `**explore**` subagent; output contract is at `assets/schemas/explore-schema.json`
4. **`## Tree`** — sequential execution pipeline with `IF`/`ELSE_IF`/`ELSE`/`SWITCH`/`CASE`/`FOR_EACH` branching (markdown list `*` or box-drawing fenced block)
5. **`## Rules`** — skill-wide invariants
6. **`## Response:`** — output format declaration

## Repo Layout (v0.18.0+)

This repo ships three installable Agent Skills under `skills/`, split along authoring-vs-execution lines:

| Skill | Role | Notes |
|-------|------|-------|
| `canopy/` | **Authoring agent** — create / modify / validate / improve / scaffold / refactor / advise / convert Canopy skills. | Invokes as `/canopy`. Depends on `canopy-runtime`. Ops loaded via `SWITCH`/`CASE` dispatch. |
| `canopy-debug/` | **Trace wrapper** — run any canopy-flavored skill with phase banners + per-node tracing. | Invokes as `/canopy-debug <skill>`. |
| `canopy-runtime/` | **Execution engine** — interprets canopy-flavored skills. Self-activates on first load (writes the marker block to the active platform's instructions file). | Hidden from `/` menu (`metadata.user-invocable: "false"`). Loaded ambiently via `CLAUDE.md` / `.github/copilot-instructions.md`. Install this alone to just *execute* canopy skills without authoring. |

Each framework skill follows the standard agentskills.io layout introduced in v0.18.0:

```
skills/<name>/
├── SKILL.md              ← only file at root
├── scripts/              ← executable code
├── references/           ← docs loaded on demand
│   ├── ops.md            ← simple skills
│   └── ops/<name>.md     ← per-op definitions (canopy uses this)
└── assets/               ← static resources
    ├── templates/
    ├── constants/
    ├── schemas/
    ├── checklists/
    ├── policies/
    └── verify/
```

Plus:

- `.claude-plugin/plugin.json` — Claude Code plugin manifest (makes the whole repo installable as a plugin via `/plugin install canopy@claude-canopy`)
- `.claude-plugin/marketplace.json` — marketplace catalog (makes the repo a marketplace that users can add via `/plugin marketplace add kostiantyn-matsebora/claude-canopy`)
- `docs/` — `CONCEPTS.md`, `TERMINOLOGY.md`, `CHEATSHEET.md`, `GETTING_STARTED.md`, `VSCODE.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`, `reference/{index,FRAMEWORK_SPEC,PRIMITIVES,RUNTIMES}.md`. (`FRAMEWORK.md` and `AUTHORING.md` are stub redirects after the docs restructure.)
- `assets/` — logo / icon files referenced by docs
- `.canopy-version` — single-line version string (machine-readable)
- `LICENSE`

The repo is intentionally shaped so the SAME `skills/canopy/`, `skills/canopy-debug/`, and `skills/canopy-runtime/` directories serve all three install paths:
1. **Claude Code plugin** — `.claude-plugin/plugin.json` at repo root + `skills/<name>/SKILL.md` matches the Claude Code plugin layout. Skills become `/canopy:canopy`, `/canopy:canopy-debug` (plugin-namespaced; canopy-runtime is hidden).
2. **`gh skill install`** — reads `skills/*/SKILL.md` from the repo directly. Lands skills at `.claude/skills/<name>/`; slash commands are `/canopy` and `/canopy-debug` (no namespace).
3. **`install.sh` / `install.ps1`** — same placement as gh-skill-install PLUS writes a canopy-runtime marker block to `CLAUDE.md` or `.github/copilot-instructions.md` for ambient runtime activation.

Keep this single-source-of-truth property when adding skills: put them under `skills/<name>/` only. Don't create parallel copies.

**Authoring vs. execution split:** the `canopy` skill (authoring agent) depends on `canopy-runtime` (execution engine) via sibling-relative reads (`../canopy-runtime/references/...`). `canopy-runtime` is the minimum install: a consumer who only wants to *execute* existing canopy skills can install just `canopy-runtime` and skip `canopy`. The install script installs all three by default.

## agentskills.io Compliance Invariants

Every skill produced by `/canopy create` or `/canopy scaffold` enforces these invariants:

1. Skill file is exactly `SKILL.md` (uppercase) — case-sensitive filesystems require this exact name
2. Frontmatter root contains only spec-allowed fields (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`); `argument-hint`/`user-invocable` go inside `metadata`
3. Every `## Tree` skill has a `compatibility` field declaring canopy-runtime requirement
4. Every `## Tree` skill has a safety preamble guard block at the top of the body
5. Cross-skill shared logic (extracted via `/canopy refactor`) becomes a named, installable skill — never a bare shared file
6. canopy-runtime self-activates the first time an agent loads it — `/canopy activate` is mostly redundant since v0.18.0 (see "canopy-runtime activation" under Install / Distribute for who writes the marker block per install path)

`/canopy validate` and `/canopy improve` enforce these invariants on existing skills and gap-fix where missing.

## Op Lookup Order

When a tree node has an `ALL_CAPS` identifier, look up in this order:
1. `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` — skill-local. Backward-compatible fallback: `<skill>/ops.md` at root for legacy-layout skills.
2. Consumer-defined cross-skill ops (optional; consumers package these as their own skill — declared via `compatibility`)
3. `skills/canopy-runtime/references/framework-ops.md` — framework primitives (`IF`, `ELSE_IF`, `ELSE`, `SWITCH`, `CASE`, `DEFAULT`, `FOR_EACH`, `BREAK`, `END`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`)

Primitives are never overridden.

## Tree Notation

`<<` = input, `>>` = output/displayed fields, `|` = separator between options or fields.

```
skill-name
├── OP_NAME << input >> output
├── ASK << Proceed? | Yes | No
├── IF << condition
│   └── branch-op or natural language
└── ELSE
    └── other action
```

## Standard Layout (v0.18.0+)

Each skill aligns with the agentskills.io standard:

| Path | Behavior |
|------|----------|
| `SKILL.md` | required, uppercase, only file at skill root |
| `scripts/` | executable code (`.ps1`, `.sh`) — invoked via named sections (`# === Section Name ===`) |
| `references/ops.md` or `references/ops/<name>.md` | skill-local op definitions |
| `references/<other>.md` | supporting documentation loaded on demand |
| `assets/templates/` | fillable output documents with `<token>` placeholders |
| `assets/constants/` | read-only lookup data (mapping tables, enum-like value lists) |
| `assets/schemas/` | structure definitions (subagent contracts, data shapes) |
| `assets/checklists/` | evaluation criteria lists (`- [ ] ...`) |
| `assets/policies/` | behavioural constraints |
| `assets/verify/` | post-execution expected-state checklists for `VERIFY_EXPECTED` |

Reference pattern in SKILL.md: `Read \`<category-path>/<file>\` for <brief description>.` — load at point of use, not front-loaded.

## Backward compatibility

Older skills using a flat layout (category dirs at the skill root: `schemas/`, `templates/`, `commands/`, etc.) continue to execute correctly — canopy-runtime follows `Read` references literally. `/canopy improve` can migrate them to the standard layout on user opt-in.

## Key Files

- `docs/reference/FRAMEWORK_SPEC.md` — canonical framework specification (single source of truth for non-runtime spec material)
- `docs/reference/PRIMITIVES.md` — auto-mirrored from `skills/canopy-runtime/references/framework-ops.md`. Do NOT edit directly — edit the canonical file under `skills/canopy-runtime/references/` and run `python scripts/sync-runtime-docs.py`.
- `docs/reference/RUNTIMES.md` — auto-mirrored from `skills/canopy-runtime/references/runtime-{claude,copilot}.md`. Same edit rule as PRIMITIVES.md.
- `docs/CONCEPTS.md` — model/narrative walkthrough (skill anatomy, `## Agent` patterns, ops, execution model, runtime/authoring split, agentskills.io alignment)

**canopy (authoring agent):**
- `skills/canopy/SKILL.md` — agent body: loads canopy-runtime spec up-front (sibling-relative `../canopy-runtime/...`), then dispatches deterministically to one of 11 ops via `SWITCH/CASE`
- `skills/canopy/references/ops/` — per-operation procedure files (create, modify, scaffold, validate, improve, advise, refactor-skills, convert-to-canopy, convert-to-regular, activate, help, fetch-dispatch-context)
- `skills/canopy/assets/policies/authoring-rules.md` — skill structure, frontmatter compliance, compatibility/preamble requirements, writing style, op naming, subagent contract, debug meta-skill
- `skills/canopy/assets/policies/category-decision-flowchart.md` · `platform-targeting.md` · `preservation-rules.md` · `conversion-expansion-rules.md`
- `skills/canopy/assets/constants/` — lookup tables for authoring ops (category dirs, control flow notation, operation detection, dispatch map, validation checks, marker block)
- `skills/canopy/assets/schemas/dispatch-schema.json` — output contract for canopy's intent-classification subagent (includes `repo_context` field)
- `skills/canopy/assets/schemas/explore-schema.json` — sample output for skill-analysis explore subagents
- `skills/canopy/assets/templates/skill.md` and `ops.md` — skeletons used by SCAFFOLD (skeleton includes compatibility + safety preamble)
- `skills/canopy/assets/verify/` — expected-state checklists per authoring op

**canopy-runtime (execution engine):**
- `skills/canopy-runtime/SKILL.md` — overview + platform detection + Activation section (self-activating marker-block writer) + pointers to references/
- `skills/canopy-runtime/references/framework-ops.md` — immutable framework primitives (spec)
- `skills/canopy-runtime/references/runtime-claude.md` — Claude Code runtime rules (base paths, native subagents, invocation forms)
- `skills/canopy-runtime/references/runtime-copilot.md` — GitHub Copilot runtime rules (inline subagent fallback, `.github/` paths, invocation forms)
- `skills/canopy-runtime/references/skill-resources.md` — category behavior, op lookup chain, tree format, explore subagent contract, safety preamble (shared framework spec)

**canopy-debug (trace wrapper):**
- `skills/canopy-debug/SKILL.md` — loads canopy-runtime spec up-front, then wraps a target skill with `EXECUTE_WITH_TRACE`
- `skills/canopy-debug/references/ops.md` — trace ops (EMIT_PHASE_BANNER, EXECUTE_WITH_TRACE, TRACE_NODE, etc.)
- `skills/canopy-debug/assets/policies/debug-output.md` — rendering protocol

## Install / Distribute

Three install paths supported:

1. **Claude Code plugin marketplace** — inside Claude Code: `/plugin marketplace add kostiantyn-matsebora/claude-canopy` then `/plugin install canopy@claude-canopy`. Bundles all three skills. No external CLI required.
2. **`gh skill`** ([GitHub CLI v2.90.0+](https://cli.github.com/manual/gh_skill_install)) — `gh skill install kostiantyn-matsebora/claude-canopy <skill> --agent claude-code|github-copilot --scope project --pin vX.Y.Z`. `--agent` chooses `.claude/skills/<skill>/` or `.github/skills/<skill>/`.
3. **Install script** — `install.sh` / `install.ps1` at repo root. Consumers fetch via `curl | bash` or `irm | iex`. Resolves version from `--ref` / `--version` flag → `.canopy-version` → latest release. Installs all three skills AND idempotently writes the canopy-runtime marker block to `CLAUDE.md` / `.github/copilot-instructions.md` (per `--target`). Supports `--ref <branch|tag|SHA>` for pre-release testing; `--ref` installs do NOT write `.canopy-version`.

### canopy-runtime activation (v0.18.0+)

The runtime's `## Activation` section writes the canopy-runtime marker block to the active platform's instructions file. Replaces the explicit `/canopy:canopy activate` step.

- **Who writes the marker block, by install path:**
  - `install.sh` / `install.ps1` — the script writes it during install. Shell-context, no agent to defer to → project is fully activated when install completes.
  - `gh skill install` — file placement only. Marker block is written by the next agent invocation that loads `canopy-runtime/SKILL.md` and runs Activation.
  - Claude Code plugin marketplace — same as `gh skill install`: file placement only; agent writes the block on first load.
- **Activation is agent-mediated** for the latter two paths. Pure CLI install (no agent following) leaves the marker block unwritten until an agent next loads the runtime.
- **Idempotent** — running Activation on a fully activated project is a no-op. CREATE if absent, APPEND if no markers, REPLACE if exactly one marker pair, WARN on multiple, REFUSE on mismatched.

## Contributing Rules

When modifying any of these, keep all in sync:
- `docs/reference/FRAMEWORK_SPEC.md` — non-runtime spec content (skill anatomy, frontmatter rules, tree execution model, op-lookup order, category dirs, activation, debug mode)
- `skills/canopy-runtime/references/skill-resources.md` — category semantics, op lookup chain, tree format, subagent contract, safety preamble
- `skills/canopy-runtime/references/framework-ops.md` — primitive definitions (canonical for `docs/reference/PRIMITIVES.md`)
- `skills/canopy-runtime/references/runtime-{claude,copilot}.md` — per-platform runtime rules (canonical for `docs/reference/RUNTIMES.md`)
- `skills/canopy/assets/policies/` — update the relevant policy file(s)
- `skills/canopy/assets/constants/` — update enumerations (e.g. `validate-checks.md` primitive list, `control-flow-notation.md` migration table) when the framework gains a new primitive, section, or convention
- `skills/canopy/references/ops/` — update the authoring ops so `/canopy create`, `/canopy improve`, `/canopy advise`, `/canopy convert-to-canopy`, `/canopy validate`, `/canopy scaffold`, etc. **know about the new feature**. Otherwise authors using the framework via the agent will never be guided toward it.

**Authoring-ops awareness.** Every framework change that adds capability (new primitive, new section type, new dispatch mode, new convention) must be reflected in `skills/canopy/references/ops/` and `skills/canopy/assets/constants/` so the agent-driven authoring path (`/canopy create`/`improve`/`advise`/`convert-to-canopy`/`validate`/`scaffold`) knows about it. See `.claude/rules/authoring-ops-sync.md` for the per-feature-category checklist (which authoring files to touch for which kind of framework change) and the rationale for the rule.

**After editing any `skills/canopy-runtime/references/{framework-ops,runtime-claude,runtime-copilot}.md`**, run `python scripts/sync-runtime-docs.py` to regenerate `docs/reference/{PRIMITIVES,RUNTIMES}.md`. CI fails the build if you forget — `ci.yml` runs the script in `--check` mode.

When the marker block content changes, update all four sources of truth simultaneously:
- `skills/canopy-runtime/assets/constants/marker-block.md` (canonical home — runtime is self-contained for activation)
- `install.sh` `build_marker_block()`
- `install.ps1` `Build-MarkerBlock`
- VSCode extension's marker-block constant in `claude-canopy-vscode/src/commands/installCanopy.ts`

After any change to skill or op behavior, check that `skills/canopy-runtime/references/runtime-claude.md`, `runtime-copilot.md`, and `docs/CONCEPTS.md` still accurately describe current behavior. Update stale content before the work is considered done.

Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`).

## Versioning & release

The version string lives in **four places** that must stay in sync:
1. `.canopy-version`
2. `.claude-plugin/plugin.json` → `version`
3. `.claude-plugin/marketplace.json` → `metadata.version` AND `plugins[0].version`
4. The git tag `vX.Y.Z`

Use the `/bump-version X.Y.Z` skill (at `.claude/skills/bump-version/`) to update all four + draft a `docs/CHANGELOG.md` entry + create the local tag in one step. The skill never pushes; pushing is deliberate and manual:

```bash
git push origin master vX.Y.Z
```

Pushing a `v*` tag fires `.github/workflows/release.yml`, which extracts the matching `## [X.Y.Z] — …` block from `docs/CHANGELOG.md` and creates a GitHub Release with those notes. The git tag is also the install artifact for `gh skill install --pin vX.Y.Z` and for `/plugin install canopy@claude-canopy` (which picks up `plugin.json`'s `version`).

## Writing style — structured, not stream-of-consciousness

**Applies to every change you author in this repo and any repo it produces** — no surface is exempt:

- Docs (`docs/*.md`, `README.md`, `CONTRIBUTING.md`, `CLAUDE.md`)
- CHANGELOG entries
- Commit message bodies and PR descriptions
- GitHub Release notes (drafted from CHANGELOG; same rule applies)
- Status updates, summaries, and replies you write back to the user during a session
- **Skill content** — `SKILL.md` (preamble, tree nodes, `## Rules`, `## Response:` lines, the description in frontmatter), `references/ops.md` and `references/ops/*.md` (op signatures and bodies), `references/*.md` (supporting docs), `assets/policies/*.md`, `assets/constants/*.md`, `assets/checklists/*.md`, `assets/verify/*.md`, anything else inside a skill

A reader should grok the shape in one pass.

- **Lead with the claim, then break out the details.** No multi-clause prose paragraphs that bury the point.
- **Bullets, not run-on sentences.** Anything joined by `;` `—` `and also` `additionally` is a candidate for splitting.
- **Label the bullets.** `**Who writes the marker block:**`, `**By install path:**`, `**Idempotent —**` — short bold labels at the front of each bullet so the eye finds the relevant one fast.
- **Tables for matrices.** When information has two axes (e.g. install path × who writes the marker block), use a table or a labeled bulleted list. Never inline a 3-way comparison in prose.
- **Cross-reference instead of restating.** If the same content lives in two places, the second reference should link/point to the first, not repeat.
- **Consistent verb mood.** Imperative for instructions ("Write the marker block"), declarative for spec ("The marker block is written by…"). Don't mix within a single block.

Anti-pattern (mindflow):

> canopy-runtime self-activation: SKILL.md now includes an Activation section that writes the marker block to CLAUDE.md (Claude Code) or .github/copilot-instructions.md (Copilot) the first time an agent loads the runtime SKILL.md — no human /canopy:canopy activate needed. Note: this is agent-driven, not install-tool-driven. Pure CLI install paths (gh skill install, plugin marketplace) only place files; the marker block is written when the next agent invocation loads the runtime. install.sh/install.ps1 additionally write the marker block during install (shell-context scripts have no agent to defer to), so those paths leave the project fully activated.

Structured replacement:

> **canopy-runtime self-activation.** Replaces explicit `/canopy:canopy activate`.
>
> **Who writes the marker block, by install path:**
> - `install.sh` / `install.ps1` — script writes it during install. Project is fully activated when install completes.
> - `gh skill install` — file placement only. Block is written by the next agent invocation that loads `canopy-runtime/SKILL.md`.
> - Plugin marketplace — same as `gh skill install`.
>
> **Idempotent.** Running on a fully activated project is a no-op.

Apply this rule when authoring or editing any markdown in this repo. When you catch existing content that violates it, restructure it as part of your change.

## SKILL.md Constraints

`SKILL.md` must contain **only** orchestration — no tables, JSON/YAML blocks, scripts, inline examples, or templates. Structured content belongs in category subdirectories. See `skills/canopy/assets/policies/authoring-rules.md` for the full rule set.

## Platform Compatibility

Canopy must remain fully compatible with **both** Claude Code and **GitHub Copilot**.

- Every change to skills, ops, or policies must be verified against both platforms before the work is considered done.
- If a construct works on one platform but not the other, it must be reworked until it passes on both, or the incompatibility must be explicitly documented with a rationale.
