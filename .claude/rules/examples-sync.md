---
paths:
  - "skills/canopy-runtime/references/framework-ops.md"
  - "skills/canopy-runtime/references/runtime-claude.md"
  - "skills/canopy-runtime/references/runtime-copilot.md"
  - "skills/canopy-runtime/references/skill-resources.md"
  - "docs/CONCEPTS.md"
  - "docs/CHEATSHEET.md"
  - "docs/README.md"
  - "docs/index.md"
---

# Rule: keep user-facing examples and snippets in sync with framework changes

Framework changes that add capability (new primitive, new section type, new dispatch mode, new tree-notation convention) must surface in the **user-facing demonstration surface** — the skill examples, snippets, and visual walkthroughs readers see before they read the spec. Without this, the framework gains a feature that no one discovers.

## Why

The Canopy framework has three surfaces; the [authoring-ops-sync rule](authoring-ops-sync.md) covers the first two:

1. **Runtime** — what the runtime understands and executes
2. **Authoring agent** — what `/canopy create`/`improve`/`validate` knows about

But there's a third surface — the **demo surface** — that authoring-ops-sync doesn't cover:

3. **User-facing examples** — what readers and users actually *see* in docs, snippets, and example skills

A change that lands in the runtime + authoring surface but not the demo surface is technically working but invisible. Users browsing the GH Pages site, reading the README, or using the vscode snippets see the **old** way of doing things and write skills that look pre-feature. The S2 retrofit was the canonical case: subagent dispatch shipped to the runtime + authoring agent, but the docs "How it works" example, the examples-repo `parallel-review` skill, and the vscode snippets all still showed the legacy `## Agent` + `EXPLORE` form.

## What to update — by surface

| Surface | When to touch | What to update |
|---|---|---|
| **`docs/index.md` + `docs/README.md` "How it works" skill example** | Any new primitive, dispatch mode, or tree-notation convention worth showcasing. The example should reflect the **current canonical form** of a Canopy skill — not the legacy form. | Rewrite the embedded code block; update the trailing caption ("Subagent dispatch via …, multi-way `SWITCH/CASE`, …") to name the features actually shown |
| **`docs/CHEATSHEET.md`** | Any new primitive or convention | Add a row / section. Cheatsheet is the one-page reference; missing primitives mean readers learn an incomplete subset |
| **`docs/CONCEPTS.md`** | New section type, new dispatch mode, new execution-model concept | Add a narrative subsection; update the skill-anatomy walkthrough if section types changed |
| **`docs/CHANGELOG.md`** | Every framework release | Prepend a release block per `versioning.md` |
| **(Cross-repo) `claude-canopy-vscode/snippets/canopy.json`** | New primitive, new tree-notation convention | Add a snippet (e.g. `parallel`, `switch`, `op-subagent`, `call-subagent`). Tracked in the extension's `keep-in-sync.md` rule too — flagging here so framework-side authors know the snippet update belongs in the same release window |
| **(Cross-repo) `claude-canopy-examples/.agents/skills/`** | **Every** new capability in canopy. The examples repo is the live demonstration surface — every primitive, dispatch mode, and section type should be exercised by at least one skill there. | Decide per the table below; bump `.canopy-version`; CHANGELOG entry; update the **feature coverage matrix** in `claude-canopy-examples/CLAUDE.md` (mark the new column ✓ for the skill that adopts it). The retrofit lands as its own follow-up PR after the framework tag publishes (so vendored framework can be re-pinned). |

## How to apply

1. **Before opening a framework PR**, walk the table above and identify which demo-surface files need updates.
2. **Land in the same PR** (within `claude-canopy/`): docs example, CHEATSHEET, CONCEPTS, CHANGELOG. These are zero-risk and cheap to keep current.
3. **Open follow-up PRs** for cross-repo surfaces (`claude-canopy-vscode` snippets, `claude-canopy-examples` retrofits) — they ship in their own release cycles but should be queued the same day as the framework PR so the demo surface across repos doesn't drift.
4. **Visual review the rendered docs** — open the `## How it works` block in a browser-width preview; long lines (>80 chars in the code fence) trigger horizontal scroll on the cayman theme's `.skill-example pre` and make the example feel cramped. Trim the `compatibility:` / `description:` lines if needed.

## Cross-repo coverage — `claude-canopy-examples`

