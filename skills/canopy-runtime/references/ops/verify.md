# Verify Primitive — VERIFY_EXPECTED

Post-execution state-check primitive. Loaded when the skill's manifest declares `canopy-features: [..., verify, ...]`.

Notation: `<<` input source or options, `>>` captured output or displayed fields, `|` item separator.

---

## VERIFY_EXPECTED \<\< assets/verify/verify-expected.md

Check current state against expected outcomes defined in `assets/verify/verify-expected.md` (or `verify/verify-expected.md` for skills using the legacy flat layout).

`VERIFY_EXPECTED` reads the referenced checklist file as a list of `- [ ]` items, evaluates each against the current working state (filesystem, captured outputs, environment), and reports pass/fail per item.

Non-passing items are surfaced to the user in the response. Whether a non-passing item halts the skill is a per-skill decision documented in the checklist itself; the primitive merely reports.

The standard layout path is `assets/verify/<file>.md`; the legacy flat layout uses `verify/<file>.md` at skill root. Both are accepted.
