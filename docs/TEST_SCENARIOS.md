# Canopy Test Scenarios

Test suites covering canopy 0.22.0 spec compliance, install paths, and runtime behavior. Suites are the parallelization unit — every suite is fully isolated and may run concurrently with any other suite. Scenarios within a suite generally parallelize too (each gets its own sandbox); exceptions are flagged.

## Coverage by feature epoch

| Epoch | Feature | Suites |
|---|---|---|
| 0.18.0 | agentskills.io standard layout, marker-block parity, install scripts | A, B, D, F, G |
| 0.19.0 | `PARALLEL` primitive (S1) — heterogeneous parallel-subagent fan-out | I (new) |
| 0.20.0 | Subagent dispatch model (S2) — per-op markers + bold call-sites | J (new) |
| 0.21.0 | Context optimization — slim marker block, sliced primitive spec, per-skill `metadata.canopy-features` manifest, `MEASURE_CONTEXT` op | K (new); H.12 (new MEASURE_CONTEXT) |
| 0.22.0 | Universal op contracts (S3) — bare `> **Input/Output contract:**` markers on inline ops, `metadata.canopy-contracts: strict` opt-in runtime enforcement, `/canopy improve --scaffold-contracts` schema generator | L (new); D additions (universal-marker static checks) |

## Conventions

- **Sandbox** — every install/runtime scenario runs in a unique workspace under `$TMPDIR/canopy-<suite>-<scenario>/`. Workspaces are wiped before each run.
- **Refs** — `<canopy-ref>` is a branch, tag, or commit on `kostiantyn-matsebora/canopy`. `<examples-ref>` is the same on `kostiantyn-matsebora/canopy-examples`. For pre-release testing use `agentskills-compatibility` and `e2e-preview`.
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
  - `canopy/skills/canopy-runtime/assets/constants/marker-block.md` (canonical home since 0.18.0)
  - `canopy-vscode/src/commands/installCanopy.ts` `MARKER_BLOCK` constant
  - `canopy/install.sh` `build_marker_block()` heredoc
  - `canopy/install.ps1` `Build-MarkerBlock` here-string
- **Failure modes:** any source diverges; the script prints a unified diff against canonical and exits 1.

---

## Suite C — VSCode Extension