The examples repo's job is to be the live demonstration of canopy's capability set. Every primitive, dispatch mode, and section type should be exercised by **at least one** skill there. A feature with **zero demos** is a coverage gap and a future-author-misleads-themselves trap.

**Decision flow for which skill to touch when canopy ships a feature:**

| Canopy change | What to do in `claude-canopy-examples` |
|---|---|
| **New primitive** (e.g. `PARALLEL` v0.19, `SWITCH` v0.13) | Retrofit the smallest existing skill where the primitive fits naturally. If no fit exists, add a small new skill whose entire purpose is to demo the primitive (e.g. `parallel-review` was added to demo `PARALLEL`). |
| **New dispatch mode / convention** (e.g. subagent dispatch markers in v0.20) | Retrofit one example that benefits from the new form. Don't migrate every skill — leaving some on soft-compat also tests soft-compat. (S2 retrofitted `parallel-review` only.) |
| **New section type** | Add a focused demo skill — section types are visible in skill anatomy and warrant their own example. |
| **New schema convention** (e.g. universal input contracts, S3) | Retrofit one subagent-using skill (likely `parallel-review`); update the matrix. |
| **Renaming / removal** | Audit every skill for the removed name. Migrate or fix; update the matrix. |
| **Bug fix or perf change** | No example change unless the fix exposes a previously broken pattern that examples should now demonstrate. |

**Demonstration rules** (so coverage stays honest):

- The use must be **execution-bearing**, not a passing prose mention. `parallel-review`'s `**REVIEW_ASPECT**` counts; `<!-- TODO PARALLEL -->` doesn't.
- The use must be **idiomatic** — the way a real author would write it, not a toy stub. `* PARALLEL` over a single child is not idiomatic.
- The surrounding skill must have a **realistic reason** to use the feature. If you can't find one, add a tiny new skill rather than corrupting an existing one — these skills are also installation tests.
- **Don't kitchen-sink any single skill.** Each skill should be a real workflow that *happens to* use specific features. Coverage gets added by **adding skills**, not by inflating individual ones.

The coverage matrix in `claude-canopy-examples/CLAUDE.md` ("Feature coverage matrix" section) is the source of truth. Update the column for the affected skill in the same PR that retrofits it. Tracked gaps belong below the matrix as candidates for future examples.

**PR-body shape for example PRs** — state which features the skill demonstrates and confirm the matrix is updated:

> **Demonstrates:** `PARALLEL` (v0.19), subagent dispatch markers (v0.20), `assets/schemas/` contract.
> **Coverage matrix:** updated `parallel-review` row; subagent dispatch markers ✓.

## Anti-patterns this rule prevents

- **Stale "How it works" example.** Pre-S2 example used `## Agent` + `EXPLORE` + `* natural language: Cancelled by user.` — three legacy patterns at once, after the framework had moved past all of them.
- **Showcase example that misses the showcase.** The example should be dense with features; it's the first thing a reader sees. If it only shows `IF`/`ELSE`/`ASK` after we've shipped `SWITCH`/`PARALLEL`/subagent dispatch, the reader concludes Canopy is just markdown branching.
- **Examples-repo skill written in pre-feature style.** `parallel-review` shipped with prose subagent invocations under `PARALLEL`; the S2 retrofit promoted them to `**REVIEW_ASPECT**` bold call-sites. The retrofit is the canonical demo of the new dispatch model — without it, users had no reference implementation.
- **Coverage gap silently lingers.** Canopy ships `PARALLEL`, but no example uses it for two months → users learning by example write multi-aspect logic with sequential prose subagent calls because they see no other pattern. Closed in practice by adding `parallel-review` in the same release window, but the failure mode is silent — the coverage matrix is what makes it loud.
- **Horizontal scroll in code blocks.** `compatibility: <one-line manifesto with full URL and install paths>` overflows narrow viewports. Code blocks must keep every line short enough to not trigger overflow on the rendered theme.

## Enforcement

This rule is currently **documentation-only** — same caveat as `authoring-ops-sync.md`. If repeated drift recurs, candidates for automation:

- **Diff-checker in `scripts/validate.sh`** — when a PR touches `skills/canopy-runtime/references/framework-ops.md`, require it to also touch `docs/CHEATSHEET.md` and one of `docs/{index,README}.md`.
- **Line-length lint** on the `## How it works` code fence — fail CI if any line in the embedded skill exceeds 80 chars.
