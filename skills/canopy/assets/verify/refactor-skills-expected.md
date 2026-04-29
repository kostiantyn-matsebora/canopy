# REFACTOR_SKILLS — Expected State

After REFACTOR_SKILLS completes successfully:

- [ ] The shared content lives in a complete, named, installable skill (`<shared-skill>/SKILL.md` exists with full frontmatter, including `compatibility` and safety preamble for `## Tree` content)
- [ ] No bare shared files exist — extracted content is inside a proper skill directory, not a sibling shared folder referenced via `..` paths
- [ ] Each extracted op appears exactly once in `<shared-skill>/references/ops.md` (appended, not duplicated)
- [ ] Each extracted resource file exists at `<shared-skill>/assets/<category>/<filename>` (or appropriate standard-layout location)
- [ ] Source skills no longer contain the extracted op definitions in their op files
- [ ] Source skills whose op file became empty have had the file deleted
- [ ] Each dependent source skill's `SKILL.md` frontmatter declares the shared skill via `compatibility` (so consumers know to install it)
- [ ] All `Read` references in source skills point to the new shared location
- [ ] No tree structure, logic, or intent changed in any source skill
- [ ] VALIDATE reports no Errors on any modified skill or on the new shared skill
- [ ] The new shared skill is independently installable via `gh skill install` (verified by inspecting its directory — it has its own `SKILL.md`, no `..` paths)