The extension is a separate repo with its own test surface. See [`canopy-vscode/docs/TEST_SCENARIOS.md`](https://github.com/kostiantyn-matsebora/canopy-vscode/blob/master/docs/TEST_SCENARIOS.md) — covers TypeScript compile, vitest unit suite (323+ tests), per-command handler tests, compatibility-shape diagnostics, real-skills snapshot, marker-block parity (extension side), Extension Development Host smoke tests, and the marketplace publish gate.

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
- `/plugin marketplace add kostiantyn-matsebora/canopy`
- `/plugin install canopy@canopy`
- **Expected:** all three skills available as `/canopy:canopy`, `/canopy:canopy-debug`; canopy-runtime hidden from `/` menu.

### G.2 — First-load activation
On first session after install, runtime self-activates: marker block lands in `CLAUDE.md`.

### G.3 — `/plugin update` after marker block content change
Activation re-runs and replaces marker block (REPLACE branch of idempotent contract).

---

## Suite H — Canopy Authoring Ops (E2E)

**Validates:** the canopy authoring skill executes each of its 11 ops correctly against seeded inputs and produces spec-compliant output.
**Parallelizable:** each op gets its own sandbox + subagent. Run as 3 batches × 3–4 parallel agents (token-efficient version of the previous Monitor-tail pattern; see plan `canopy-e2e-all-ops-parallel`).
**Prereqs:** gh CLI ≥ 2.90; ability to spawn background subagents; the `canopy` + `canopy-runtime` skills installable via `gh skill install ... --pin <SHA>`.

### Execution pattern

Per-op sandbox under `$TMPDIR/canopy-e2e-<op>/`:
- agent installs `canopy-runtime` and `canopy` via pinned `gh skill install`
- agent activates runtime in `<sandbox>/CLAUDE.md`
- agent invokes the op with the matrix invocation phrase
- agent self-verifies pass criteria and writes `RESULT.json` — schema `{"op","status","files_changed","errors"}` (errors capped at 5)
- parent reads only `RESULT.json`; transcripts (`AGENT_TRANSCRIPT.md`) read only on FAIL

Shared instructions (transcript labels, RESULT.json schema, anti-patterns) live in a single file referenced by every per-op prompt — avoids re-inlining preamble per agent.

### H.1 — HELP
**Invocation:** "help". **Seed:** empty. **Pass:** response names all 12 ops (CREATE, SCAFFOLD, MODIFY, VALIDATE, IMPROVE, CONVERT_TO_CANOPY, CONVERT_TO_REGULAR, REFACTOR_SKILLS, ADVISE, ACTIVATE, MEASURE_CONTEXT, HELP).

### H.2 — ACTIVATE
**Invocation:** "activate". **Seed:** sandbox `CLAUDE.md` containing `# Project`. **Pass:** marker block appended between `<!-- canopy-runtime-begin -->` / `<!-- canopy-runtime-end -->`; outer content preserved.

### H.3 — SCAFFOLD
**Invocation:** "scaffold a blank skill called probe". **Seed:** empty. **Pass:** `.claude/skills/probe/SKILL.md` exists; `references/ops.md` exists; no `ops.md` at skill root.

### H.4 — CREATE
**Invocation:** "create a skill that pings a URL and reports HTTP status". **Seed:** empty. **Pass:** new skill with `## Tree`, free-text `compatibility`, runtime safety preamble.

### H.5 — MODIFY
**Invocation:** "add a dry-run option to probe". **Seed:** canopy-flavored `probe` skill (valid SKILL.md with `## Tree`, `references/ops.md`). **Pass:** `## Tree` gains a node referencing dry-run; SKILL.md still parses.

### H.6 — ADVISE
**Invocation:** "advise on adding a verify step to probe". **Seed:** canopy-flavored `probe` skill. **Pass:** `files_changed: 0` (read-only op); advisory text in transcript.

### H.7 — VALIDATE
**Invocation:** "validate probe-good", "validate probe-bad". **Seed:** `probe-good` (valid) and `probe-bad` (intentionally invalid: structured `compatibility:` block-form map instead of free-text). **Pass:** clean run on probe-good; ≥1 error on probe-bad flagging the compatibility shape.

### H.8 — IMPROVE
**Invocation:** "improve probe-legacy". **Seed:** `probe-legacy` with flat layout (root `templates/`, `commands/`, `ops.md`; SKILL.md missing `compatibility`). **Pass:** layout migrated to `assets/templates/`, `scripts/`, `references/ops.md`; `compatibility` field added.

### H.9 — CONVERT_TO_CANOPY
**Invocation:** "convert probe-prose to canopy". **Seed:** plain-markdown skill (no `## Tree`, no compatibility, no preamble). **Pass:** `## Tree` added; `compatibility` added; safety preamble added. Original may be retained as `SKILL.classic.md`.

### H.10 — CONVERT_TO_REGULAR
**Invocation:** "convert probe-canopy back to regular". **Seed:** canopy-flavored skill. **Pass:** `## Tree`, `compatibility`, and runtime safety preamble all removed.

### H.11 — REFACTOR_SKILLS
**Invocation:** "refactor skills — extract shared ops". **Seed:** `probe-a` and `probe-b`, both canopy-flavored, each with an identical op in `references/ops.md`. **Pass:** a new installable skill (e.g. `probe-shared-ops`) exists with the extracted op + its own `compatibility`; both source skills reference it via `compatibility`; the duplicate op is removed/replaced with a pointer.

### H.12 — MEASURE_CONTEXT
**Invocation:** "measure context for probe". **Seed:** canopy-flavored `probe` skill with `metadata.canopy-features: [interaction, verify]`. **Pass:** report names every load source (marker block, runtime SKILL.md, skill-resources, runtime-{claude|copilot}, slice:core, slice:interaction, slice:verify, skill, ops, any read-refs); reports per-source line counts; reports a TOTAL. **Failure modes:** declared slices not loaded; un-declared slices loaded (drift not detected); missing files counted as zero without a note.

---

## Suite I — `PARALLEL` Primitive (canopy 0.19.0+)

**Validates:** the `PARALLEL` block primitive — heterogeneous parallel-subagent fan-out — emits the right tool calls per platform and aggregates child bindings.
**Parallelizable:** each scenario uses a unique sandbox + invokes the `parallel-review` example skill.
**Prereqs:** canopy 0.19.0+ runtime; `parallel-review` example installed; Claude Code or Copilot with subagent surface.

### I.1 — Three children, all marker-based subagent calls (Claude)
- **Setup:** sandbox with `parallel-review` skill.
- **Steps:** invoke `parallel-review` against a small directory.
- **Expected:** in a single assistant turn, the agent emits multiple `Task` tool calls (one per `**REVIEW_ASPECT**` child); each subagent returns JSON shaped to `aspect-findings-schema.json`; bindings merged in declaration order.
- **Failure modes:** sequential `Task` calls (one assistant turn per child); aggregated output missing aspects; `Promise.allSettled` semantics not honored on simulated child failure.

### I.2 — Three children, sequential-inline fallback (Copilot, no fleet)
- **Setup:** Copilot session, no `/fleet` active, no `@CUSTOM-AGENT-NAME` defined.
- **Steps:** same invocation.
- **Expected:** runtime falls back to evaluating each child sequentially in-context; final aggregated report identical to I.1.
- **Failure modes:** runtime errors instead of falling back; bindings lost.

### I.3 — Plain (un-bold) children inside `PARALLEL`
- **Setup:** synthetic skill with `PARALLEL` whose children are plain `OP_NAME << ... >> ...` (no bold).
- **Expected:** runtime executes children inline, sequentially within the same turn; warning that `PARALLEL` over inline children loses fan-out benefit (informational, not error).

### I.4 — `PARALLEL` with one child (degenerate)
- **Setup:** synthetic skill with `PARALLEL` containing exactly one child.
- **Expected:** vscode flags `PARALLEL` with <2 children as a hint; runtime executes the child as a no-op fan-out (degenerate but legal).

---

## Suite J — Subagent Dispatch (canopy 0.20.0+)

**Validates:** the per-op subagent dispatch model — `> **Subagent.**` op-def marker + `**OP_NAME**` bold call-site, with the strict-contract rule on subagent op bodies.
**Parallelizable:** each scenario uses a unique sandbox.
**Prereqs:** canopy 0.20.0+ runtime; `parallel-review` example for the happy path; synthetic skills for negative cases.

### J.1 — Marker + bold call agree (happy path)
- **Setup:** `parallel-review` (post-S2 retrofit). `references/ops.md` has `## REVIEW_ASPECT << ... >>` with `> **Subagent.** Output contract: <schema>` blockquote; SKILL.md tree calls `**REVIEW_ASPECT** << ... >>` (bold).
- **Expected:** runtime dispatches the body as a subagent; output JSON validated against schema; bound to the `>>` name.

### J.2 — Bold call without op-def marker (mismatch)
- **Setup:** synthetic skill with `**FOO** << x >> y` in the tree, but `## FOO` definition has no `> **Subagent.**` blockquote.
- **Expected:** `/canopy validate` reports a bidirectional-mismatch error; runtime halts with a contract-mismatch diagnostic when invoked.

### J.3 — Op-def marker without any bold call-site (mismatch)
- **Setup:** synthetic skill with `## FOO << x >> y` carrying `> **Subagent.**` but every call site is plain `FOO << x >> y` (no bold).
- **Expected:** `/canopy validate` reports a bidirectional-mismatch error.

### J.4 — Subagent op body uses ambient `context.*` (strict-contract violation)
- **Setup:** synthetic skill where `## FOO << bar >>` is marked `> **Subagent.**` but its body references `context.baz` (where `baz` is not in the `<<` signature).
- **Expected:** `/canopy validate` reports a strict-contract violation error.

### J.5 — Output schema file missing
- **Setup:** synthetic skill where the marker references `assets/schemas/missing.json` but the file doesn't exist.
- **Expected:** `/canopy validate` reports missing-schema error; runtime halts on dispatch.

### J.6 — Soft-compat: `## Agent` + `EXPLORE >> context`
- **Setup:** legacy skill with `## Agent` declaring `**explore**` and `EXPLORE >> context` as the first tree node.
- **Expected:** runtime treats this as an implicit single-element marked op named `EXPLORE`; output bound to `context` per `assets/schemas/explore-schema.json`. Runs unchanged on canopy 0.20.0+.

### J.7 — Marker-based children inside `PARALLEL` (composition)
- **Setup:** `parallel-review` (canonical). PARALLEL block has 4 bold-marked children.
- **Expected:** runtime emits 4 parallel subagent invocations; each binds its `>>` to the schema-shaped result; aggregation honors declaration order.

---

## Suite K — Context Optimization (canopy 0.21.0+)

**Validates:** the slim marker block, sliced primitive spec, per-skill `metadata.canopy-features` manifest, and the `MEASURE_CONTEXT` op together cut the canopy tax proportional to feature usage.
**Parallelizable:** each scenario uses a unique sandbox.
**Prereqs:** canopy 0.21.0+ runtime.

### K.1 — Slim marker block content
- **Setup:** install canopy 0.21.0 to a fresh project.
- **Steps:** read the marker block written into `CLAUDE.md` (or `.github/copilot-instructions.md`).
- **Expected:** block is ~5 lines (markers + 1 heading + 1 content paragraph); references `<skills-root>` resolution + pointer to `canopy-runtime/SKILL.md`; does NOT inline primitives, op-lookup chain, or category list.
- **Failure modes:** legacy 30-line block written; spec content inlined.

### K.2 — Slice index + per-feature slice files exist
- **Setup:** installed canopy 0.21.0.
- **Expected:** `references/ops.md` (index) exists; `references/ops/{core,interaction,control-flow,parallel,subagent,explore,verify}.md` all exist; `references/framework-ops.md` does NOT exist (deleted in v0.21.0).

### K.3 — Manifest-aware load (per-skill `metadata.canopy-features`)
- **Setup:** synthetic skill `tiny` with `metadata.canopy-features: [interaction, verify]`. Tree uses only `IF`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`.
- **Expected:** when invoked, the runtime reads `ops/core.md` (always), `ops/interaction.md`, `ops/verify.md`, `runtime-{claude|copilot}.md`, `skill-resources.md`, `canopy-runtime/SKILL.md`, marker block, and the skill's own files. Slices `control-flow`, `parallel`, `subagent`, `explore` are NOT loaded.
- **Failure modes:** all slices loaded despite manifest; declared slices skipped.

### K.4 — Manifest absent (back-compat fallback)
- **Setup:** legacy skill (canopy 0.20.x) with no `metadata.canopy-features` manifest.
- **Expected:** runtime falls back to loading every slice under `ops/`. Skill executes correctly. `/canopy validate` warns "manifest absent — load-everything fallback"; never errors.

### K.5 — Manifest drift (declared but unused)
- **Setup:** synthetic skill with `metadata.canopy-features: [interaction, parallel]` but tree uses no `PARALLEL`.
- **Expected:** `/canopy validate` warns: "Declared feature `parallel` not used in tree".

### K.6 — Manifest drift (used but undeclared)
- **Setup:** synthetic skill with `metadata.canopy-features: [interaction]` but tree contains `**FOO** << x >> y` (subagent dispatch).
- **Expected:** `/canopy validate` warns: "Used feature `subagent` not declared in manifest".

### K.7 — `core` listed in manifest (implicit-always-loaded)
- **Setup:** synthetic skill with `metadata.canopy-features: [core, interaction]`.
- **Expected:** `/canopy validate` warns: "`core` is implicit-always-loaded — remove from manifest".

### K.8 — Unrecognized feature value
- **Setup:** synthetic skill with `metadata.canopy-features: [interaction, dispatch-magic]`.
- **Expected:** `/canopy validate` warns: "Unknown feature `dispatch-magic` — valid values: interaction, control-flow, parallel, subagent, explore, verify".

### K.9 — `/canopy create` emits a manifest matching the produced tree
- **Setup:** invoke `/canopy create a skill that asks the user a question and verifies the result`.
- **Expected:** produced SKILL.md has `metadata.canopy-features: [interaction, verify]` (or equivalent set matching the produced tree).

### K.10 — `/canopy improve` proposes a manifest where missing
- **Setup:** legacy skill without manifest.
- **Steps:** invoke `/canopy improve <skill>`.
- **Expected:** decision table contains a row with action `add-canopy-features-manifest` and the inferred feature set.

### K.11 — `/canopy measure-context <skill>` reports a breakdown
- **Setup:** any canopy-flavored skill with a manifest.
- **Steps:** invoke `/canopy measure-context <skill>`.
- **Expected:** report names every load source (marker block, runtime SKILL.md, skill-resources, runtime-platform, slice:core, declared slices, skill, ops, read-refs); reports per-source line counts; reports a TOTAL. No file mutations. (Same as H.12.)

### K.12 — Marker-block parity (4-source check post-trim)
- **Setup:** clean working tree post-v0.21.0.
- **Steps:** compare `marker-block.md` canonical content with `install.sh` `build_marker_block()` heredoc, `install.ps1` `Build-MarkerBlock` here-string, and `canopy-vscode/src/commands/installCanopy.ts` `MARKER_BLOCK` constant.
- **Expected:** four sources byte-identical. (Vscode mirror updated in the follow-up extension PR; before that lands, the framework-side three must agree.)

---

## Suite L — Universal op contracts (canopy 0.22.0+)

Covers S3 — universal `> **Input contract:** \`...\`` / `> **Output contract:** \`...\`` markers on inline ops, the `metadata.canopy-contracts: strict` runtime opt-in, and the `/canopy improve --scaffold-contracts` schema generator. Authoring-time static checks (binding-graph drift, schema-shape drift) live in the vscode extension's own scenarios — Suite C cross-references them.

### L.1 — `/canopy validate` flags missing contract schema files
- **Setup:** an inline op definition with `> **Output contract:** \`assets/schemas/missing.json\`` but no schema file present.
- **Steps:** `/canopy validate <skill>`.
- **Expected:** error reported naming the missing file path. Same severity as the existing subagent-marker missing-schema error — the universal-marker check does not double-flag subagent ops.

### L.2 — `/canopy validate` flags strict-mode without contracts
- **Setup:** SKILL.md with `metadata.canopy-contracts: strict` but no op carries a contract marker.
- **Steps:** `/canopy validate <skill>`.
- **Expected:** warning reported ("strict mode tightens nothing").

### L.3 — `/canopy validate` flags unrecognized canopy-contracts value
- **Setup:** SKILL.md with `metadata.canopy-contracts: lenient` (or any value other than `strict`).
- **Steps:** `/canopy validate <skill>`.
- **Expected:** error reported listing recognized values (`strict`).

### L.4 — `/canopy improve --scaffold-contracts` generates initial schemas
- **Setup:** existing skill with no contract markers; ops have stable `<<` / `>>` named-field signatures.
- **Steps:** `/canopy improve <skill>` and accept the `scaffold-contracts` action in the decision table.
- **Expected:** `assets/schemas/<op-name>-input.json` and `<op-name>-output.json` created for each scaffolded op; `properties` mirror the named `<<` / `>>` fields; `additionalProperties: true`; every property starts as `type: string`. Op definitions gain bare `> **Input contract:**` / `> **Output contract:**` blockquote markers. Re-running validate reports clean.

### L.5 — Strict-mode runtime halts on contract violation
- **Setup:** parallel-review skill (vendored in canopy-examples at v0.8.0+) — has contracts on every op + `metadata.canopy-contracts: strict`. Force a `REVIEW_ASPECT` invocation with malformed `aspect` (e.g. `"unknown"` instead of one of the four enum values).
- **Steps:** invoke the skill on a small target.
- **Expected:** runtime halts before the subagent fires; emits `[contract-violation]` error citing the offending op + the schema property whose constraint failed. Skill produces no partial output.

### L.6 — Default mode (no canopy-contracts) ignores contracts at runtime
- **Setup:** a skill with contract markers on its ops but no `metadata.canopy-contracts` declared.
- **Steps:** invoke the skill with a deliberately malformed input.
- **Expected:** runtime executes normally — contracts are descriptive only when strict mode is not declared. vscode static analysis still flags the malformed input at authoring time.

### L.7 — Universal contract markers on inline ops parse identically to subagent contracts
- **Setup:** an `ops.md` with one inline op carrying `> **Input contract:** \`x.json\`` (bare blockquote) and one subagent op carrying `> **Subagent.** Input contract: \`y.json\``.
- **Expected:** both populate `inputContract` on their respective `OpDefinition`. Only the subagent op carries `isSubagent: true`. Vscode's parser-level test (`parseDocument — universal contract markers`) is the authoritative coverage — Suite C handles this.

---

## Parallelization graph

```
A (install scripts)        ─┐
B (marker parity)          ─┤
D (static SKILL.md check)  ─┤
E (autonomous E2E)         ─┤
F (gh skill matrix)        ─┼─── all suites run in parallel
G (plugin marketplace) *   ─┤    suite-internal scenarios also parallel
H (canopy authoring) *     ─┤    (each scenario uses a unique sandbox dir)
I (PARALLEL primitive) *   ─┤
J (subagent dispatch) *    ─┤
K (context optimization)   ─┤
L (universal contracts) *  ─┘

* G, H, I, J, L require interactive Claude Code or a Copilot session for runtime invocation; others are CI-friendly.
```

Run all CI-friendly suites concurrently; gate the release on every suite's PASS. G/H/I/J/L run pre-release as smoke tests in a manual session. The VSCode extension's own suites (C1–C7) run in the extension repo's CI — independent of this framework.
