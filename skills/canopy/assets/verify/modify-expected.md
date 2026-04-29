# MODIFY — Expected State

After MODIFY completes successfully:

- [ ] All files listed in the decision table have been updated
- [ ] No inline JSON, YAML, tables, scripts, or code blocks introduced in `SKILL.md`
- [ ] Tree syntax (list vs box-drawing) is unchanged from the original
- [ ] Directory layout (legacy flat vs. standard `scripts/`/`references/`/`assets/`) is unchanged from the original — MODIFY does not silently restructure
- [ ] Skill file is exactly `SKILL.md` (uppercase) — unchanged from the original
- [ ] If skill has `## Tree`: `compatibility` field and safety preamble are present (added if missing — gap-fix)
- [ ] No tree nodes removed or repositioned beyond what was explicitly requested
- [ ] VALIDATE reports no Errors on the modified skill
