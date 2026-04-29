# CONVERT_TO_REGULAR

Convert a Canopy skill to a plain agentskills.io skill (prose/numbered steps, no canopy primitives, no canopy-specific frontmatter).

The output is still an agentskills.io-compliant skill — it follows the standard `scripts/`/`references/`/`assets/` layout and the case-sensitive `SKILL.md` filename. Only canopy-specific elements are stripped.

1. Locate the skill directory using Glob.
2. Read all files: `SKILL.md`, `references/ops.md` (or legacy `ops.md`) if present, all category subdir files (standard or legacy layout).
3. Show plan: output file | steps count | content to inline | files to flatten | canopy-specific frontmatter and body elements to remove. Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: CONVERT_TO_REGULAR` | `skill: <name>` | `output: <output-file>` | `files-to-flatten: <list>`.

4. Ask: **"Proceed? | Yes | No"**
5. Produce the converted `SKILL.md`:
   - Read `assets/policies/conversion-expansion-rules.md` for how to expand each Canopy element
   - Strip canopy-specific frontmatter: remove the `compatibility` field that declares canopy-runtime (regular skills don't require canopy-runtime); leave `name`, `description`, `license`, `metadata` (with `argument-hint` retained), `allowed-tools` intact
   - Strip the safety preamble guard block from the body — regular skills run on any agent and don't need the runtime-required guard
   - Apply all expansions from `assets/policies/conversion-expansion-rules.md` (replace `## Tree` with `## Steps`, expand `IF`/`ASK`/`SHOW_PLAN`/`VERIFY_EXPECTED`/named ops/`Read`/`## Agent` per the rules)
6. Ask: **"What to do with source Canopy files? | Write alongside (as SKILL.canopy.md) | Replace (overwrite SKILL.md, delete extras)"**
7. Write the output. If replacing, delete `references/ops.md` (and `references/ops/`) and the canopy-specific category subdir files that were inlined. Keep `scripts/`, `references/`, `assets/` directory layout — these are standard agentskills.io paths and remain valid for plain skills.
8. Verify result against `assets/verify/convert-to-regular-expected.md`.
9. Report: **Summary / Output file / Inlined files / Note: conversion is lossy — op structure and resource separation are not recoverable from the output**
