# Canopy Test Scenarios

Test suites covering canopy 0.18.0 spec compliance, install paths, and runtime behavior. Suites are the parallelization unit — every suite is fully isolated and may run concurrently with any other suite. Scenarios within a suite generally parallelize too (each gets its own sandbox); exceptions are flagged.

## Conventions

- **Sandbox** — every install/runtime scenario runs in a unique workspace under `$TMPDIR/canopy-<suite>-<scenario>/`. Workspaces are wiped before each run.
- **Refs** — `<canopy-ref>` is a branch, tag, or commit on `kostiantyn-matsebora/claude-canopy`. `<examples-ref>` is the same on `kostiantyn-matsebora/claude-canopy-examples`. For pre-release testing use `agentskills-compatibility` and `e2e-preview`.
- **Result format** — each scenario lists Setup, Steps, Expected, Failure modes. Pass = all Expected hold; any drift in Failure modes = fail.

---

## Suite A — Install Scripts (`install.sh`, `install.ps1`)

**Validates:** the install scripts wire skills into the right location and write the marker block correctly per `--target`.
**Parallelizable:** all scenarios independent (unique sandbox dirs).
**Prereqs:** bash (Suite A.sh) or PowerShell 7+ (Suite A.ps), git, network.

### A.1 — bash install, target=claude (fresh project)
- **Setup:** empty workspace.
- **Steps:** `bash install.sh --target claude --ref <canopy-ref>`.
- **Expected:** `.claude/skills/{canopy,canopy-debug,canopy-runtime}/SKILL.md` exist; `CLAUDE.md` created; contains exactly one `<!-- canopy-runtime-begin -->` … `<!-- canopy-runtime-end -->` pair.
- **Failure modes:** marker block missing, duplicated, or content drift from canonical.

### A.2 — bash install, target=copilot (fresh project)
- **Setup:** empty workspace.
- **Steps:** `bash install.sh --target copilot --ref <canopy-ref>`.
- **Expected:** `.github/skills/{canopy,canopy-debug,canopy-runtime}/SKILL.md` exist; `.github/copilot-instructions.md` created with marker block.
- **Failure modes:** wrong skills root, marker writes to CLAUDE.md instead.

### A.3 — bash install, target=both (fresh project)
- **Setup:** empty workspace.
- **Steps:** `bash install.sh --target both --ref <canopy-ref>`.
- **Expected:** skills land in BOTH `.claude/skills/` and `.github/skills/`; marker block in BOTH `CLAUDE.md` and `.github/copilot-instructions.md`.

### A.4 — bash install, target=agents (cross-client, fresh project)
- **Setup:** empty workspace.
- **Steps:** `bash install.sh --target agents --ref <canopy-ref>`.
- **Expected:** skills land in `.agents/skills/` only; marker block in `CLAUDE.md` (fallback created since no instructions file existed).

### A.5 — bash install, target=agents, pre-existing `.github/copilot-instructions.md`
- **Setup:** workspace contains an empty `.github/copilot-instructions.md`.
- **Steps:** `bash install.sh --target agents --ref <canopy-ref>`.
- **Expected:** marker block appended to `.github/copilot-instructions.md`; no `CLAUDE.md` created.

### A.6 — bash install, idempotent re-run
- **Setup:** workspace already activated by A.1.
- **Steps:** re-run `bash install.sh --target claude --ref <canopy-ref>`.
- **Expected:** marker block unchanged; no new file created; exit code 0; output reports "unchanged" or "updated" depending on whether content shifted.
- **Failure modes:** marker block duplicated; outer content modified.

### A.7..A.10 — PowerShell parity
Same scenarios as A.1–A.4 but with `pwsh -NoProfile -File install.ps1 -Target <claude|copilot|both|agents> -Ref <canopy-ref>`. Run `pwsh` from a Windows-resolved path (`$env:TEMP`), not bash's `/tmp/` — the two interpret tmp differently and pwsh defaults to the calling shell's cwd if `Set-Location` fails.

---

## Suite B — Marker Block Parity

**Validates:** the canonical marker block content is byte-identical across all four sources.
**Parallelizable:** static-only; one Python script. Trivially parallel-safe with anything else.
**Prereqs:** Python 3, the four source files.

### B.1 — Four-way parity check
- **Setup:** clean working tree.
- **Steps:** `python install-test/check_parity.py`.
- **Expected:** four `OK` lines for `canonical`, `vscode-ts`, `install.sh`, `install.ps1`. Exit 0.
- **Sources of truth:**
  - `claude-canopy/skills/canopy-runtime/assets/constants/marker-block.md` (canonical home since 0.18.0)
  - `claude-canopy-vscode/src/commands/installCanopy.ts` `MARKER_BLOCK` constant
  - `claude-canopy/install.sh` `build_marker_block()` heredoc
  - `claude-canopy/install.ps1` `Build-MarkerBlock` here-string
