---
paths:
  - "skills/canopy-runtime/assets/constants/marker-block.md"
  - "install.sh"
  - "install.ps1"
---

# Rule: Marker block 4-source-of-truth parity

When the canopy-runtime marker block content changes, **all four sources of truth must stay byte-identical**:

1. `skills/canopy-runtime/assets/constants/marker-block.md` — canonical home (runtime is self-contained for activation)
2. `install.sh` `build_marker_block()`
3. `install.ps1` `Build-MarkerBlock`
4. VSCode extension's marker-block constant in `claude-canopy-vscode/src/commands/installCanopy.ts` (sibling repo)

## Verify

After updating any of the four, run the parity check:

```bash
python install-test/check_parity.py
```

The script reports `OK` / `FAIL` per source. CI fails the build if drift exists between any pair.

## Cross-repo coupling

The vscode extension mirror (`claude-canopy-vscode`) lives in a separate repo. When updating the framework-side marker block, the vscode mirror PR must follow shortly. The parity check is what catches drift; it runs in both repos' CI.

## Why this matters

The marker block is what activates `canopy-runtime` ambiently — it's written into `CLAUDE.md` (Claude Code) or `.github/copilot-instructions.md` (Copilot) by install scripts and by the runtime's `## Activation` section. Drift between sources means a project installed via one path gets a different marker than one installed via another, breaking the "single source of truth for the runtime" property.

## Path scope

This rule loads when any of the in-repo marker-block sources is read or edited. The vscode mirror is in a sibling repo and can't be path-scoped from here, but the warning still applies — when committing changes here, ensure the vscode PR is opened.
