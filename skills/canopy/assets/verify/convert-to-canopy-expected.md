# CONVERT_TO_CANOPY — Expected State

After CONVERT_TO_CANOPY completes successfully:

- [ ] `SKILL.classic.md` exists alongside the new `SKILL.md` (original preserved)
- [ ] New skill file is exactly `SKILL.md` (uppercase)
- [ ] `SKILL.md` frontmatter is agentskills.io-compliant — only spec-allowed root fields; `argument-hint` (if any) inside `metadata`; `compatibility` field present declaring canopy-runtime requirement
- [ ] `SKILL.md` body opens with safety preamble guard block before `$ARGUMENTS`
- [ ] `SKILL.md` contains `## Tree`, `## Rules`, and `## Response:` sections
- [ ] `SKILL.md` contains no inline JSON, YAML, tables, scripts, or code blocks
- [ ] Every content block from the original has been placed in the correct standard-layout location per `assets/policies/category-decision-flowchart.md` (`assets/<category>/`, `scripts/`, or `references/`)
- [ ] `references/ops.md` exists if any ops were defined that are not covered by shared
- [ ] Each new category file contains only content appropriate to its directory
- [ ] Shared references introduced where equivalent content already existed in shared
- [ ] VALIDATE reports no Errors on the converted skill
