---
paths:
  - "docs/**/*.md"
  - "README.md"
  - "skills/**/*.md"
---

# Rule: avoid horizontal scrolling in documentation

Horizontal scroll on a code block, ASCII diagram, or table makes the reader work for content the writer should have packed in. Default to vertical: write to wrap naturally, not to overflow.

## Where it bites

| Surface | Renders at | Lines wider than … cause scroll |
|---|---|---|
| GitHub `README.md` (file viewer) | ~80–90 chars in code blocks | **~75 chars** to be safe |
| GitHub Pages (cayman theme) `pre` | ~80 chars at desktop, less when sidebar visible | **~75 chars** |
| GitHub Pages, `.skill-example pre` (font-size: 0.72em) | wider effective budget but still bounded | **~80 chars** |
| VSCode markdown preview | varies by panel width | **~70 chars** for 50/50 splits |

The narrowest rendering wins. Aim for **≤75 chars per line in any code fence, ASCII diagram, or table cell** unless the content genuinely cannot be wrapped.

## What to do

- **Code fences (```` ``` ````)**: keep every line ≤ 75 chars. Include the indent / tree-art prefix in the count — `│   ├── ` already eats 8 chars. Verify by piping through `awk '{print length, $0}' file | sort -nr | head`.
- **ASCII tree diagrams**: tighten the per-leaf prose, not the structure. Drop adjectives, drop parenthetical list extensions, drop URLs (move to surrounding prose if needed). Don't sacrifice the tree shape — that's what makes the diagram readable.
- **Long URLs**: prefer the short `owner/repo` form when the surrounding context already implies "GitHub". Reserve full `https://github.com/owner/repo` for surrounding prose, not code blocks.
- **Inline `compatibility:` / `description:` fields in skill examples**: cap at ~75 chars. The full canonical form belongs in real skills, not in teasers.
- **Tables**: a 5-column matrix at wide column widths overflows even narrow viewports. If a row would wrap awkwardly, switch to a labeled bulleted list. Tables shine for **two-axis** lookups; nested 3+ axes belong in lists.
- **Skill code examples**: SKILL.md teaser content is the most common offender — long `compatibility:` lines and verbose op signatures both blow past 80 chars. Trim mercilessly; the example is to *introduce*, not to *exhaustively configure*.

## Anti-patterns this rule catches

- The pre-S2 "How it works" example in `docs/{index,README}.md` — a 152-char `compatibility:` line.
- The pre-fix "Why Canopy?" tree in `docs/README.md` — a 178-char workflow-engines line, 152-char "nothing canopy-specific leaks" line, 124-char agentskills-native line.
- Wide tables in cheatsheet / reference docs that wrap weirdly on narrow viewports — convert to nested bullet lists.
- Pasting full GitHub URLs (`https://github.com/kostiantyn-matsebora/canopy`) inside ASCII art when `kostiantyn-matsebora/canopy` would suffice.

## How to verify before committing

Quick check on any docs file you're editing:

```bash
awk '{print length, $0}' <file> | sort -nr | head -10
```

Anything > 75 chars in a code fence is a candidate for tightening (prose lines outside fences are fine — markdown viewers wrap them).

For ASCII trees specifically, count from column 0 — the tree-art chars (`│`, `├`, `└`) are part of the line budget, not free.

## Why this matters

Documentation is the first thing a new user touches. A horizontal scrollbar reads as "this project doesn't sweat the details." We want the opposite signal: that the project is precise, tight, and respects the reader's eye.
