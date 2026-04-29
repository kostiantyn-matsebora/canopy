# CREATE

Create a new Canopy skill from a description.

1. If no description given, ask for it.
2. Derive a kebab-case skill name from the description, or ask if ambiguous.
3. Read `assets/policies/platform-targeting.md` and resolve the target platform.
4. Resolve target skill location from `context.repo_context`:
   - `distribution` → write to `skills/<skill_name>/` at the repo root
   - `consumer` → write to `<skills_base>/<skill_name>/` per platform target (`.claude/skills/` or `.github/skills/`)
   Check if the target directory already exists — if so, offer MODIFY instead.
5. Ask: **"Which tree syntax? | Markdown list (`*`) | Box-drawing (tree characters)"**
6. Analyze the description:
   - Read `assets/policies/category-decision-flowchart.md` to classify each content block
   - Read `assets/policies/authoring-rules.md` for SKILL.md composition and writing rules (frontmatter compliance, compatibility field, safety preamble, structure)
   - Identify purpose, inputs, outputs, key decision points, and phases
   - Determine whether an explore subagent is needed (the skill must read project files before acting)
   - Identify which steps should become named ops in `references/ops.md` (or `references/ops/<name>.md`)
   - Identify which structured content belongs in category subdirs (`assets/<category>/` for static resources, `scripts/` for executables, `references/` for docs loaded on demand)
7. Consult `framework-ops.md` (framework primitives — already loaded into context by the canopy tree's up-front Read of `../canopy-runtime/references/framework-ops.md`) and any consumer-defined cross-skill ops the user mentions.
   - For each candidate op: if an equivalent already exists in framework primitives or consumer-shared ops, reference it — do not redefine it skill-locally
   - For each candidate resource file: if equivalent content already exists elsewhere, reference that file — do not duplicate it
8. Show plan: skill name | target location | tree structure preview | files to create (marking shared references vs new files). Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: CREATE` | `skill: <name>` | `target: <full-path>` | `tree-syntax: <markdown-list|box-drawing>` | `changes`.
9. Ask: **"Proceed? | Yes | Adjust plan | No"** — if adjusting, accept clarifications and re-show plan.
10. Generate and write files. Skill file must be exactly `SKILL.md` (uppercase):
    - `SKILL.md` — agentskills.io-compliant frontmatter (`name`, `description`, `compatibility` declaring canopy-runtime requirement, `metadata` for non-spec fields like `argument-hint`); body opens with the safety preamble guard block (see `assets/policies/authoring-rules.md` → Safety preamble); then Tree, Rules, Response sections
    - `references/ops.md` — only for ops not already covered; nodes must comply with the same `assets/policies/authoring-rules.md` constraints as `SKILL.md` tree nodes
    - Category subdir files (`assets/schemas/`, `assets/policies/`, etc.; `scripts/` for executables; `references/` for on-demand docs) — only for content not already available elsewhere
11. After writing, run VALIDATE inline. Report any issues.
12. Verify result against `assets/verify/create-expected.md`.
13. Report: **Summary / Files created / Shared references used / Next steps**

**SKILL.md must contain only orchestration, tree nodes must be short and scannable** — see `assets/policies/authoring-rules.md`.
