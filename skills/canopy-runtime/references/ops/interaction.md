# Interaction Primitives — ASK / SHOW_PLAN

User-interaction primitives. Loaded when the skill's manifest declares `canopy-features: [..., interaction, ...]`.

Notation: `<<` input source or options, `>>` captured output or displayed fields, `|` item separator.

---

## ASK \<question\> \<\< option1 | option2 [| ...]

Present `<question>` with the listed options.
Do not proceed past this step until the user responds.

`ASK` may also be used in free-form mode without a `|`-separated option list — the runtime renders the question and accepts whatever the user types as the answer.

---

## SHOW_PLAN \>\> field1 | field2 | ...

Present a structured plan showing all listed fields before any changes are made.
