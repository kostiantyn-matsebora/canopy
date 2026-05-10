# ADVISE

Answer a "how to" question about implementing something in an existing Canopy skill. Read-only — no files are written. Produces a structured plan the user can hand to MODIFY or IMPROVE.

1. If no skill name or path is given, ask for it.
2. Locate the skill directory using Glob.
3. Read all files: `SKILL.md`, `references/ops.md` or legacy `ops.md` (if present), and all category subdir files (standard layout under `assets/`/`scripts/`/`references/`, or legacy flat layout at the skill root).
4. Understand the question — identify the specific behaviour, pattern, or feature being asked about.
5. Analyse the current skill against the question:
   - Identify what is missing, suboptimal, or not yet expressed in the skill
   - Determine which framework primitives, ops, or category files apply
   - Identify which existing nodes or ops need to change and which new ones are needed
   - If the skill has multiple sequential `## Agent` invocations or prose fan-out (e.g. "spawn N in parallel") with no data dependency between them, recommend the `PARALLEL` block primitive as the structural alternative — cite cache-stable emission, deterministic fan-out shape, and editor support
   - If the skill uses `## Agent` singular + `EXPLORE >> context`, recommend migrating to the marker form — a marked op definition (`## EXPLORE >> context` heading + `> **Subagent.** Output contract: <schema>` blockquote) and bold call site (`**EXPLORE** >> context`). Cite consistency with the new authoring style (multi-subagent skills must use the marker form anyway) and the bidirectional vscode diagnostic (catches drift between definition and call sites).
   - If an inline op's body honors strict `<<` inputs (no ambient `context.*` reads outside the signature; no prior-binding leaks), recommend promoting to a subagent: add the `> **Subagent.** Output contract: <schema>` marker to the definition and bold every call site. Cite context isolation and parallel-fan-out eligibility under `PARALLEL`.
   - If an op has a stable `<<` / `>>` signature and one or more downstream consumers but no contracts (v0.22.0+), recommend declaring `> **Input contract:** <path>` and `> **Output contract:** <path>` blockquotes on the op definition. Cite vscode static type-flow analysis at authoring time and optional runtime enforcement via `metadata.canopy-contracts: strict`. Recommend running `/canopy improve --scaffold-contracts` to generate the initial schemas.
6. Present an advice plan as a table:

   | # | What | File | Action | Reasoning |
   |---|------|------|--------|-----------|
   | 1 | `<symbol, section, or content>` | `<file>` | add / change / extract / create | `<why this is the right Canopy approach>` |

   Follow the table with a short explanation of the overall approach and any trade-offs.
7. Do not apply any changes. If the user wants the changes applied, tell them to follow up with MODIFY or IMPROVE.
8. Report: **Advice plan / Approach summary / Suggested follow-up operation**
