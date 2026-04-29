# IMPROVE — Expected State

After IMPROVE completes successfully:

- [ ] All VALIDATE Errors and Warnings have been fixed — including agentskills.io compliance gaps:
  - Skill filename is exactly `SKILL.md` (uppercase)
  - Frontmatter root contains only spec-allowed fields; `argument-hint`/`user-invocable` are inside `metadata`
  - `## Tree` skills have a `compatibility` field as a YAML string declaring canopy-runtime requirement and source (legacy structured `compatibility: { requires: [...] }` shapes have been migrated to spec-compliant free-text)
  - `## Tree` skills have safety preamble guard block at the top of the body
- [ ] Every misplaced category file has been relocated per `assets/policies/category-decision-flowchart.md`
- [ ] `SKILL.md` contains no inline JSON, YAML, tables, scripts, or code blocks
- [ ] Shared references introduced where duplicated content existed in shared
- [ ] If layout migration was approved: directories moved per the legacy → standard mapping; every `Read` reference rewritten to the new path; no orphaned files left behind
- [ ] Tree syntax (list vs box-drawing) is unchanged from the original
- [ ] Skill logic and intent are unchanged
- [ ] If skill makes changes to files: `VERIFY_EXPECTED` node present in the success branch and `assets/verify/verify-expected.md` (or legacy `verify/verify-expected.md`) exists
- [ ] VALIDATE reports no Errors on the improved skill
