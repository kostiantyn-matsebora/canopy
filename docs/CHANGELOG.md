---
title: Changelog
nav_order: 5
description: "All notable changes to Canopy."
no_toc: true
---

<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to Canopy are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.19.0] — 2026-05-08

### Added

- **`PARALLEL` block primitive** — heterogeneous parallel-subagent fan-out as a real grammar element. `PARALLEL` takes no input and accepts ≥2 indented children; each child runs in its own context window. Defined in `skills/canopy-runtime/references/framework-ops.md` (mirrored to `docs/reference/PRIMITIVES.md`); platform emission rules in `runtime-claude.md` (multi-`Task` in one assistant turn) and `runtime-copilot.md` (fleet subtask / `@CUSTOM-AGENT-NAME` / sequential inline fallback). Failure semantics: `Promise.allSettled` — sibling failures don't abort. Backward-compatible: prose fan-out continues to work as the dynamic-shape escape hatch.

### Changed

- **Authoring agent now recognizes `PARALLEL` as a structural target.** `/canopy improve` flags prose-fan-out patterns and proposes `PARALLEL`-block migration alongside existing primitive-migration suggestions. `/canopy convert-to-canopy` maps "spawn N in parallel" prose to `PARALLEL` blocks during conversion. `/canopy advise` recommends `PARALLEL` when a skill has ≥2 sequential `## Agent` invocations with no data dependency between them.
- **Marker-block** updated in all framework sources (`marker-block.md`, `install.sh`, `install.ps1`) to list `PARALLEL` in the control-flow primitives. The vscode-extension mirror (`claude-canopy-vscode/src/commands/installCanopy.ts`) is updated separately in extension v0.12.0; parity check passes once both PRs land.
- **Spec narrative docs** (`CONCEPTS.md`, `FRAMEWORK_SPEC.md` Tree Execution Model + Op Lookup Order) extended to enumerate `PARALLEL` alongside existing primitives.

### Notes

- This is the **Tier 1 / S1** step from the parallel-subagent design ideation. S2 (`## Agents` + `SPAWN` per-subagent schema declarations) and S3 (`PARALLEL_FOR_EACH` data-parallel iterator) are deferred — escalate only if real skills demonstrate Tier 1 isn't enough.
- No behavioral break: every existing skill continues to parse and run unchanged.

---

## [0.18.1] — 2026-04-30

### Fixed

- **`scripts/validate.sh` safety-preamble check**: regex now matches the canonical period form (`> **Runtime required.**`); previously required a colon (`> **Runtime required:**`), which no actual template, policy, op, or `SKILL.md` in the repo uses — only the validator and one stray spot in `docs/README.md`. Result: post-merge CI on master flagged spec-compliant skills (including the bundled `canopy` and `canopy-debug`) as missing the preamble.

### Notes — release integrity

- **Tags are now SSH-signed.** Verify with `git verify-tag v0.18.1`. The local clone has `tag.gpgsign true` set; the public key is registered as a Signing Key on GitHub.
- **SLSA build provenance** is attached to every release. `release.yml` now uses `actions/attest-build-provenance@v2` to produce a Sigstore-signed provenance record over the install tarball (`canopy-${VERSION}.tar.gz`), each `SKILL.md`, and both plugin manifests. Verify with `gh attestation verify canopy-0.18.1.tar.gz --owner kostiantyn-matsebora`.
- **Install tarball** is now uploaded as a release asset. Same install surface as `gh skill install` / plugin marketplace, just packaged for offline / scripted consumption.
- **`SECURITY.md`** added at the repo root (private vulnerability reporting, supported versions, integrity-verification snippet, in-scope / out-of-scope list). Auto-surfaces on the repo's Security tab.
- **`master` branch protection enabled**: PR required, status check `validate` must pass, no force pushes, no deletions, linear history, conversation resolution required, admin enforcement on (no bypass).
- **Docs site published** at <https://kostiantyn-matsebora.github.io/claude-canopy/> — full reference rendered with cayman theme, dark/light toggle, and per-section TOC.

No skill behavior changes from 0.18.0; this is a patch release for repo hygiene + verifiable supply-chain.

---

## [0.18.0] — 2026-04-29

### Added

- **agentskills.io standard layout**: framework skills migrated to the spec-aligned layout — only `SKILL.md` at the root, with `scripts/` (executable code), `references/` (docs loaded on demand, including `ops.md` / `ops/`), and `assets/` (static resources: `templates/`, `constants/`, `schemas/`, `checklists/`, `policies/`, `verify/`). Old flat layout (category dirs at the skill root) remains fully supported by canopy-runtime — `Read` references resolve literally. `/canopy improve` can migrate legacy skills on user opt-in.
- **`compatibility` field on every `## Tree` skill**: spec-compliant free-text declaring the canopy-runtime requirement and its source repo, listing install tools as alternatives (`gh skill install`, `git clone`, `install.sh`/`install.ps1`, plugin marketplace) so the agent picks the install method its environment supports. Per agentskills.io spec, `compatibility` is a max-500-char string — structured shapes like `compatibility: { requires: [...] }` are non-spec and rejected by `/canopy validate` / migrated by `/canopy improve`. Authoring ops (`CREATE`, `SCAFFOLD`, `CONVERT_TO_CANOPY`, `MODIFY`) emit the canonical free-text form automatically.
- **Safety preamble** on every `## Tree` skill: a fail-fast guard block at the top of the body that halts execution on agents without canopy-runtime active. Prevents silent wrong execution on unsupported platforms.
- **canopy-runtime self-activation**: `canopy-runtime/SKILL.md` now includes an Activation section that writes the marker block to `CLAUDE.md` (Claude Code) or `.github/copilot-instructions.md` (Copilot). Replaces the explicit `/canopy:canopy activate` step for all install paths.
  - **Who writes the marker block, by install path:**
    - `install.sh` / `install.ps1` — the script writes it during install. Shell-context, no agent to defer to → project is fully activated when install completes.
    - `gh skill install` — file placement only. Marker block is written by the next agent invocation that loads `canopy-runtime/SKILL.md` and runs Activation.
    - Claude Code plugin marketplace — same as `gh skill install`: file placement only; agent writes the block on first load.
  - **Idempotent** — running Activation on a fully activated project is a no-op.
