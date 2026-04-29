# ACTIVATE

Wire canopy-runtime into the current project's ambient instruction file (`CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot) so user-authored canopy skills are interpreted by canopy-runtime — regardless of how canopy itself was installed.

**Mostly redundant since canopy-runtime v0.18.0:** canopy-runtime now self-activates on first load (see its **Activation** section), writing the marker block automatically without user interaction. ACTIVATE remains useful for:
- Re-applying the marker block after a canopy version bump that changes its content
- Forcing activation explicitly (e.g. troubleshooting "runtime not loading")
- Activating across both platforms in a dual-target repo in one pass

If canopy-runtime is current and the marker block is already correct, ACTIVATE reports `unchanged` and exits.

1. Read `assets/policies/platform-targeting.md` and resolve the target platform(s):
   - `claude` only → target file is `CLAUDE.md` at workspace root
   - `copilot` only → target file is `.github/copilot-instructions.md`
   - both → write to both files (one ACTIVATE pass per file)
2. Read `assets/constants/marker-block.md` for the canonical block content and the idempotent write contract.
3. For each target file, inspect the existing state and determine the action per the contract:
   - File doesn't exist → action: `CREATE`
   - File exists, zero marker pairs → action: `APPEND` (preserve content; add a blank-line separator if file doesn't already end on a newline)
   - File exists, exactly one marker pair → action: `REPLACE` (rewrite only between the markers; outer content untouched)
   - File exists, multiple marker pairs → action: `REPLACE_FIRST` + warn the user about the extras
   - File exists, marker count mismatch (begin count ≠ end count) → action: `REFUSE` — show the file path and ask the user to clean up manually before re-running ACTIVATE
4. Show plan: per target file, list `target_file | action | block diff` (the lines being added or replaced).
5. Ask: **"Proceed with activation? | Yes | No"** — abort with no changes on No.
6. Apply each change idempotently. Content above and below the markers MUST remain bit-identical. Preserve trailing-newline semantics.
7. Verify result against `assets/verify/activate-expected.md`.
8. Report: **target_files | action_per_file | warnings | next steps**

## Notes

- **Re-running is safe and a no-op** when the block is already current — the contract treats "no change needed" as success and reports `unchanged`.
- **Re-running after a canopy version bump** that changes the marker content is an idempotent rewrite; outer content stays put.
- The block content lives at `assets/constants/marker-block.md` and must stay byte-identical with `claude-canopy/install.sh build_marker_block()`, `install.ps1 Build-MarkerBlock`, and the VSCode extension's marker-block constant. CI (`scripts/validate.sh`) verifies parity — a mismatch is a release blocker.
- ACTIVATE never modifies files outside the workspace root and never deletes existing content (only appends, replaces between markers, or refuses).
