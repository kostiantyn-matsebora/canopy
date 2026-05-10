# Control Flow Notation — Migration Table

Replace all ad-hoc control flow patterns with standard Canopy ops:

| Old pattern | Replace with |
|---|---|
| `Ask: "question? (yes/no)"` | `ASK << question? \| Yes \| No` |
| `Show Plan (field1, field2)` | `SHOW_PLAN >> field1 \| field2` |
| `Read verify/verify-expected.md for expected state` | `VERIFY_EXPECTED` |
| `→ {fields}` (output capture) | `>> {fields}` |
| `IF << condition → action` (inline branch) | `IF << condition` with `action` as nested child node |
| `ELSE → action` (inline branch) | `ELSE` with `action` as nested child node |
| `if X: do Y` (in steps) | `IF << X` tree node with `Y` as child |
| `else if Y: do Z` (in steps) | `ELSE_IF << Y` chained after `IF` |
| `else: do Z` (in steps) | `ELSE` chained after `IF` or `ELSE_IF` |
| early return from op (no error) | `BREAK` |
| fatal stop with message | `END <message>` |
| `if X: do Y / else if Y: do Z / ...` repeated over one value | `SWITCH << X` with `CASE << Y` branches |
| `ELSE_IF` chain matching `value == "a"`, `value == "b"`, … | `SWITCH << value` with `CASE << "a"`, `CASE << "b"`, … |
| `for each X in Y` prose loop (or numbered step repeated per item) | `FOR_EACH << x in y` with loop body as child nodes |
| `FOR_EACH << x in y` with no exit condition | add `IF << exit condition` + `BREAK` child if early exit is needed |
| `spawn N subagents in parallel` (prose fan-out) / sequential `## Agent` invocations with no data dependency | `PARALLEL` block with each subagent invocation as an indented child |
| Prose `**explore**` body in `## Agent` (singular) | Marked op definition: `## EXPLORE >> context` heading + `> **Subagent.** Output contract: assets/schemas/explore-schema.json` blockquote + tree-form body. Call site stays `**EXPLORE** >> context` (bold). |
| Multiple inline ops doing isolated, schema-shaped reads → would benefit from out-of-context dispatch | Add `> **Subagent.** Output contract: <schema>` marker to each op definition; bold the call sites: `**OP_NAME** << ... >> ...` |
| Inline op whose `<<` inputs and `>>` outputs are stable but undocumented → would benefit from typed contracts (v0.22.0+) | Add `> **Input contract:** assets/schemas/<op>-input.json` and/or `> **Output contract:** assets/schemas/<op>-output.json` blockquotes under the op heading. Generate scaffolds via `/canopy improve --scaffold-contracts`. |
| Skill carries op contracts and the author wants runtime enforcement (v0.22.0+) | Add `metadata.canopy-contracts: strict`. Runtime validates each contract-bearing op's input/output before/after firing and halts with `[contract-violation]` on drift. |