- **Repo context detection**: `CREATE` and `SCAFFOLD` choose the target skill location based on `context.repo_context` — distribution repos (`skills/` at root) get skills written to `skills/<name>/`; consumer projects get them in `.claude/skills/<name>/` or `.github/skills/<name>/`.
- **Cross-skill extraction constraint**: `REFACTOR_SKILLS` now requires extracted shared logic to become a complete, named, installable skill (with its own `SKILL.md`, `compatibility` field, and safety preamble); dependent skills declare it via `compatibility`. No more bare shared files referenced from sibling directories — preserves agentskills.io skill autonomy.
- **`SKILL.md` uppercase enforcement**: `validate.sh` and `/canopy validate` flag lowercase `skill.md` files. Required for case-sensitive filesystems (Linux, macOS APFS) and for `gh skill install` discovery.
- **Frontmatter compliance enforcement**: `argument-hint` and `user-invocable` are non-spec at frontmatter root and must live inside `metadata`. `validate.sh` rejects root-level placement.
- **Cross-client install target** (agentskills.io spec): a single install at `.agents/skills/` serves both Claude Code and GitHub Copilot. canopy-runtime self-identifies the active host at runtime and applies the matching runtime spec (`runtime-claude.md` or `runtime-copilot.md`) — no path-derived platform detection. Cross-client is **additive**; existing `claude` / `copilot` / `both` install targets are preserved.
  - `install.sh --target agents` and `install.ps1 -Target agents` install to `.agents/skills/`. Marker block goes to whichever instructions file already exists (`CLAUDE.md` and/or `.github/copilot-instructions.md`); `CLAUDE.md` is created as fallback.
  - `gh skill install ... --dir .agents/skills` is the equivalent path for the gh-CLI flow. Newer `gh` (2.91+) defaults Copilot installs to `.agents/skills/` automatically.
  - VSCode extension's install commands include a **Cross-client** pick alongside Claude Code, Copilot, and Both, in both the install-script and gh-skill flows.
- **Skills-root resolution** in canopy-runtime: `<skills-root>` is the first matching directory containing `canopy-runtime/SKILL.md`. Recognized roots, in order: `.agents/skills/` → `.claude/skills/` → `.github/skills/`. `dispatch-schema.json`'s `explicit_target_platform` enum gains `cross-client`.

### Changed

