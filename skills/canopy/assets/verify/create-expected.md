# CREATE — Expected State

After CREATE completes successfully:

- [ ] `SKILL.md` exists at `<skill_dir>/SKILL.md` — exact uppercase filename — under the resolved target location (distribution: `skills/<name>/`; consumer: `<skills_base>/<name>/` per platform)
- [ ] `SKILL.md` frontmatter contains only spec-allowed root fields (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`); `argument-hint`/`user-invocable` if present are inside `metadata`
- [ ] `SKILL.md` includes a `compatibility` field declaring canopy-runtime requirement (Claude Code + Copilot install paths)
- [ ] `SKILL.md` body opens with the safety preamble guard block before `$ARGUMENTS`
- [ ] `SKILL.md` contains no hardcoded `.claude/` or `.github/` paths in tree nodes or `Read` references
- [ ] `SKILL.md` contains `## Tree`, `## Rules`, and `## Response:` sections
- [ ] `SKILL.md` contains no inline JSON, YAML, tables, scripts, or code blocks
- [ ] `references/ops.md` exists if any ops were defined that are not covered by shared
- [ ] Each category subdir file exists in the correct standard-layout location (`assets/<category>/` for static resources, `scripts/` for executables, `references/` for on-demand docs) if content was extracted that is not already in shared
- [ ] VALIDATE reports no Errors on the new skill
