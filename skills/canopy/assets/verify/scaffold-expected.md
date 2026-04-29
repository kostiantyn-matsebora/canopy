# SCAFFOLD — Expected State

After SCAFFOLD completes successfully:

- [ ] `<skill_dir>/SKILL.md` exists — exact uppercase filename — under the resolved target location (distribution: `skills/<name>/`; consumer: `<skills_base>/<name>/` per platform)
- [ ] `SKILL.md` frontmatter contains `name`, `description`, `compatibility` (declaring canopy-runtime requirement), and `metadata` (with `argument-hint` inside `metadata`, never at root)
- [ ] `SKILL.md` body opens with the safety preamble guard block before `$ARGUMENTS`
- [ ] `SKILL.md` has `## Tree`, `## Rules`, and `## Response:` sections
- [ ] `SKILL.md` contains no hardcoded `.claude/` or `.github/` paths in tree nodes or `Read` references
- [ ] Tree syntax matches the choice made at step 4 (list `*` or box-drawing)
- [ ] `<skill_dir>/references/ops.md` exists as a placeholder
- [ ] Standard-layout subdirectory tree exists: `scripts/`, `references/`, `assets/templates/`, `assets/constants/`, `assets/schemas/`, `assets/checklists/`, `assets/policies/`, `assets/verify/`
- [ ] No other files were created or modified
