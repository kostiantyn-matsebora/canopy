# Subagent Dispatch — Markers + Bold Call-Sites

Per-op subagent dispatch model. **Not a primitive** — the existing op-call contract (`<< inputs >> outputs`) IS the subagent contract; the marker decides dispatch. Loaded when the skill's manifest declares `canopy-features: [..., subagent, ...]`.

Notation: `<<` input source or options, `>>` captured output or displayed fields, `|` item separator.

---

## Op definition marker

A subagent op's definition (in `references/ops.md` or `references/ops/<name>.md`) carries a blockquote marker as the first content under its heading:

```markdown
## REVIEW_ASPECT << aspect | file_paths >> findings

> **Subagent.** Output contract: `assets/schemas/aspect-findings-schema.json`

REVIEW_ASPECT << aspect | file_paths
├── Read `assets/constants/review-aspects.md` → § matching `aspect`
├── FOR_EACH << path in file_paths
│   └── read the file at `path`
└── apply criteria; return findings shaped per the contract
```

The marker may be expanded with input descriptions (narrative bullets — for primitive types/enums) or with `Input contract: <schema-path>` (for complex inputs):

```markdown
> **Subagent.**
> **Inputs:**
> - `aspect` — enum: `"security"`, `"performance"`, `"style"`, `"correctness"`
> - `file_paths` — list of file paths (strings)
>
> **Output contract:** `assets/schemas/aspect-findings-schema.json`
```

## Call-site marker

Calls to a subagent-marked op use **bold around the op name** in tree notation:

```markdown
* PARALLEL
  * **REVIEW_ASPECT** << "security"    | context.file_paths >> security_findings
  * **REVIEW_ASPECT** << "performance" | context.file_paths >> perf_findings
```

Plain (un-bold) `OP_NAME << ... >> ...` always means inline. Bold means dispatch out-of-context. The two markers (op-def + call-site) must be consistent — vscode flags drift.

## Strict contract for subagent ops

A subagent op's body may use:
- Names declared in its `<<` signature
- Static skill assets via path (`assets/constants/...`, `assets/templates/...`, `assets/policies/...`)

A subagent op's body MUST NOT use:
- `context.<name>` where `<name>` is not in the signature
- Bindings produced by prior tree nodes that weren't passed via `<<`
- Other ambient parent state

If the op's body legitimately needs ambient state, drop the marker — keep it as an inline op. The strict contract is what makes out-of-context dispatch viable.

## Composition with PARALLEL

`PARALLEL` (see [`parallel.md`](parallel.md)) is a structural block. When its children are bold-marked op calls, the runtime fans them out as parallel subagent invocations — the canonical multi-source explore / multi-aspect review pattern. Plain children of PARALLEL run inline, sequentially within the same agent turn. Mixing is allowed.

Skills using marker-based children inside `PARALLEL` should declare both `parallel` and `subagent` in their manifest.

## Contracts on subagent ops

The `Output contract:` reference inside the `> **Subagent.**` blockquote and the optional `Input contract:` reference share their syntax and semantics with **universal op contracts** — see [`../skill-resources.md`](../skill-resources.md) → "Op contracts (universal input/output schemas)". The subagent marker is the dispatch flag; the contract markers are independent and apply to inline ops too.

Bare contract markers — `> **Input contract:** \`<path>\`` and `> **Output contract:** \`<path>\`` — without the `**Subagent.**` lead declare contracts on an inline op (no dispatch).