- `commands/` directory renamed → `scripts/` (matches agentskills.io standard).
- `ops.md` and `ops/` moved under `references/` (as documentation loaded on demand, per the agentskills.io progressive-disclosure pattern).
- All static resource directories (`schemas/`, `templates/`, `constants/`, `checklists/`, `policies/`, `verify/`) moved under `assets/`.
- `IMPROVE` op extended with agentskills.io compliance checks: missing `compatibility`, missing safety preamble, root-level `argument-hint`/`user-invocable`, lowercase `skill.md`, structured-object `compatibility` (migrated to spec-compliant free-text). Optionally migrates legacy flat layout to the standard layout.
- `CONVERT_TO_REGULAR` op now strips `compatibility` field and safety preamble (regular agentskills.io skills don't require them).
- canopy-runtime category-directory documentation updated for new layout in `skill-resources.md`, `framework-ops.md`, `runtime-claude.md`, `runtime-copilot.md`.
- canopy-runtime platform detection moved from path-derived to runtime self-identification — the agent identifies itself (Claude Code / Copilot / other) instead of inferring from the skills-root path. `runtime-claude.md` and `runtime-copilot.md` use the abstract `<skills-root>` placeholder so both specs work regardless of install location.
- Marker block content restructured as bulleted (with nested) lists for readability and updated to mention all three skills roots. CI parity check across `marker-block.md`, `install.sh`, `install.ps1`, and the vscode extension's `MARKER_BLOCK` constant still enforced.
- Marker block canonical file moved from `skills/canopy/assets/constants/marker-block.md` to `skills/canopy-runtime/assets/constants/marker-block.md`. Reason: `gh skill install canopy-runtime` does not transitively pull `canopy`; the runtime must be self-contained for activation. Authoring ops (`/canopy activate`) cross-reference the new location via `../canopy-runtime/...`.

### Notes

- **Not a breaking change**: existing consumer skills using the legacy flat layout continue to execute correctly. canopy-runtime resolves `Read` references literally; old skills don't need migration. Existing `--target claude` / `copilot` / `both` install flows unchanged. Cross-client is purely additive.
- VSCode extension `claude-canopy-vscode` updated in lockstep — language ID file patterns rewritten for new layout (`commands/*.{ps1,sh}` → `scripts/*.{ps1,sh}`; `templates/*` → `assets/templates/*`; etc.) AND extended to also recognize `.agents/skills/` paths. Diagnostics flag old-layout skills with a "consider migrating" hint.

---

## [0.17.1] — 2026-04-25

### Added

- **`ACTIVATE` op** (`/canopy:canopy activate` or `/canopy activate`): writes the canopy-runtime marker block to the current project's `CLAUDE.md` and/or `.github/copilot-instructions.md`. Closes the runtime-activation gap for the two install paths that don't write the block automatically — `/plugin install canopy@claude-canopy` and manual `gh skill install`. Fully idempotent: same write contract as `install.sh write_marker_block()` (create / append / replace / unchanged / refuse-on-malformed). Run once per project after a plugin or gh-skill install; user-authored canopy skills under `.claude/skills/` / `.github/skills/` then load runtime ambiently. Detection phrases: `activate`, `activate runtime`, `wire up runtime`, `install runtime`, `write marker block`, `ambient activation`, `runtime not loading`.
- **`skills/canopy/constants/marker-block.md`**: canonical source of the marker block content + the idempotent write contract. Documented as needing to stay byte-identical with `install.sh build_marker_block()` and `install.ps1 Build-MarkerBlock`.

### Notes

- Existing install paths are unchanged. Users who installed via `install.sh` / `install.ps1` (or via the vscode extension's `installAsAgentSkill`) already have the block — running ACTIVATE on those projects is a safe no-op.

---

## [0.17.0] — 2026-04-24

### Changed (BREAKING)

- **Distribution shape**: Canopy is now a set of [agentskills.io](https://agentskills.io)-format Agent Skills, not a git subtree + setup-script bundle. Ships as **three** skills split along authoring-vs-execution lines:
  - **`canopy-runtime`** — execution engine. Platform detection, primitives spec, op lookup chain, category semantics, subagent contract, per-platform runtime rules. Hidden from `/` menu. Loaded ambiently via `CLAUDE.md` / `.github/copilot-instructions.md` (install script writes a marker block). **Install this alone to execute existing canopy skills.**
  - **`canopy`** — authoring agent. Create/modify/validate/improve/scaffold/refactor/advise/convert skills. Depends on `canopy-runtime`.
  - **`canopy-debug`** — trace wrapper. `/canopy-debug <skill>` emits phase banners and node traces.
- **Claude Code plugin support**: Added `.claude-plugin/plugin.json` (plugin manifest) and `.claude-plugin/marketplace.json` (marketplace catalog) at repo root. The whole repo now doubles as a Claude Code plugin AND a self-hosting marketplace. `/plugin install canopy@claude-canopy` bundles all three skills. The `skills/` directory serves all three install paths (plugin, gh skill, install script) from one source of truth.
- **`install.sh` / `install.ps1`**: idempotent installer scripts at repo root, callable via `curl | bash` or `irm | iex`. Install all three skills AND idempotently write a marker-delimited `canopy-runtime` block to `CLAUDE.md` / `.github/copilot-instructions.md` for ambient runtime activation. Resolution order: `--ref` (git branch/tag/SHA; transient) → `--version` → `.canopy-version` → latest release. Writes `.canopy-version` on version-pinned installs; skips it for `--ref` installs. Platform-agnostic: `--target claude|copilot|both`.
- **`gh skill install`**: `gh skill install kostiantyn-matsebora/claude-canopy <skill> --agent claude-code|github-copilot --scope project --pin v0.17.0` installs individual skills. Requires GitHub CLI v2.90.0+. Does NOT write ambient instruction files (use the install script if you want deterministic runtime activation).
- **The agent is now a skill**: the canopy agent (formerly `agents/canopy.md` + `agents/canopy/<resource-dirs>/`) was consolidated into `skills/canopy/SKILL.md` plus its existing resource subdirectories. agentskills.io skills auto-register `/<skill-name>` slash commands, so no wrapper skill is needed.
- **Runtime/spec extracted to `canopy-runtime`**: `framework-ops.md` (primitives), `skill-resources.md` (category semantics, op lookup, tree format, subagent contract), `runtime-claude.md` and `runtime-copilot.md` (platform-specific rules) live in `skills/canopy-runtime/references/`. The canopy authoring agent reads them via sibling-relative path (`../canopy-runtime/references/...`). Minimum install = canopy-runtime alone.
- **Ambient runtime activation**: user-authored canopy skills stay runtime-unaware. The install script writes a marker-delimited canopy-runtime block to the platform's ambient instruction file. Re-runs idempotently update the block. Recognition trigger: presence of `## Tree` in any SKILL.md under `.claude/skills/` or `.github/skills/`.
- **`canopy-debug`**: file rename to uppercase `SKILL.md`; frontmatter updated to agentskills.io spec; tree gains up-front platform-branched Reads of `../canopy-runtime/SKILL.md` + references for formal runtime adherence during tracing.
- **User skill files**: the spec uses `SKILL.md` (uppercase). All canopy resource files now reference `SKILL.md` instead of `skill.md`.
- **Cross-skill ops**: `skills/shared/project/ops.md` is no longer a built-in concept. Consumers who want shared cross-skill ops author their own skill (e.g. a `project-ops` skill) and reference it explicitly. `REFACTOR_SKILLS` now asks where to extract.

### Removed

- `agents/` directory — consolidated into `skills/canopy/`.
- `runtimes/` directory — moved to `skills/canopy-runtime/references/`.
- `rules/` directory — moved to `skills/canopy-runtime/references/`.
- `skills/shared/` directory (framework/, project/, top-level ops.md stub).
- `skills/canopy-help/` — redundant; HELP op inside canopy covers it (`/canopy help`).
- Old `setup.sh` / `setup.ps1` — replaced by the new install scripts at repo root.

### Migration guide

Consumer repos:

```bash
# Remove the subtree
git rm -r .claude/canopy

# Install all three skills + ambient runtime wiring (recommended)
curl -sSL https://raw.githubusercontent.com/kostiantyn-matsebora/claude-canopy/master/install.sh \
  | bash -s -- --target claude --pin v0.17.0    # or --target both for Claude+Copilot

# Alternative: gh skill (no ambient-file write)
gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code --scope project --pin v0.17.0
gh skill install kostiantyn-matsebora/claude-canopy canopy         --agent claude-code --scope project --pin v0.17.0
gh skill install kostiantyn-matsebora/claude-canopy canopy-debug   --agent claude-code --scope project --pin v0.17.0
```

User-authored skills under `.claude/skills/` keep working with no changes — ambient canopy-runtime activation via `CLAUDE.md` provides the interpretation rules; skills themselves stay runtime-unaware.

## [0.16.0] — 2026-04-22

### Added

- `install.sh` / `install.ps1` and `setup.sh` / `setup.ps1` now accept `--target claude|copilot` (`-Target` on PowerShell) to wire either `.claude/` or `.github/` on a fresh install. Previously the scripts were Claude-only despite the framework's dual-platform compatibility rule.
- Copilot target: canopy source is placed at `.github/canopy/`; skills and agents are linked under `.github/skills/` and `.github/agents/`; a marker-delimited `## Canopy Skill Resources` section is appended to `.github/copilot-instructions.md` (Copilot has no glob-based ambient rules, so the Claude-flavored `rules/skill-resources.md` isn't created).
- README Quick Start: dedicated Copilot invocation line for each installer.

### Changed

- Setup scripts now emit `$BASE`-aware paths in both `shared/ops.md` stubs and the "Next steps" output, so Copilot users see `.github/...` paths instead of `.claude/...`.

## [0.15.0] — 2026-04-21

### Added

- `agents/canopy/policies/authoring-rules.md` — consolidated policy file merging five prior files (`skill-structure-rules.md`, `writing-rules.md`, `op-naming-rules.md`, `subagent-rules.md`, `debug-rules.md`). VALIDATE now loads one policy file instead of four.
- `agents/canopy/constants/validate-checks.md` — extracted the Error/Warning/Optimization check catalog out of `ops/validate.md` (was ~30 inline lines). `validate.md` shrinks from 61 → 15 lines.
- `agents/canopy/constants/apply-block-protocol.md` — single definition of the fenced `apply` block format and re-invocation rule. 7 ops (CREATE, MODIFY, IMPROVE, SCAFFOLD, REFACTOR_SKILLS, CONVERT_TO_CANOPY, CONVERT_TO_REGULAR) now reference the protocol instead of each repeating ~10 lines of boilerplate.
- `agents/canopy/constants/platform-detection.md` — `.claude/` → `claude`, `.github/` → `copilot` mapping; previously inlined in `agents/canopy.md` `## Agent` body.
- `agents/canopy/constants/target-platform-triggers.md` — trigger-phrase lookup ("for copilot", "as claude", etc.); previously inlined.
- `agents/canopy/ops/fetch-dispatch-context.md` — tree-form op implementing the canopy agent's dispatch context resolution (intent classification, platform detection, target-platform resolution, skill extraction, extra context).
- `agents/canopy/policies/authoring-rules.md` — new "`## Agent` body shape" section with three canonical shapes (A: minimal / B: sub-task bullets / C: op reference), must-not list, and multi-concern MUST rule.
- `agents/canopy/constants/validate-checks.md` — two new Errors (inline mapping/enumeration in `## Agent`, inline quoted examples in `## Agent`) and two new Warnings (schema-field lists in `## Agent`, multi-concern prose in `## Agent`).

### Changed

- `agents/canopy.md` — `## Agent` body reduced from ~6-line prose paragraph (inlining mapping, examples, and schema-field list) to a single shape (C) line: `**explore** — execute FETCH_DISPATCH_CONTEXT. Output contract: schemas/dispatch-schema.json.`
- `agents/canopy/ops/validate.md` — reads `policies/authoring-rules.md` (single file) instead of four separate policy files; reads `constants/validate-checks.md` for the check catalog.
- `agents/canopy/ops/create.md`, `convert-to-canopy.md` — references updated from `skill-structure-rules.md` / `writing-rules.md` to `authoring-rules.md`.
- `agents/canopy/ops/create.md`, `modify.md`, `improve.md`, `scaffold.md`, `refactor-skills.md`, `convert-to-canopy.md`, `convert-to-regular.md` — apply-block boilerplate replaced with single-line reference to `constants/apply-block-protocol.md`.
- `agents/canopy/constants/operations-dispatch.md` — absolute `.github/agents/canopy/ops/…` paths replaced with paths relative to the agent directory (`ops/…`). Fixes Claude Code dispatch — previously only worked on Copilot.
- `agents/canopy/policies/authoring-rules.md` "Subagent contract" — runtime fallback behavior removed (was duplicated with `runtimes/copilot.md`); replaced with cross-reference to runtime specs.
- `agents/canopy/schemas/explore-schema.json` — example `existing_resources` entry updated from `policies/writing-rules.md` to `policies/authoring-rules.md`.
- `runtimes/claude.md`, `runtimes/copilot.md` — added op-resolution rule for `## Agent` shape (C): `**explore** — execute NAMED_OP` is resolved via the standard op lookup chain and the op body is injected as the subagent's task (or inlined on Copilot).
- `agents/canopy/ops/scaffold.md` — scaffolded `skill.md` template now includes an optional commented-out `## Agent` stanza with pointer to `policies/authoring-rules.md` for shape selection.
- `docs/AUTHORING.md` — trimmed from 262 → ~170 lines by replacing duplicated tables/sections (notation, framework primitives, category directories, op lookup order) with links to the corresponding FRAMEWORK.md anchors; `## Agent` subsection rewritten with three canonical shapes.
- `docs/FRAMEWORK.md` — Skill Anatomy section cross-references AUTHORING.md's three `## Agent` shapes; directory-layout comment updated to reflect new policy filenames.
- `docs/CHEATSHEET.md` — added `## Agent body shapes` quick-reference table.
- `docs/CONTRIBUTING.md` — sync-required file list references `authoring-rules.md` instead of the deleted `optimization-rules.md`.
- `CLAUDE.md` — `agents/canopy/policies/` description updated to list current policy filenames.
- `skills/canopy-help/SKILL.md` — added platform detection branch; previously hardcoded only `.github/` paths so was Copilot-only.
- `setup.sh`, `setup.ps1` — generated `skill-resources.md` now includes `checklists/` row in the category table (was missing).
- VS Code extension `src/commands/setupCanopy.ts` — `SKILL_RESOURCES_COPY` and `SKILL_RESOURCES_COPILOT` templates now include `checklists/` in the category table and `SWITCH`, `CASE`, `DEFAULT`, `FOR_EACH` in the primitives list.

### Removed

- `agents/canopy/policies/skill-structure-rules.md`, `writing-rules.md`, `op-naming-rules.md`, `subagent-rules.md`, `debug-rules.md` — consolidated into `authoring-rules.md`.
- `agents/canopy/policies/optimization-rules.md` — was a dead index file pointing at the files now merged into `authoring-rules.md`.

---

## [0.14.0] — 2026-04-21

### Changed

- `agents/canopy/ops/validate.md` — two new Errors added: inline fixed text in any tree node (including `Report:`, natural language steps, op descriptions) must be extracted to `constants/`; inline parameterised text with `<token>` slots must be extracted to `templates/`; procedural note added: for content-class rules, iterate every tree node in order and apply each check explicitly — do not rely on a holistic scan

---

## [0.13.0] — 2026-04-20

### Changed

- `agents/canopy/ops/validate.md` — added scope line: all checks apply to tree nodes in both `skill.md` and `ops.md` equally; new Error for complex inline command invocations (must extract to `commands/`); new Warning for long prose nodes (must extract to named op)
- `agents/canopy/ops/improve.md` — step 9 changed to iterative: repeat VALIDATE + fix loop until no Errors or Warnings remain (previously stopped after one pass, leaving residual violations)
- `agents/canopy/ops/create.md` — `ops.md` quality spec added: nodes must comply with same writing-rules and skill-structure-rules as `skill.md`; footer added reinforcing short nodes and commands-extraction requirement
- `agents/canopy/policies/writing-rules.md` — two new sections: "Tree nodes → ops" (long prose must be extracted); "Static and parameterised content → constants or templates" (applies to all node types)
- `agents/canopy/policies/skill-structure-rules.md` — added to must-NOT-contain list: complex inline command invocations must be extracted to `commands/` scripts

---

## [0.12.0] — 2026-04-20

### Added

- `skills/shared/framework/ops.md` — new `FOR_EACH << item in collection` primitive for iterating over collections; body executes once per element; empty collection skips body entirely; `BREAK` inside exits the loop early; `BREAK` outside a loop exits the current op (dual role clarified)

### Changed

- `docs/FRAMEWORK.md` — added `FOR_EACH` to node types table, Control Flow Primitives section, and Op Registries table; primitives sentence updated
- `docs/AUTHORING.md` — added `FOR_EACH` and updated `BREAK` in Framework Primitives table
- `agents/canopy/constants/control-flow-notation.md` — added migration entries for `FOR_EACH` (replace prose loops and numbered-step-per-item patterns)
- `agents/canopy/ops/validate.md` — `FOR_EACH` added to error check for framework primitives defined in skill/project ops
- `agents/canopy.md` — primitives list updated
- `skills/canopy-debug/ops.md` — `FOR_EACH` added to never-simulated primitives list
- `rules/skill-resources.md`, `setup.sh`, `setup.ps1`, `CLAUDE.md` — primitives lists updated

---

## [0.11.0] — 2026-04-20

### Added

- `skills/shared/framework/ops.md` — three new control-flow primitives: `SWITCH << expression`, `CASE << value`, `DEFAULT`; `SWITCH` evaluates an expression once and executes the first matching `CASE`; `DEFAULT` fires when no `CASE` matched; use in place of long `IF/ELSE_IF` chains that branch on a single value

### Changed

- `docs/FRAMEWORK.md` — added `SWITCH/CASE/DEFAULT` to Control Flow Primitives section and Op Registries table; updated primitives list in Op Lookup Order
- `docs/AUTHORING.md` — added `SWITCH`, `CASE`, `DEFAULT` to Framework Primitives table
- `agents/canopy/constants/control-flow-notation.md` — added migration entries for `SWITCH/CASE` (replace repeated `ELSE_IF` chains matching one value)
- `agents/canopy/ops/validate.md` — `SWITCH`, `CASE`, `DEFAULT` added to error check for framework primitives defined in skill/project ops
- `agents/canopy.md` — primitives list updated
- `skills/canopy-debug/ops.md` — `SWITCH`, `CASE`, `DEFAULT` added to never-simulated primitives list
- `rules/skill-resources.md`, `setup.sh`, `setup.ps1`, `CLAUDE.md` — primitives lists updated

---

## [0.10.0] — 2026-04-20

### Added

- `skills/canopy/skill.md` — new bundled `canopy` skill; detects active platform and delegates to `.claude/agents/canopy.md` or `.github/agents/canopy.md`; enables `/canopy <request>` as the primary invocation shorthand on Claude Code
- `agents/canopy/policies/platform-targeting.md` — platform targeting policy for write ops (CREATE, SCAFFOLD, CONVERT_TO_CANOPY): maps execution platform and explicit user target to the correct skills base path; enforces no hardcoded `.claude/` or `.github/` paths in generated skill content

### Changed

- `agents/canopy.md` — `dispatch-schema.json` explore output extended with `available_platforms` (all detected platform dirs) and `explicit_target_platform` (from user input or null); added rule: always load platform runtime spec before executing any op procedure
- `agents/canopy/schemas/dispatch-schema.json` — added `available_platforms` (array) and `explicit_target_platform` (string or null) fields to the dispatch output contract
- `agents/canopy/ops/create.md`, `scaffold.md`, `convert-to-canopy.md` — platform-aware skill path resolution via `policies/platform-targeting.md`
- `agents/canopy/ops/validate.md` — added cross-platform content check: flags hardcoded `.claude/` or `.github/` paths in skill files
- `agents/canopy/policies/skill-structure-rules.md` — added cross-platform content rule: `skill.md` must not contain hardcoded platform paths
- `agents/canopy/policies/subagent-rules.md` — documented platform-specific subagent execution: native Explore subagent on Claude Code; inline sequential file-reading fallback on Copilot
- `agents/canopy/verify/create-expected.md`, `scaffold-expected.md` — verify target-platform path rather than hardcoded `.claude/` path
- `runtimes/claude.md` — invocation updated to `/canopy <request>` via the bundled `canopy` skill
- `docs/README.md` — invocation section rewritten: `/canopy <request>` as primary form for Claude Code; `Follow .github/agents/canopy.md and <request>` for Copilot; operations table updated with concrete `/canopy` examples
- `CLAUDE.md` — Contributing Rules: added documentation verification requirement — every framework change must be verified against `runtimes/`, `AUTHORING.md` for staleness before the work is considered done

---

## [0.9.0] — 2026-04-19

### Added

- `runtimes/claude.md` — Claude Code runtime spec: base paths (`.claude/`), native explore subagent execution, ambient rules via globs, agent and skill invocation forms
- `runtimes/copilot.md` — GitHub Copilot runtime spec: base paths (`.github/`), inline sequential file-reading fallback when native subagent is unavailable, `copilot-instructions.md` rules wiring, explicit agent invocation form
- `agents/canopy/schemas/dispatch-schema.json` — output contract for the canopy agent's own intent-classification subagent; fields: `operation`, `platform` (`claude` | `copilot`), `target_skill`, `extra_context`

### Changed

- `agents/canopy.md` — restructured from free-form prose to Canopy skill format (frontmatter + `## Agent` + `## Tree` + `## Rules` + `## Response:`); `## Agent` explore subagent now classifies intent **and** detects platform; `## Tree` replaces LLM-inferred dispatch with an explicit `IF/ELSE_IF` chain over `context.operation` — deterministic routing to one of 10 ops; falls back to `ASK` when intent is ambiguous
- `docs/README.md` — added "Skills that run on Claude Code and GitHub Copilot" to Why Canopy; updated How It Works to describe platform-aware execution and self-hosting agent design; updated Under the Hood diagram with Stage 2 (detect platform + load runtime), Stage 3 (explore with native vs inline fallback), and runtime specs legend
- `docs/FRAMEWORK.md` — added Runtime Model section (interpreter model rationale, feature delta table, runtime spec file list); updated directory layout to show `runtimes/` and both schema files
- `CLAUDE.md` — updated Key Files to document `runtimes/`, `dispatch-schema.json`, and the new canopy agent structure

---

## [0.8.1] — 2026-04-16

### Changed

- `agents/canopy/ops/improve.md`, `modify.md`, `refactor-skills.md`, `convert-to-canopy.md`, `create.md`, `scaffold.md`, `convert-to-regular.md` — all confirmation-pause ops now emit a fenced `apply` block (op name, skill name, per-file change list) immediately before asking "Proceed?"; if re-invoked after the block is visible in context the agent skips analysis and applies directly, preventing plan context loss across invocations
- `agents/canopy/ops/help.md` — corrected Claude Code CLI invocation section: `/canopy` invokes a skill, not the agent; natural language requests auto-apply the agent from `.claude/agents/canopy.md`; explicit form documented as `Follow .claude/agents/canopy.md and <request>`

---

## [0.8.0] — 2026-04-16

### Added

- `agents/canopy/ops/` — per-operation procedure files extracted from `agents/canopy.md`: `create.md`, `modify.md`, `scaffold.md`, `convert-to-canopy.md`, `validate.md`, `convert-to-regular.md`, `improve.md`, `advise.md`, `refactor-skills.md`, `help.md`
- `agents/canopy/constants/` — extracted lookup tables: `category-dirs.md`, `control-flow-notation.md`, `operation-detection.md`, `operations-dispatch.md`
- `agents/canopy/verify/` — expected-state checklists for `VERIFY_EXPECTED` per operation: `create-expected.md`, `modify-expected.md`, `scaffold-expected.md`, `convert-to-canopy-expected.md`, `convert-to-regular-expected.md`, `improve-expected.md`, `refactor-skills-expected.md`
- `agents/canopy/policies/skill-structure-rules.md`, `writing-rules.md`, `op-naming-rules.md`, `subagent-rules.md`, `debug-rules.md`, `preservation-rules.md`, `category-decision-flowchart.md`, `conversion-expansion-rules.md` — `optimization-rules.md` decomposed into targeted single-concern policy files
- New operations on the `canopy` agent: `IMPROVE` (fix violations, re-categorise resources, align with framework), `ADVISE` (read-only "how to" plans), `REFACTOR_SKILLS` (extract ops/resources shared across > 2 skills to `shared/`), `HELP` (usage reference)
- `skills/canopy-help/SKILL.md` — read-only skill that emits the canopy agent help reference or a specific operation procedure

### Changed

- `agents/canopy.md` — inline operation procedures and constants replaced with `Read <category>/<file>` references; tree examples expanded with a full `release` skill illustration; `REFACTOR_SKILLS` and `HELP` added to operation detection; two new rules added (no duplicate shared ops/resources; verify references after every change)
- `agents/canopy/policies/optimization-rules.md` — now an index table pointing to the decomposed policy files
- `agents/canopy/schemas/explore-schema.json` — `existing_resources` field updated to reference new policy file names
- `docs/FRAMEWORK.md`, `CLAUDE.md` — directory layout updated to show `ops/`, `constants/`, `verify/` under `agents/canopy/`; sync-required note updated to reference `agents/canopy/policies/` instead of the single `optimization-rules.md`
- `docs/README.md` — usage table extended with IMPROVE, ADVISE, REFACTOR_SKILLS, HELP operations

---

## [0.7.0] — 2026-04-13

### Added

- `skills/canopy-debug/skill.md` — new `canopy-debug` skill; traces any Canopy skill with live phase banners and per-node tree tracking; respects Claude Code mode (plan mode simulates mutations, edit mode executes normally)
- `skills/canopy-debug/ops.md` — skill-local ops: `EMIT_PHASE_BANNER` (renders double-box phase banners), `EXECUTE_WITH_TRACE` (drives full skill execution with tracing), `TRACE_NODE` (emits stream one-liner and overwrites trace file per state change), `TRACE_EXECUTE_NODES` (iterates nodes with mode-aware branch evaluation), `WRITE_TRACE_FILE` (overwrites `.canopy-debug-trace.log` with current full-tree snapshot)
- `skills/canopy-debug/policies/debug-output.md` — debug output protocol: dual-channel output (chat stream + trace file), phase registry with ordinals and descriptions, phase banner format, node state symbol table (`→ ⟳ ✓ ◎ ⊘ ✗ ⏸ ⊙`), stream and trace file formats, mode-aware execution rules, ASK interaction protocol, EXPLORE subagent handling, END/HALTED display

### Changed

- `docs/README.md` — added "Failures you can trace to a single node" bullet to the "Why Canopy?" section; references `/canopy-debug` for live phase and per-node tracing

---

## [0.6.0] — 2026-04-12

### Changed

- `agents/canopy-skill.md` → `agents/canopy.md` — agent renamed from `canopy-skill` to `canopy`
- `agents/canopy-skill/` → `agents/canopy/` — agent resource directory renamed to match
- `agents/canopy.md` — frontmatter `name:` updated to `canopy`; `optimization-rules.md` glob updated to `**/canopy/policies/optimization-rules.md`
- `docs/FRAMEWORK.md`, `docs/README.md`, `docs/AUTHORING.md`, `docs/CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md` — all `canopy-skill` agent references updated to `canopy`

---

## [0.5.0] — 2026-04-12

### Added

- `agents/canopy-skill.md` — `canopy-skill` promoted from skill to Claude Code agent; handles six operations: CREATE (new skill from description), MODIFY (targeted edits to existing skill), SCAFFOLD (blank skeleton with all dirs), CONVERT_TO_CANOPY (flat skill → Canopy format), VALIDATE (errors, warnings, optimization report), CONVERT_TO_REGULAR (Canopy → flat skill)
- `agents/canopy-skill/templates/skill.md` and `agents/canopy-skill/templates/ops.md` — skeleton templates used by the SCAFFOLD operation
- `AUTHORING.md` — manual skill authoring reference: full anatomy walkthrough, both tree syntaxes with examples, op definition patterns, primitives table, category resource directory reference, and `skill.md` content constraints
- `setup.sh` and `setup.ps1` — agent wiring: symlink/junction each bundled agent `.md` file and its resource directory into `.claude/agents/` (mirrors existing skill symlink pattern)

### Changed

- `agents/canopy-skill/policies/optimization-rules.md` — moved from `skills/canopy-skill/policies/`; content unchanged
- `agents/canopy-skill/schemas/explore-schema.json` — moved from `skills/canopy-skill/schemas/`; content unchanged
- `README.md` — Usage section rewritten around the `canopy-skill` agent (operation table with example invocations); manual authoring content replaced with a link to `AUTHORING.md`; `## Skill Anatomy` section trimmed to structural overview only; Features bullet updated to reflect agent promotion; `AUTHORING.md` added to Directory Structure
- `FRAMEWORK.md` — added `## Framework Agents` section documenting agent format, resource subdirectory conventions, and setup wiring; directory layout updated to show `agents/` alongside `skills/`
- `CONTRIBUTING.md` — sync-required file list updated to reference `agents/canopy-skill/policies/optimization-rules.md`

### Removed

- `skills/canopy-skill/skill.md` and `skills/canopy-skill/ops.md` — superseded by `agents/canopy-skill.md`

---

## [0.4.0] — 2026-04-12

### Added

- Markdown list syntax (`*` nested lists) as an alternative to box-drawing characters for tree definitions — write trees directly under `## Tree` without a fenced code block
- `examples/` documentation split out to `claude-canopy-examples` repo; canopy repo stays submodule-clean

### Changed

- `rules/skill-resources.md` — Tree format section now documents both syntaxes with examples
- `FRAMEWORK.md` — Tree Execution Model section shows both formats side-by-side; Skill-Local ops.md section shows markdown list format as alternative for branching op definitions
- `README.md` — `## Tree` anatomy and minimal example updated to lead with markdown list syntax
- `skills/canopy-skill/policies/optimization-rules.md` — Rule 6 updated to list both formats; markdown list marked as preferred for new/simple trees

---

## [0.3.2] — 2026-04-12

### Added

- community health files for GitHub: `CONTRIBUTING.md`, issue templates, and pull request template

---

## [0.3.1] — 2026-04-12

### Changed

- `README.md` — replaced the broken external examples link with plain repo mention, made the `## Agent` example generic instead of project-specific, and reduced duplication between `Skill Anatomy` and `Writing a Skill`

---

## [0.3.0] — 2026-04-12

### Fixed

- `setup.ps1` — create directory junctions in `.claude/skills/` for each bundled canopy skill so VS Code discovers them outside the submodule boundary
- `setup.sh` — create symlinks in `.claude/skills/` for each bundled canopy skill for the same reason on Linux/macOS

---

## [0.2.0] — 2026-04-12

### Added

- `setup.sh` and `setup.ps1` — submodule setup scripts; create wiring files in the user's project so Claude Code can see both canopy internals and project skills
- `skills/canopy-skill/` — renamed from `optimize-skill`; bundled meta-skill for auditing and optimizing Canopy skills

### Changed

- `README.md` — added "How It Works" diagram showing full skill anatomy; added inline examples in Features; added Skill Anatomy section; rewrote Quick Start Option A (vendored via curl/tar, explicit warning against git clone) and Option B (git submodule + setup script); removed manual Submodule Wiring section
- `FRAMEWORK.md` — removed content duplicated in README (intro paragraph, submodule directory tree, Skill Anatomy); added pointer to README for setup instructions
- `rules/skill-resources.md` — updated standalone note to reference setup scripts

---

## [0.1.0] — 2026-04-12

### Added

- Initial framework release — extracted from home-data-center project
- `FRAMEWORK.md` — full Canopy specification (tree execution model, op lookup order, category resources)
- `rules/skill-resources.md` — ambient rules for standalone use
- `skills/shared/framework/ops.md` — framework primitives: `IF`, `ELSE_IF`, `ELSE`, `BREAK`, `END`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`
- `skills/shared/project/ops.md` — stub with commented examples for project-wide ops
- `skills/shared/ops.md` — redirect stub
- `skills/canopy-skill/` — bundled meta-skill for auditing and optimizing Canopy skills
- `README.md` — setup instructions for standalone and submodule usage
- `LICENSE` — MIT
- Submodule wiring documentation