- **Failure modes:** any source diverges; the script prints a unified diff against canonical and exits 1.

---

## Suite C — VSCode Extension

The extension is a separate repo with its own test surface. See [`claude-canopy-vscode/docs/TEST-SCENARIOS.md`](https://github.com/kostiantyn-matsebora/claude-canopy-vscode/blob/master/docs/TEST-SCENARIOS.md) — covers TypeScript compile, vitest unit suite (276+ tests), compatibility-shape diagnostics, real-skills snapshot, marker-block parity (extension side), Extension Development Host smoke tests, and the marketplace publish gate.

The extension's `MARKER_BLOCK` constant is one of the four sources Suite B (this doc) checks for parity — that is the sole framework ↔ extension overlap point.

---

## Suite D — Static SKILL.md Validation

**Validates:** every `SKILL.md` in the framework + examples meets the agentskills.io spec.
**Parallelizable:** static analysis; no fs mutations; runs in seconds.
**Prereqs:** Python 3 + PyYAML, OR `skills-ref validate`.

### D.1 — Frontmatter loads as YAML
For each `skills/*/SKILL.md` and `.claude/skills/*/SKILL.md`: extract the frontmatter, run `yaml.safe_load`. **Expected:** no parse errors. **Failure modes:** colon-space inside an unquoted scalar (the canonical foot-gun).

### D.2 — `compatibility` is a string
For every SKILL.md that declares `compatibility`: assert `isinstance(value, str)`. **Expected:** all match. **Failure modes:** structured maps (`requires:`) or lists.

### D.3 — `compatibility` length ≤ 500 chars
Spec maximum.

### D.4 — Canopy-flavored skills have safety preamble
For every SKILL.md with `## Tree`: the body opens with a blockquote mentioning `canopy-runtime`.

### D.5 — Frontmatter root contains only spec fields
Allowed at root: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. **Failure modes:** `argument-hint` or `user-invocable` at root (must live inside `metadata`).

### D.6 — Skill file is exactly `SKILL.md` (uppercase)
For every skill directory: `SKILL.md` exists and `skill.md` does not. Required for case-sensitive filesystems.

---

## Suite E — Autonomous Agent E2E

**Validates:** an agent with zero canopy-specific knowledge can install a canopy skill, satisfy its dependencies, activate the runtime, and execute the skill — using only standard agentskills.io primitives.
**Parallelizable:** each round uses a unique sandbox + its own background agent; no shared state. Run-time per round: ~3–5 min.
**Prereqs:** gh CLI ≥ 2.90 (for native `gh skill`), or willingness to download a portable gh binary into the sandbox; network; published `agentskills-compatibility` + `e2e-preview` branches.

For all rounds: workspace is `$TMPDIR/canopy-e2e-skill-<round>/` containing only `CHANGELOG.md` (heading + tagline) and an empty `AGENT_TRANSCRIPT.md`. The agent appends `[HH:MM:SS] STEP_LABEL — what + outcome` lines to AGENT_TRANSCRIPT.md as it works; a `tail -f` Monitor surfaces them live.

### E.1 — Baseline (any-tool fallback)
Agent allowed any install primitive. Validates the spec works at all.
- **Allowed:** `git clone`, `install.sh`/`install.ps1`, `gh skill install`, tarball, `gh api`.
- **Forbidden:** none.
- **Expected:** agent picks whatever its environment supports; skill installs; runtime installs; marker block lands in CLAUDE.md (write source: install script if used, agent if not); skill mutates `CHANGELOG.md`; verify-expected 4/4 pass.
- **Today's outcome:** PASS via `git clone` + `install.sh`. Documented Finding 3 (skill-rule ambiguity, not framework).

### E.2 — Strict `gh skill install` only
Forbid clone/install-script paths. Validates the canonical agentskills.io install primitive works alone.
- **Allowed:** `gh skill install` (download portable gh binary into sandbox if local gh < 2.90), single-file `gh api` reads.
- **Forbidden:** `git clone`, `install.sh`, `install.ps1`, `/archive` tarballs, `gh api` to fetch trees.
- **Expected:** agent uses `gh skill install --pin <SHA> --agent claude-code` for both skills; activation written by agent following runtime SKILL.md `## Activation`.
- **Today's outcome:** PASS. Surfaced Finding 1 (`--allow-hidden-dirs` needed when skills published at `.claude/skills/`) and Finding 2 (Activation wording overclaimed "no follow-up step").

### E.3 — Canonical publishing layout (post-Finding-1 fix)
Same constraints as E.2 but skills are published at `skills/<name>/` at repo root (not `.claude/skills/`).
- **Forbidden additions:** `--allow-hidden-dirs` flag.
- **Expected:** `gh skill install <repo> skills/<skill-name> --pin <SHA> --agent claude-code` succeeds with no flags beyond the canonical set.
- **Today's outcome:** PASS. Surfaced two new findings: (a) runtime not self-contained for activation (Activation step 3 referenced `<skills-root>/canopy/...` but `gh skill install canopy-runtime` doesn't pull `canopy`), (b) canopy-runtime missing optional `compatibility` field.

