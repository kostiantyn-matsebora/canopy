# Contributing to Canopy

Thanks for contributing.

## Scope

This repo is the framework itself. Good contributions include:

- framework docs and clarifications
- improvements to bundled skills
- framework primitives or resource-loading behavior
- agentskills.io spec compliance fixes

If a change affects framework behavior, keep these files in sync:

- `docs/FRAMEWORK.md`
- `skills/canopy-runtime/SKILL.md` (especially the `## Activation` section)
- `skills/canopy-runtime/references/skill-resources.md`
- `skills/canopy-runtime/references/framework-ops.md`
- `skills/canopy-runtime/references/runtime-claude.md` and `runtime-copilot.md`
- `skills/canopy/assets/policies/authoring-rules.md`

If a change affects the marker-block content, also keep these in sync (CI parity check enforces it):

- `skills/canopy-runtime/assets/constants/marker-block.md` (canonical home)
- `install.sh` `build_marker_block()`
- `install.ps1` `Build-MarkerBlock`
- The VSCode extension's `MARKER_BLOCK` constant in `claude-canopy-vscode/src/commands/installCanopy.ts`

## Getting Started

1. Fork the repository.
2. Create a branch from `master`.
3. Make focused changes.
4. Update docs when behavior changes.
5. Update `docs/CHANGELOG.md` for user-visible changes.
6. Open a pull request.

## Style

- Keep changes minimal and scoped.
- Preserve the framework's terminology and tree notation.
- Prefer examples that are generic rather than project-specific.
- Do not introduce breaking behavior without documenting it clearly.

## Pull Requests

Before opening a pull request, check:

- the README still matches the actual install flow (`gh skill install ...`, install scripts, plugin marketplace, cross-client `.agents/skills/`)
- framework docs do not duplicate each other unnecessarily
- bundled skills still reflect current framework rules
- the marker-block parity check passes — `python install-test/check_parity.py` returns four `OK` lines
- `gh skill install` round-trip still works against the modified skill (publishing layout: `skills/<name>/` at repo root, no `: ` inside unquoted compatibility values)
- compatibility values stay free-text under 500 chars (per agentskills.io spec)

## Commit Messages

Conventional Commits are preferred, for example:

- `feat: add submodule setup wiring`
- `fix: align README setup instructions with actual behavior`
- `docs: clarify tree execution model`
