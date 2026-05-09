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
| **(Cross-repo) `claude-canopy-examples/.agents/skills/`** | A new feature that an existing example would showcase better than the old form (e.g. subagent dispatch retrofit on `parallel-review`) | Retrofit the affected example skill; bump `.canopy-version`; CHANGELOG entry. The retrofit lands as its own follow-up PR after the framework tag publishes (so vendored framework can be re-pinned) |

## How to apply

1. **Before opening a framework PR**, walk the table above and identify which demo-surface files need updates.
2. **Land in the same PR** (within `claude-canopy/`): docs example, CHEATSHEET, CONCEPTS, CHANGELOG. These are zero-risk and cheap to keep current.
3. **Open follow-up PRs** for cross-repo surfaces (`claude-canopy-vscode` snippets, `claude-canopy-examples` retrofits) — they ship in their own release cycles but should be queued the same day as the framework PR so the demo surface across repos doesn't drift.
4. **Visual review the rendered docs** — open the `## How it works` block in a browser-width preview; long lines (>80 chars in the code fence) trigger horizontal scroll on the cayman theme's `.skill-example pre` and make the example feel cramped. Trim the `compatibility:` / `description:` lines if needed.

## Anti-patterns this rule prevents

- **Stale "How it works" example.** Pre-S2 example used `## Agent` + `EXPLORE` + `* natural language: Cancelled by user.` — three legacy patterns at once, after the framework had moved past all of them.
- **Showcase example that misses the showcase.** The example should be dense with features; it's the first thing a reader sees. If it only shows `IF`/`ELSE`/`ASK` after we've shipped `SWITCH`/`PARALLEL`/subagent dispatch, the reader concludes Canopy is just markdown branching.
- **Examples-repo skill written in pre-feature style.** `parallel-review` shipped with prose subagent invocations under `PARALLEL`; the S2 retrofit promoted them to `**REVIEW_ASPECT**` bold call-sites. The retrofit is the canonical demo of the new dispatch model — without it, users had no reference implementation.
- **Horizontal scroll in code blocks.** `compatibility: <one-line manifesto with full URL and install paths>` overflows narrow viewports. Code blocks must keep every line short enough to not trigger overflow on the rendered theme.

## Enforcement

This rule is currently **documentation-only** — same caveat as `authoring-ops-sync.md`. If repeated drift recurs, candidates for automation:

- **Diff-checker in `scripts/validate.sh`** — when a PR touches `skills/canopy-runtime/references/framework-ops.md`, require it to also touch `docs/CHEATSHEET.md` and one of `docs/{index,README}.md`.
- **Line-length lint** on the `## How it works` code fence — fail CI if any line in the embedded skill exceeds 80 chars.
