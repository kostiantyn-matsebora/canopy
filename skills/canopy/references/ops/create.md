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
   - Read `assets/policies/authoring-rules.md` for SKILL.md composition and writing rules (frontmatter compliance, compatibility field, safety preamble, structure, subagent contract)
   - Identify purpose, inputs, outputs, key decision points, and phases
   - Determine whether an explore subagent is needed (the skill must read project files before acting). **Use the marker form** for new skills — define `## EXPLORE >> context` in `references/ops.md` with `> **Subagent.** Output contract: assets/schemas/explore-schema.json` and a `**EXPLORE** >> context` (bold) first tree node. Do NOT generate the legacy `## Agent` section for new skills (it remains a soft-compat shape for existing skills only).
   - Determine whether other subagent-shaped ops are needed (substantial reading/analysis with isolated `<<` inputs and a well-defined output schema). Mark them with the same `> **Subagent.** Output contract: <schema>` blockquote and bold their call sites.
   - Identify which steps should become named ops in `references/ops.md` (or `references/ops/<name>.md`) — inline (no marker) by default; mark as subagent only when context isolation justifies the dispatch cost
   - Identify which structured content belongs in category subdirs (`assets/<category>/` for static resources, `scripts/` for executables, `references/` for docs loaded on demand)
7. Consult canopy-runtime's primitive slices (indexed in `../canopy-runtime/references/ops.md`) and any consumer-defined cross-skill ops the user mentions.
   - For each candidate op: if an equivalent already exists in framework primitives or consumer-shared ops, reference it — do not redefine it skill-locally
   - For each candidate resource file: if equivalent content already exists elsewhere, reference that file — do not duplicate it
8. **Compute the `canopy-features` manifest** from the planned tree:
   - Walk every tree node and op definition. For each primitive used, map it to its slice: `ASK`/`SHOW_PLAN` → `interaction`; `SWITCH`/`CASE`/`DEFAULT`/`FOR_EACH` → `control-flow`; `PARALLEL` → `parallel`; bold-marked op call (`**OP**`) or `> **Subagent.**` op-def → `subagent`; legacy `## Agent` + `EXPLORE >> context` → `explore`; `VERIFY_EXPECTED` → `verify`. `IF`/`ELSE_IF`/`ELSE`/`END`/`BREAK` are core (implicit-always-loaded — never list).
   - The manifest is the deduped sorted list of slice names actually used. Emit it as `metadata.canopy-features: [...]` in the produced SKILL.md frontmatter.
9. Show plan: skill name | target location | tree structure preview | `canopy-features` manifest | files to create (marking shared references vs new files). Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: CREATE` | `skill: <name>` | `target: <full-path>` | `tree-syntax: <markdown-list|box-drawing>` | `canopy-features` | `changes`.
10. Ask: **"Proceed? | Yes | Adjust plan | No"** — if adjusting, accept clarifications and re-show plan.
11. Generate and write files. Skill file must be exactly `SKILL.md` (uppercase):
    - `SKILL.md` — agentskills.io-compliant frontmatter (`name`, `description`, `compatibility` declaring canopy-runtime requirement, `metadata` for non-spec fields including `argument-hint` and `canopy-features`); body opens with the safety preamble guard block (see `assets/policies/authoring-rules.md` → Safety preamble); then Tree, Rules, Response sections
    - `references/ops.md` — only for ops not already covered; nodes must comply with the same `assets/policies/authoring-rules.md` constraints as `SKILL.md` tree nodes
    - Category subdir files (`assets/schemas/`, `assets/policies/`, etc.; `scripts/` for executables; `references/` for on-demand docs) — only for content not already available elsewhere
12. After writing, run VALIDATE inline. Report any issues.
13. Verify result against `assets/verify/create-expected.md`.
14. Report: **Summary / Files created / Shared references used / Manifest features declared / Next steps**

**SKILL.md must contain only orchestration, tree nodes must be short and scannable** — see `assets/policies/authoring-rules.md`.