### E.4 — Self-contained runtime (post-Finding-1a fix)
Same constraints as E.3. Validates that `marker-block.md` lives inside `canopy-runtime/assets/constants/` (moved from `canopy/`), so activation needs zero upstream fetches.
- **Expected:** during `ACTIVATE_RUNTIME`, the agent reads the marker block from the local installed path `.claude/skills/canopy-runtime/assets/constants/marker-block.md` only. Transcript explicitly states "no upstream fetch".
- **Today's outcome:** PASS (round 4b after a YAML-colon regression fix on canopy-runtime's compatibility value).

### E.5 — (future) Cross-client install path
Validates `gh skill install` to `.agents/skills/` (default on gh ≥ 2.91 with `--agent github-copilot`).

### E.6 — (future) Multi-step skill with subagent
Validates a canopy skill that declares `## Agent` and uses `EXPLORE >> context` — explore-schema parsing, subagent invocation contract.

---

## Suite F — `gh skill install` Matrix

**Validates:** install primitives across the supported `--agent` and pinning combinations.
**Parallelizable:** each scenario uses a unique sandbox.
**Prereqs:** gh CLI ≥ 2.90.

### F.1 — `--agent claude-code` → `.claude/skills/`
### F.2 — `--agent github-copilot` → `.github/skills/` (or `.agents/skills/` on gh ≥ 2.91)
### F.3 — `--pin <commit-SHA>` (40-hex)
### F.4 — `--pin <tag>` (e.g. `v0.18.0`)
### F.5 — `--pin <branch-name>` (resolves to branch HEAD; non-pinning)
### F.6 — `--scope project` vs `--scope user` (placement: project-local vs `~/.claude/skills/`)
### F.7 — Source path argument: bare name vs `skills/<name>` vs `.claude/skills/<name>`
### F.8 — `--allow-hidden-dirs` required when source is at `.claude/skills/...` and absent in default search paths
### F.9 — Re-install over existing — `--force` vs default behavior

---

## Suite G — Plugin Marketplace

**Validates:** the Claude Code plugin install path produces an equivalent result to `gh skill install` + manual activation.
**Parallelizable:** runs inside Claude Code, not a CI step. Manual.
**Prereqs:** Claude Code session.

### G.1 — Add marketplace + install plugin
- `/plugin marketplace add kostiantyn-matsebora/claude-canopy`
- `/plugin install canopy@claude-canopy`
- **Expected:** all three skills available as `/canopy:canopy`, `/canopy:canopy-debug`; canopy-runtime hidden from `/` menu.

### G.2 — First-load activation
On first session after install, runtime self-activates: marker block lands in `CLAUDE.md`.

### G.3 — `/plugin update` after marker block content change
Activation re-runs and replaces marker block (REPLACE branch of idempotent contract).

---

## Suite H — Plan Files & Skill Authoring (Round-trip)

**Validates:** the canopy authoring agent (`/canopy create`, `/canopy improve`, `/canopy convert-to-canopy`, etc.) produces spec-compliant output.
**Parallelizable:** each op runs against its own scratch skill; no shared state.
**Prereqs:** Claude Code with canopy installed.

### H.1 — `/canopy scaffold <name>` produces compliant skeleton
- Frontmatter root has only spec fields
- `compatibility` is a string declaring canopy-runtime + a locatable source
- Safety preamble present, structured (not mindflow)
- Standard layout (`scripts/`, `references/`, `assets/{templates,constants,schemas,checklists,policies,verify}/`)

### H.2 — `/canopy improve <legacy-skill>` migrates structured `compatibility`
Input has `compatibility: { requires: [canopy-runtime] }`; output has the canonical free-text form.

### H.3 — `/canopy convert-to-regular <canopy-skill>` strips canopy-specific fields
Output has no `## Tree`, no `## Rules`, no `## Response:`, no `compatibility` (when canopy-runtime was the only requirement), no safety preamble.

### H.4 — `/canopy validate <skill>` flags non-spec compatibility
Reject structured shapes; reject overlength values; hint when canopy-runtime not mentioned.

---

## Parallelization graph

```
A (install scripts)        ─┐
B (marker parity)          ─┤
D (static SKILL.md check)  ─┼─── all suites run in parallel
E (autonomous E2E)         ─┤    suite-internal scenarios also parallel
F (gh skill matrix)        ─┤    (each scenario uses a unique sandbox dir)
G (plugin marketplace) *   ─┤
H (canopy authoring) *     ─┘

* G and H require interactive Claude Code; others are CI-friendly.
```

Run all CI-friendly suites concurrently; gate the release on every suite's PASS. G and H run pre-release as smoke tests in a manual session. The VSCode extension's own suites (C1–C7) run in the extension repo's CI — independent of this framework.
