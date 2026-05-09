---
paths:
  - "skills/canopy-runtime/**/*.md"
  - "skills/canopy/**/*.md"
  - "skills/canopy-debug/**/*.md"
  - "skills/canopy-runtime/**/*.json"
  - "skills/canopy/**/*.json"
  - "skills/canopy-debug/**/*.json"
  - "install.sh"
  - "install.ps1"
  - "docs/TEST_SCENARIOS.md"
---

# Rule: keep TEST_SCENARIOS in sync with skill / runtime / installer changes

`docs/TEST_SCENARIOS.md` is the canonical inventory of behavioral tests for the framework — install paths, marker-block parity, static `SKILL.md` validation, autonomous-agent E2E, `gh skill install` matrix, plugin marketplace, authoring ops, `PARALLEL`, subagent dispatch, context optimization. It's the truth source for **what's tested** and **what changed enough to need new coverage**.

Every framework change that adds, removes, or changes user-observable behavior must be reflected here in the same PR. Otherwise the test surface drifts behind reality and we ship features whose only verification is "the author tried it once."

## What kinds of change require a TEST_SCENARIOS update

| Change | Update required |
|---|---|
| New primitive in `references/ops/<slice>.md` | New scenario in the suite that owns the primitive's category (Suite I for `PARALLEL`, Suite J for subagent, etc.); or a new suite if the primitive opens a new feature category |
| New op in `skills/canopy/references/ops/` | New `H.<n>` scenario covering invocation phrase, seed, pass criteria, failure modes |
| New section type in `SKILL.md` (e.g. `## Agents`) | New scenarios in Suite D (static validation) + Suite J (or wherever the section's runtime semantics live) |
| New dispatch mode | New suite or scenarios under existing suite covering happy path + every mismatch / drift case |
| New tree-notation convention (e.g. `**OP**` for subagent dispatch) | Suite D static checks for the convention; Suite J runtime checks |
| New install path (`gh skill`, plugin marketplace, install script flag) | Suite A or F additions |
| New marker block content | Suite B (marker parity check) — verify after the parity script catches up |
| New frontmatter rule | Suite D check |
| Removal of any of the above | Remove the obsolete scenarios; do not let dead checks linger as "this no longer applies" comments |
| Version bump (across the 7 sources of truth) | Update the "Coverage by feature epoch" table at the top with the new epoch row |

## How to apply

1. **Before opening a PR**, walk the table above and identify which scenarios need additions, modifications, or removals.
2. **Land in the same PR** as the framework change. The gap between framework merge and test-scenario update is exactly when regressions slip in unseen.
3. **Run the affected scenarios** post-merge as part of release smoke testing. CI-friendly suites (A, B, D, E, F, K static checks) run automatically; manual suites (G, H, I, J interactive) get a pre-release dry run.

## Anti-patterns this rule prevents

- **A new primitive ships without scenarios.** `PARALLEL` shipped in v0.19.0 but Suite I didn't exist until v0.21.0 — three releases of pure self-trust. Scenarios let reviewers and downstream consumers verify behavior independent of the original author.
- **Manifest drift goes uncaught.** v0.21.0 introduces `metadata.canopy-features` — Suite K validates every drift case (declared but unused, used but undeclared, `core` listed, unknown values). Without those scenarios, only `/canopy validate` (which the rule itself defines) checks the rule — circular validation.
- **Dead test scenarios linger.** When a feature is removed, the corresponding scenarios must go too. Leaving them as TODO-style comments creates the illusion of coverage while the underlying behavior no longer exists.

## Cross-repo

- The vscode extension has its own `docs/TEST_SCENARIOS.md` covering parsing, diagnostics, hover, goto, snippets, and Extension Development Host smoke tests. That file's sync rule lives in `claude-canopy-vscode/.claude/rules/`.
- This rule covers `claude-canopy/docs/TEST_SCENARIOS.md` only.
- Suite C in this file is intentionally a single-paragraph cross-reference to the extension's own scenarios — they don't live here.

## Enforcement

This rule is currently **documentation-only**. If repeated drift recurs:

- **Diff-checker in `scripts/validate.sh`** — when a PR touches any file under `skills/canopy-runtime/references/`, `skills/canopy/references/ops/`, or `install.{sh,ps1}`, require it to also touch `docs/TEST_SCENARIOS.md` (or carry a `[skip-test-scenarios]` opt-out token in the commit body for genuinely test-coverage-irrelevant changes).
