# CONVERT_TO_REGULAR — Expected State

After CONVERT_TO_REGULAR completes successfully:

- [ ] Output file exists (either `SKILL.md` overwritten or `SKILL.canopy.md` written alongside)
- [ ] Output file is named `SKILL.md` (uppercase) at the skill root
- [ ] Output frontmatter no longer contains `compatibility` field declaring canopy-runtime requirement (regular skills don't need it)
- [ ] Output body no longer contains the safety preamble guard block (regular skills run on any agent)
- [ ] Output frontmatter retains `name`, `description`, `license`, `metadata` (with `argument-hint` if it was present), `allowed-tools`
- [ ] Output contains `## Steps` (numbered list), not `## Tree`
- [ ] Output contains no `## Rules` or `## Response:` Canopy section markers (their content merged into prose)
- [ ] All `IF`/`ELSE_IF`/`ELSE` nodes expanded to conditional prose
- [ ] All `ASK` and `SHOW_PLAN` nodes expanded to prose equivalents
- [ ] All named op calls replaced with their inlined definitions
- [ ] All `Read \`<category-path>/<file>\`` references replaced with inlined content
- [ ] If "Replace" was chosen: `references/ops.md` (and `references/ops/`) and the canopy-specific category subdir files that were inlined are deleted; `scripts/`, `references/`, `assets/` directory layout retained where files remain
