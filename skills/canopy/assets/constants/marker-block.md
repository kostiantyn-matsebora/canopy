# Canopy Runtime Marker Block

The canonical ambient instruction block written into `CLAUDE.md` (Claude Code) or `.github/copilot-instructions.md` (Copilot) — by canopy-runtime's Activation section on first load, by the ACTIVATE op, or by install scripts.

This content must remain byte-identical to `claude-canopy/install.sh build_marker_block()`, `install.ps1 Build-MarkerBlock`, and the VSCode extension's marker-block constant. Drift between the four is a bug — `scripts/validate.sh` checks parity in CI.

The marker is delimited by `<!-- canopy-runtime-begin -->` and `<!-- canopy-runtime-end -->` (HTML comment tags). The opening and closing markers must each be on their own line.

## Block content (between the markers, inclusive)

```
<!-- canopy-runtime-begin -->
## Canopy Runtime

Any `SKILL.md` under `.claude/skills/` or `.github/skills/` that declares a `## Tree`
section is a canopy-flavored skill. Before interpreting it, load
`<skills-root>/canopy-runtime/SKILL.md` and apply the execution model defined
there — sections (`## Agent`, `## Tree`, `## Rules`, `## Response:`), tree
notation (`<<`, `>>`, `|`), control-flow and interaction primitives, op lookup
chain (skill-local `references/ops.md` or `references/ops/<name>.md`, falling
back to legacy `ops.md` at root → consumer project ops → framework primitives),
category directory layout (`scripts/` for executable code, `references/` for
docs loaded on demand including ops, `assets/{templates,constants,schemas,
checklists,policies,verify}/` for static resources; legacy flat layout with
these dirs at skill root remains supported), subagent contract (`EXPLORE` as
first node when `## Agent` declares `**explore**`), and the active platform
runtime (`references/runtime-claude.md` or `references/runtime-copilot.md`).

`<skills-root>` resolves to `.claude/skills/` on Claude Code and `.github/skills/`
on Copilot.
<!-- canopy-runtime-end -->
```

## Idempotent write contract

Mirrors `install.sh write_marker_block()` and canopy-runtime's Activation section:

| Starting state of target file | Action | Result |
|---|---|---|
| Does not exist | CREATE | File created with only the marker block + trailing newline |
| Exists, no markers | APPEND | Block appended after a blank-line separator (if file doesn't already end on a newline, one is added first) |
| Exists, exactly one marker pair | REPLACE | Block content between (and including) the markers is rewritten; content outside the pair untouched |
| Exists, multiple marker pairs | REPLACE_FIRST + WARN | Only the first pair is rewritten; remaining pairs left in place; warn the user |
| Exists, marker count mismatch (begin ≠ end) | REFUSE | Print error pointing at the file; ask the user to fix manually before re-running |

Trailing-newline preservation: a file with no trailing newline before activation must end with a newline after activation. CRLF / LF line endings of existing content must be preserved (best-effort — re-encoding is allowed only inside the rewritten block).
