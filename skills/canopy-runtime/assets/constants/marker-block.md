# Canopy Runtime Marker Block

The canonical ambient instruction block written into `CLAUDE.md` (Claude Code) or `.github/copilot-instructions.md` (Copilot) — by canopy-runtime's Activation section on first load, by the ACTIVATE op, or by install scripts.

This content must remain byte-identical to `canopy/install.sh build_marker_block()`, `install.ps1 Build-MarkerBlock`, and the VSCode extension's marker-block constant. Drift between the four is a bug.

The marker is delimited by `<!-- canopy-runtime-begin -->` and `<!-- canopy-runtime-end -->` (HTML comment tags). The opening and closing markers must each be on their own line.

## Block content (between the markers, inclusive)

```
<!-- canopy-runtime-begin -->
## Canopy Runtime

Any `SKILL.md` declaring a `## Tree` section is canopy-flavored. To interpret, load `<skills-root>/canopy-runtime/SKILL.md` (where `<skills-root>` is the first match of `.agents/skills/`, `.claude/skills/`, `.github/skills/`). The runtime SKILL.md handles platform detection, op lookup, and lazy-loads only the spec slices the skill actually uses (per `metadata.canopy-features`).
<!-- canopy-runtime-end -->
```

## Why slim

The marker is **always-loaded ambient context** in every session of every canopy-active project. Its job is just trigger + pointer — a reader (human or agent) needs to know:

1. When canopy applies (skill has `## Tree`).
2. Where to find the runtime spec (`<skills-root>/canopy-runtime/SKILL.md`).
3. What `<skills-root>` resolves to.

Everything else (primitives, op-lookup chain, category layout, sections, dispatch model) lives in `canopy-runtime/SKILL.md` and its `references/` slices, loaded only when the runtime is actually engaged. Pre-v0.21.0 markers inlined that spec — costing every canopy-active session ~30 lines of always-loaded context for content that's already in the runtime spec.

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
