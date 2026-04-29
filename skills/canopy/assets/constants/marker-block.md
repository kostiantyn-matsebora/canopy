# Canopy Runtime Marker Block

The canonical ambient instruction block written into `CLAUDE.md` (Claude Code) or `.github/copilot-instructions.md` (Copilot) — by canopy-runtime's Activation section on first load, by the ACTIVATE op, or by install scripts.

This content must remain byte-identical to `claude-canopy/install.sh build_marker_block()`, `install.ps1 Build-MarkerBlock`, and the VSCode extension's marker-block constant. Drift between the four is a bug — `scripts/validate.sh` checks parity in CI.

The marker is delimited by `<!-- canopy-runtime-begin -->` and `<!-- canopy-runtime-end -->` (HTML comment tags). The opening and closing markers must each be on their own line.

## Block content (between the markers, inclusive)

```
<!-- canopy-runtime-begin -->
## Canopy Runtime

**Trigger:** any `SKILL.md` declaring a `## Tree` section is a canopy-flavored skill. Before interpreting it, load `<skills-root>/canopy-runtime/SKILL.md` and apply its execution model.

- **`<skills-root>` resolution** — first match wins:
  - `.agents/skills/` — cross-agent install (gh skill install default on Copilot and other hosts)
  - `.claude/skills/` — Claude Code
  - `.github/skills/` — GitHub Copilot
- **Platform detection** — at runtime, the agent self-identifies the active host:
  - Claude Code → apply `<skills-root>/canopy-runtime/references/runtime-claude.md`
  - GitHub Copilot → apply `<skills-root>/canopy-runtime/references/runtime-copilot.md`
  - Other hosts → halt with unsupported-platform error
- **Sections** — `## Agent`, `## Tree`, `## Rules`, `## Response:`
- **Tree notation** — `<<` input, `>>` output, `|` separator
- **Primitives** (defined in canopy-runtime's `references/framework-ops.md`):
  - control flow — `IF`, `ELSE_IF`, `ELSE`, `SWITCH`, `CASE`, `DEFAULT`, `FOR_EACH`, `BREAK`, `END`
  - interaction — `ASK`, `SHOW_PLAN`
  - execution — `EXPLORE`, `VERIFY_EXPECTED`
- **Op lookup chain** — first match wins:
  - skill-local: `<skill>/references/ops.md` or `<skill>/references/ops/<name>.md` (legacy `<skill>/ops.md` at root also supported)
  - consumer-defined cross-skill ops, if any
  - framework primitives in canopy-runtime's `references/framework-ops.md`
- **Category layout** (under each skill):
  - `scripts/` — executable code
  - `references/` — docs loaded on demand (including ops)
  - `assets/{templates,constants,schemas,checklists,policies,verify}/` — static resources
  - Legacy flat layout (these dirs at skill root) remains supported.
- **Subagent contract** — `EXPLORE` is the first tree node when `## Agent` declares `**explore**`.
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
