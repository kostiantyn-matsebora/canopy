# VALIDATE

Evaluate a Canopy skill for framework errors, warnings, and optimization opportunities.

1. Locate the skill directory using Glob.
2. Read all files: `SKILL.md`, `references/ops.md` (or legacy `ops.md`) if present, all category subdir files. Detect whether the skill uses standard layout (`scripts/` / `references/` / `assets/`) or legacy flat layout (category dirs at root).
3. Read `assets/policies/authoring-rules.md` for structural, style, op naming, subagent, frontmatter compliance, compatibility/preamble requirements, and debug-awareness constraints.
   Read `assets/constants/control-flow-notation.md` for ad-hoc control flow patterns to detect.
   Read `assets/constants/category-dirs.md` and `assets/policies/category-decision-flowchart.md` for category classification.
   All checks derived from these policies apply to tree nodes in **both** `SKILL.md` and op files (`references/ops.md`, `references/ops/<name>.md`, or legacy `ops.md`) equally — not just to `SKILL.md`.
4. Read `assets/constants/validate-checks.md` for the full Error, Warning, and Optimization check catalog. Evaluate the skill against every check. Classify each finding by severity: **Error** (must fix), **Warning** (should fix), **Optimization** (recommended).

   For content-class rules (inline static/parameterised content, complex commands), iterate every tree node in order and apply each check explicitly — do not rely on a holistic scan.

5. Report all findings grouped by severity, with line numbers where possible. If no issues: report "Skill passes validation — no issues found."
