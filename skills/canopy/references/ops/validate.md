# VALIDATE

Evaluate a Canopy skill for framework errors, warnings, and optimization opportunities.

1. Locate the skill directory using Glob.
2. Read all files: `SKILL.md`, `references/ops.md` (or legacy `ops.md`) if present, all category subdir files. Detect whether the skill uses standard layout (`scripts/` / `references/` / `assets/`) or legacy flat layout (category dirs at root).
3. Read `assets/policies/authoring-rules.md` for structural, style, op naming, subagent (marker dispatch + `## Agent` soft-compat), frontmatter compliance, compatibility/preamble requirements, and debug-awareness constraints.
   Read `assets/constants/control-flow-notation.md` for ad-hoc control flow patterns to detect.
   Read `assets/constants/category-dirs.md` and `assets/policies/category-decision-flowchart.md` for category classification.
   All checks derived from these policies apply to tree nodes in **both** `SKILL.md` and op files (`references/ops.md`, `references/ops/<name>.md`, or legacy `ops.md`) equally — not just to `SKILL.md`.

   **Subagent-marker checks** (per `assets/constants/validate-checks.md`):
   - For each call site `**OP_NAME** << ... >> ...` (bold around op name): the resolved op definition MUST carry `> **Subagent.** Output contract: <schema>` as the first content under its heading; otherwise emit a bidirectional-mismatch error
   - For each op definition with the marker: at least one call site must be bold; an unmarked-everywhere call to a marked op is also a mismatch error
   - The output schema file referenced in the marker MUST exist; missing file is an error
   - Inside marked op bodies: any reference to `context.<name>` not declared in the `<<` signature is a strict-contract violation error
   - Any `Input contract: <path>` reference must point at an existing schema file

   **`metadata.canopy-features` manifest checks** (v0.21.0+, per `assets/constants/validate-checks.md`):
   - Compute the actual feature set by walking the tree: `ASK`/`SHOW_PLAN` → `interaction`; `SWITCH`/`CASE`/`DEFAULT`/`FOR_EACH` → `control-flow`; `PARALLEL` → `parallel`; bold-marked op call or `> **Subagent.**` op-def → `subagent`; `## Agent` + `EXPLORE >> context` → `explore`; `VERIFY_EXPECTED` → `verify`. (`IF`/`ELSE_IF`/`ELSE`/`END`/`BREAK` are core — never list.)
   - Manifest missing → warning (back-compat — runtime falls back to load-everything; `/canopy improve` proposes adding it).
   - Declared feature not used in tree → warning (drift; remove unused entries).
   - Used feature not declared → warning (drift; add missing entries).
   - `core` listed → warning (implicit-always-loaded).
   - Unrecognized value → warning.
4. Read `assets/constants/validate-checks.md` for the full Error, Warning, and Optimization check catalog. Evaluate the skill against every check. Classify each finding by severity: **Error** (must fix), **Warning** (should fix), **Optimization** (recommended).

   For content-class rules (inline static/parameterised content, complex commands), iterate every tree node in order and apply each check explicitly — do not rely on a holistic scan.

5. Report all findings grouped by severity, with line numbers where possible. If no issues: report "Skill passes validation — no issues found."
