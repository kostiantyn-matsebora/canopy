# REFACTOR_SKILLS

Analyse all available Canopy skills, identify ops and resources duplicated across more than two skills, and extract them into a **named, installable shared skill** with its own `SKILL.md`. Logic and intent of all skills are preserved; only shared content is lifted out and dependencies declared via `compatibility`.

**Skill autonomy constraint:** extracted shared content MUST become a complete agentskills.io skill, not a bare shared file referenced from sibling skill directories. A skill referencing `../other-skill/scripts/x.sh` is broken when only the dependent is installed via `gh skill install`. The shared skill must be independently installable.

1. Discover all skill directories using Glob:
   - `.claude/skills/*/SKILL.md` and `.claude/skills/*/references/ops.md` (and legacy `.claude/skills/*/ops.md`)
   - `.github/skills/*/SKILL.md` and `.github/skills/*/references/ops.md` (and legacy `.github/skills/*/ops.md`)
   Collect every unique skill name. For each skill, also list category subdir files (under both standard layout — `assets/<dir>/`, `scripts/`, `references/` — and legacy flat layout at the skill root).

2. Read all discovered files. Build an inventory:

   **Op inventory** — for each `ALL_CAPS` op name defined in any op file:
   | Op name | Skills it appears in | Definition summary |
   |---------|---------------------|--------------------|

   **Resource inventory** — for each category file in any skill:
   | File | Skills it appears in | Category | Content summary |
   |------|---------------------|----------|-----------------|

3. Identify extraction candidates — items that appear in **more than two** skills:

   **Op candidates**: ops with the same name, OR semantically identical logic under different names, across > 2 skills. Exclude framework primitives.

   **Resource candidates**: category files with identical or near-identical content across > 2 skills. Only extract when the content's meaning is independent of the source skill's context.

4. Determine the target shared skill. ASK the user:
   - **Create new shared skill** (recommended) — propose a kebab-case name and confirm; this becomes a new skill with its own `SKILL.md`, distributable via `gh skill install`
   - **Use existing shared skill** — name an existing consumer-shared skill the user already has

   Per skill autonomy, the shared content MUST live in a real skill directory, not in a bare shared folder.

5. Consult canopy-runtime's primitive slices (indexed in `../canopy-runtime/references/ops.md`) and any consumer-shared skill files the user names to confirm no candidate is already defined there.

6. Present a decision table before making any changes:

   | # | Content | Current location(s) | Target shared skill | Action | Reason |
   |---|---------|---------------------|---------------------|--------|--------|
   | 1 | `<op name or resource description>` | `skill-a/references/ops.md`, `skill-b/...`, `skill-c/...` | `<shared-skill>/references/ops.md` | extract + update refs in dependents + add `compatibility` declaration | duplicated in N > 2 skills |

   Then list:
   - Skills whose `SKILL.md` and op files will be updated
   - The shared skill: created or extended (with file list)
   - `compatibility` field additions on each dependent skill (declaring the shared skill as a requirement)

   If no extraction candidates are found, report that and stop.

   Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: REFACTOR_SKILLS` | `shared-skill: <name>` | `changes`.

7. Ask: **"Proceed? | Yes | Adjust | No"** — wait for response before touching any file.

8. Apply all changes:
   - Read `assets/policies/preservation-rules.md` before modifying any skill
   - For a NEW shared skill: scaffold it via the same rules as SCAFFOLD — `SKILL.md` (uppercase), with `compatibility` field and safety preamble; ops in `references/ops.md`; resources in `assets/<category>/`
   - For an EXISTING shared skill: append extracted ops to its `references/ops.md`; preserve all existing content
   - Write extracted resource files to `<shared-skill>/assets/<category>/` (or appropriate standard-layout location)
   - In each source skill's op file: remove the extracted op definition verbatim; if the file becomes empty, delete it
   - In each source skill's `SKILL.md`: update every `Read \`<category-path>/<file>\`` reference that pointed to the extracted content to point to the new shared skill via the consumer cross-skill ops mechanism
   - In each source skill's `SKILL.md` frontmatter: extend (or add) the `compatibility` field to declare the shared skill as a requirement. Use the spec-compliant free-text form (single string, max 500 chars) — e.g. `compatibility: Requires the canopy-runtime skill and the <shared-skill> skill (both published at github.com/<owner>/<repo>). Install with any agentskills.io-compatible tool. Supports Claude Code and GitHub Copilot.` Do NOT use a structured object like `compatibility: { requires: [...] }` — that shape is non-spec.
   - Do not change any other tree structure, logic, or intent
   - Do not merge ops that share a name but have meaningfully different behaviour — flag those as conflicts instead

9. Run VALIDATE inline on each modified skill AND on the shared skill. Fix any issues introduced by the refactor before reporting.
10. Verify result against `assets/verify/refactor-skills-expected.md`.
11. Report: **Summary / Ops extracted / Resources extracted / Shared skill created or extended / Skills updated with compatibility declarations / Conflicts skipped / Validation results**
