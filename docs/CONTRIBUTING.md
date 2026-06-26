---
title: Contributing
nav_order: 7
description: "How to contribute to Canopy — scope, sync points, local dev, PR expectations, release flow."
---

# Contributing to Canopy

Thanks for contributing. This page covers what kind of changes fit, how to coordinate across the three sibling repos, what to keep in sync, and what CI checks before merge.

---

## What this repo holds

`canopy` is the framework itself: the spec (`docs/`), the three framework skills (`skills/canopy-runtime/`, `skills/canopy/`, `skills/canopy-debug/`), the install scripts, and the plugin manifests. Two sibling repos consume it:

| Repo | Role |
|---|---|
| [`canopy-vscode`](https://github.com/kostiantyn-matsebora/canopy-vscode) | VS Code extension — IntelliSense, diagnostics, hover docs, go-to-definition for Canopy skills. Tracks a specific framework version via `.canopy-version`. |
| [`canopy-examples`](https://github.com/kostiantyn-matsebora/canopy-examples) | Worked-example skills + a vendored framework copy. Used as an end-to-end test surface. |

Changes in `canopy` may require corresponding updates in either or both sibling repos — see [Cross-repo sync points](#cross-repo-sync-points).

---

## Good contributions

- Framework docs and clarifications (`docs/`)
- Improvements to bundled skills (`skills/canopy*/`)
- Framework primitives, op-lookup behavior, runtime spec changes
- agentskills.io spec compliance fixes
- Install-script reliability (`install.sh`, `install.ps1`)
- CI plumbing (`scripts/validate.sh`, `scripts/sync-runtime-docs.py`)

For VS Code extension changes, open a PR in [`canopy-vscode`](https://github.com/kostiantyn-matsebora/canopy-vscode) directly. For example-skill PRs, use [`canopy-examples`](https://github.com/kostiantyn-matsebora/canopy-examples).

---

## Sync points within `canopy`

The framework spec lives in multiple files by design — runtime spec is loaded ambiently by the runtime; doc spec is rendered for human readers; policies guide the authoring agent. When you change one, audit the others.

### Framework behavior

If a change affects framework behavior (a primitive, op-lookup, runtime rule, category dir, frontmatter spec), keep these in sync:

| File | Role |
|---|---|
| `docs/reference/FRAMEWORK_SPEC.md` | Human-facing spec (non-runtime content) |
| `skills/canopy-runtime/SKILL.md` | Runtime entry, including the `## Activation` section |
| `skills/canopy-runtime/references/skill-resources.md` | Category semantics, op lookup chain, tree format, subagent contract, safety preamble |
| `skills/canopy-runtime/references/ops.md` (index) + `ops/<slice>.md` (per-feature slices) | **Canonical** source for `docs/reference/PRIMITIVES.md` — run `python scripts/sync-runtime-docs.py` after editing any slice or the index |
| `skills/canopy-runtime/references/runtime-claude.md` and `runtime-copilot.md` | **Canonical** source for `docs/reference/RUNTIMES.md` — same sync rule |
| `skills/canopy/assets/policies/authoring-rules.md` | The authoring agent's rule book |

### Marker block (runtime activation)

Four sources of truth must stay byte-identical:

| File | Notes |
|---|---|
| `skills/canopy-runtime/assets/constants/marker-block.md` | Canonical home |
| `install.sh`'s `build_marker_block()` | Bash equivalent |
| `install.ps1`'s `Build-MarkerBlock` | PowerShell equivalent |
| `canopy-vscode/src/commands/installCanopy.ts`'s `MARKER_BLOCK` | TypeScript constant in the sibling repo |

CI parity check (`python install-test/check_parity.py`) enforces this — drift is a release blocker.

### Runtime mirror script

Two of the Reference pages on the docs site are **mirrors**, not authored content:

- `docs/reference/PRIMITIVES.md` ← `skills/canopy-runtime/references/ops.md` (index) + `ops/<slice>.md` (per-feature slices)
- `docs/reference/RUNTIMES.md` ← `skills/canopy-runtime/references/runtime-{claude,copilot}.md`

Don't edit the mirrors directly — your changes will be overwritten on next sync. Edit the canonical file under `skills/canopy-runtime/references/`, then run:

```bash
python scripts/sync-runtime-docs.py
```

CI runs `--check` mode and fails the build if you forget.

---

## Cross-repo sync points

When a framework change has surface-area in either sibling repo:

| Change in `canopy/` | Update in sibling |
|---|---|
| New framework primitive added (in `references/ops/<slice>.md`; index `ops.md` updated) | `canopy-vscode`: `RESERVED_PRIMITIVES`, `PRIMITIVE_DOCS`, `checkPrimitiveSignatures()`, syntax grammar, snippets — see the extension's `CLAUDE.md` for the full list |
| Primitive signature change | `canopy-vscode`: matching `case` in `checkPrimitiveSignatures()` and `PRIMITIVE_DOCS` |
| New category resource directory | `canopy-vscode`: `VALID_CATEGORIES`, `CATEGORY_DIRS`, language-ID grammar, snippets |
| Frontmatter field added or removed | `canopy-vscode`: `FRONTMATTER_REQUIRED`, `FRONTMATTER_ALLOWED`, completions, hover docs |
| Tree-syntax notation change | `canopy-vscode`: `parseTreeLine()` |
| Ambient marker-block content change | All four sources of truth (see [Marker block](#marker-block-runtime-activation)) |
| Install command surface or skill names change | `canopy-vscode`: `installCanopy.ts`, `canopyAgent.ts` |
| Major version bump | `canopy-vscode`: bump `.canopy-version`, run extension's test sweep, release new extension version |
| Behavior change worth a worked example | `canopy-examples`: add or update an example skill under `.agents/skills/` |

The full list of extension sync points lives in [`canopy-vscode/CLAUDE.md`](https://github.com/kostiantyn-matsebora/canopy-vscode/blob/master/CLAUDE.md). When in doubt, treat `docs/reference/FRAMEWORK_SPEC.md` and `skills/canopy-runtime/references/skill-resources.md` as canonical and audit downstream.

---

## Local dev

```bash
# Validate frontmatter, manifests, version sync (the same checks CI runs):
bash scripts/validate.sh

# Verify the runtime mirror is in sync (same check CI runs):
python scripts/sync-runtime-docs.py --check

# Check the marker-block parity across all four sources:
python install-test/check_parity.py

# Test an install path end-to-end:
bash install.sh --target both --ref <branch-or-sha>
# or
pwsh install.ps1 -Target both -Ref <branch-or-sha>
```

For docs-site work, the site is built automatically by GitHub Pages from `master/docs/`. Most pages render without local Jekyll — open the `.md` in any markdown viewer to preview.

---

## Workflow

1. Fork the repository
2. Create a branch from `master`
3. Make focused changes (one concern per PR; split ambitious work into a phased series)
4. Update docs when behavior changes; run `sync-runtime-docs.py` if you touched a runtime spec file
5. Update `docs/CHANGELOG.md` for user-visible changes (one entry per release block)
6. Open a pull request against `master`

---

## Style

- Keep changes minimal and scoped
- Preserve the framework's terminology and tree notation (see [Terminology](TERMINOLOGY.md))
- Prefer examples that are generic rather than project-specific
- Document any breaking behavior change clearly in the PR and `CHANGELOG.md`
- Lead bullets with a bold label when listing structured information; use tables for two-axis material; cross-reference instead of restating

---

## Pull request checklist

Before opening a PR, verify:

- [ ] `bash scripts/validate.sh` passes (frontmatter, manifests, version sync)
- [ ] `python scripts/sync-runtime-docs.py --check` passes (runtime mirror in sync)
- [ ] `python install-test/check_parity.py` returns four `OK` lines (marker-block parity)
- [ ] `gh skill install` round-trip still works against any modified skill (publishing layout: `skills/<name>/` at repo root, no `: ` inside unquoted `compatibility` values)
- [ ] `compatibility` values stay free-text under 500 chars (per agentskills.io spec)
- [ ] Bundled skills still reflect current framework rules
- [ ] `docs/` cross-references resolve (run a link check or click through after deploy preview)
- [ ] If extension surface changed, a corresponding PR in [`canopy-vscode`](https://github.com/kostiantyn-matsebora/canopy-vscode) is open or planned

---

## Commit messages

Conventional Commits, lowercase prefix:

- `feat: add the new SPAWN primitive`
- `fix: align README install instructions with v0.18.1 flags`
- `docs: clarify tree execution model`
- `chore: bump dependency`
- `refactor: extract shared op resolution into opRegistry`

---

## Release flow

The version string lives in **seven places** that must stay in sync:

1. `.canopy-version`
2. `.claude-plugin/plugin.json` → `version`
3. `.claude-plugin/marketplace.json` → `metadata.version` AND `plugins[0].version`
4. `skills/canopy/SKILL.md` → frontmatter `metadata.version`
5. `skills/canopy-runtime/SKILL.md` → frontmatter `metadata.version`
6. `skills/canopy-debug/SKILL.md` → frontmatter `metadata.version`
7. The git tag `vX.Y.Z`

Bump is manual (no `/bump-version` skill in this repo). Edit all six in-repo files, add a `docs/CHANGELOG.md` entry under `## [X.Y.Z] — YYYY-MM-DD`, commit, push to master, then tag and push the tag separately:

```bash
git push origin master
git tag -s vX.Y.Z -m "vX.Y.Z — <one-line summary>"
git push origin vX.Y.Z
```

Pushing a `v*` tag fires `.github/workflows/release.yml`, which extracts the matching `## [X.Y.Z] — …` block from `docs/CHANGELOG.md` and creates a GitHub Release. The git tag is the install artifact for `gh skill install --pin vX.Y.Z` and for the Claude Code plugin marketplace. Full bump procedure including the sanity-check grep auto-loads from [`.claude/rules/versioning.md`](../.claude/rules/versioning.md) whenever a version-tracking file is open.

---

## Reporting issues

Use the [issue templates](https://github.com/kostiantyn-matsebora/canopy/issues/new/choose). Areas:

- Framework docs / spec — `docs/reference/`
- Bundled skills — `skills/canopy*/`
- Install / setup — `install.sh`, `install.ps1`, `gh skill`
- Other

For VS Code extension issues, file in [`canopy-vscode`](https://github.com/kostiantyn-matsebora/canopy-vscode/issues).
