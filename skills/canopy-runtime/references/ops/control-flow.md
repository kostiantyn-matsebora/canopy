# Control-Flow Primitives — SWITCH / CASE / DEFAULT / FOR_EACH

Multi-way branching and iteration primitives. Loaded when the skill's manifest declares `canopy-features: [..., control-flow, ...]`.

Notation: `<<` input source or options, `>>` captured output or displayed fields, `|` item separator.

---

## SWITCH \<\< expression

```
SWITCH << expression
├── CASE << value1
│   └── branch1
[├── CASE << value2
│   └── branch2]
[└── DEFAULT
    └── default-branch]
```

Evaluate `expression` once against step context.
Match its value against each `CASE` in order; execute the first matching branch and skip the rest.
`DEFAULT` executes only if no `CASE` matched.
Branches may be op calls or natural language.
Use when branching on a single expression against multiple discrete values.

---

## CASE \<\< value

A branch within a `SWITCH` block.
Evaluated only if no prior `CASE` in the same `SWITCH` has matched.
Executed when the `SWITCH` expression equals `value`.
Branch may be an op call or natural language.

---

## DEFAULT

Closes a `SWITCH` block.
Executed only if no `CASE` in the block matched.
Branch may be an op call or natural language.

---

## FOR_EACH \<\< item in collection

```
FOR_EACH << item in collection
├── body-step-1
├── body-step-2
[└── IF << exit condition
    └── BREAK]
```

Bind `item` to each element of `collection` in turn and execute the body once per element.
If `collection` is empty, the body is skipped entirely.
`BREAK` inside the body exits the loop immediately; execution resumes at the next sibling after `FOR_EACH`. (`BREAK` lives in `core.md`.)
Body steps may be op calls or natural language.
