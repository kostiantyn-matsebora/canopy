# Core Primitives — IF / ELSE_IF / ELSE / END / BREAK

Universal control flow. Always loaded by the runtime regardless of the skill's `canopy-features` manifest — every non-trivial tree uses these.

Notation: `<<` input source or options, `>>` captured output or displayed fields, `|` item separator.

---

## IF \<\< condition

```
IF << condition
├── then-branch
[ELSE_IF << condition2
 ├── branch2]
[ELSE
 └── else-branch]
```

Evaluate `condition` against step context.
Execute first matching branch; remaining branches skipped.
Branches may be op calls or natural language.

---

## ELSE_IF \<\< condition

Continues an `IF` or `ELSE_IF` chain.
Evaluated only if all prior conditions were false.
Branches may be op calls or natural language.

---

## ELSE

Closes an `IF` or `ELSE_IF` chain.
Executed only if all prior conditions were false.
Branch may be an op call or natural language.

---

## BREAK

Exit the current loop (`FOR_EACH`) or current op immediately.
Inside `FOR_EACH`: stops iteration and resumes at the next sibling after the loop.
Outside a loop: exits the current op and returns to the caller's next node.
Does not halt the skill — execution resumes at the next sibling in the calling tree.
Use for early exit from iteration or optional branches within an op where remaining steps are not needed.

---

## END [message]

Halt the entire skill execution immediately.
Display `<message>` to the user if provided.
Use for fatal conditions and guard checks that make further execution invalid.
