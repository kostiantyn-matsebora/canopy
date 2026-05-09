# CONVERT_TO_CANOPY

Convert a regular Claude Code skill (flat prose or numbered steps) to Canopy format using the standard agentskills.io directory layout.

A "regular skill" is any `.md` skill file that uses prose or numbered `## Steps` instead of a `## Tree` with Canopy notation.

1. Read the source skill file(s).
2. Analyze content. For every distinct block of content, apply the **Category Decision Flowchart** from `assets/policies/category-decision-flowchart.md` (in order — use the first matching test). Additionally map:
   - User interaction points → `ASK` nodes
   - Plan-display steps → `SHOW_PLAN` nodes
   - Post-execution verification steps → `VERIFY_EXPECTED << assets/verify/verify-expected.md` node; create `assets/verify/verify-expected.md` with the expected-state checklist
   - If no explicit post-execution verification exists but the skill writes files or makes changes, add a `VERIFY_EXPECTED << assets/verify/verify-expected.md` node as the last step in the success branch and include it in the decision table with reason: "skill makes changes but has no verification step"
   - Independent parallel actions ("spawn N in parallel", "fan out to …", or ≥2 sequential subagent calls with no data dependency between them) → `PARALLEL` block with each action as an indented child
   - Subagent-shaped actions (substantial reading/analysis with a well-defined output schema, isolated inputs) → marked op definition with `> **Subagent.** Output contract: <schema>` blockquote + bold call site `**OP_NAME** << input >> output`. Default output schema goes under `assets/schemas/<op>-output.json`. Prefer this over `## Agent` singular for new skills.
   - File-reading "explore" phase that gathers context for the rest of the skill → marked `EXPLORE` op definition (NOT `## Agent` singular). Output contract: `assets/schemas/explore-schema.json`. First tree node: `**EXPLORE** >> context` (bold call site).
3. Ask: **"Which tree syntax? | Markdown list (`*`) | Box-drawing (tree characters)"**
4. Consult canopy-runtime's primitive slices (indexed in `../canopy-runtime/references/ops.md`) and any consumer-defined cross-skill ops the user mentions.
   - For each candidate op identified in step 2: if an equivalent already exists in primitives or consumer-shared ops, mark it as a shared reference — do not add it to the skill-local `references/ops.md`
   - For each candidate resource file: if equivalent content already exists, mark it as a shared reference — do not create a duplicate
5. **Compute the `canopy-features` manifest** from the planned tree (per `create.md` step 8 — same mapping). Will be emitted as `metadata.canopy-features: [...]` in the produced SKILL.md.
6. Present a decision table before making any changes:

   | Content | Extracted from | Target file | Category | Reason |
   |---------|---------------|-------------|----------|--------|
   | `<description>` | `<source section>` | `<assets/<dir>/<filename>.md>` or shared ref | `<constants/policies/schemas/…>` | `<decision-rule rationale>` |

   Then show: tree structure preview | ops to create | skill name | shared references used. Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: CONVERT_TO_CANOPY` | `source: <source-file>` | `skill: <name>` | `tree-syntax: <markdown-list|box-drawing>` | `changes`.

7. Ask: **"Proceed? | Yes | Adjust | No"** — wait for response before touching any file.
8. Determine target skill name (infer from file name; ask if ambiguous).
9. Read `assets/policies/platform-targeting.md` and resolve the target platform. Resolve target location from `context.repo_context`:
   - `distribution` → `skills/<skill_name>/` at the repo root
   - `consumer` → `<skills_base>/<skill_name>/` per platform target
   If target directory already exists: Ask **"Directory exists. | Overwrite | Cancel"**
10. Create the Canopy skill directory and write all files. Skill file must be exactly `SKILL.md` (uppercase):
    - Copy the original `SKILL.md` to `SKILL.classic.md` before overwriting it (preserve the pre-conversion source)
    - `SKILL.md` in Canopy format with agentskills.io-compliant frontmatter — `name`, `description`, `compatibility` (declaring canopy-runtime requirement), `metadata` for non-spec fields including `canopy-features`. Body opens with safety preamble guard block. See `assets/policies/authoring-rules.md` for full composition rules.
    - `references/ops.md` only for ops not already covered
    - Category files (`assets/schemas/`, `assets/policies/`, etc.; `scripts/` for executables; `references/` for on-demand docs) only for content not already available elsewhere
11. Run VALIDATE inline. Report conversion notes and any items needing manual review.
12. Verify result against `assets/verify/convert-to-canopy-expected.md`.
13. Report: **Summary / Files created / Shared references used / Conversion notes / Manual review items**
