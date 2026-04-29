# CONVERT_TO_CANOPY

Convert a regular Claude Code skill (flat prose or numbered steps) to Canopy format using the standard agentskills.io directory layout.

A "regular skill" is any `.md` skill file that uses prose or numbered `## Steps` instead of a `## Tree` with Canopy notation.

1. Read the source skill file(s).
2. Analyze content. For every distinct block of content, apply the **Category Decision Flowchart** from `assets/policies/category-decision-flowchart.md` (in order — use the first matching test). Additionally map:
   - User interaction points → `ASK` nodes
   - Plan-display steps → `SHOW_PLAN` nodes
   - Post-execution verification steps → `VERIFY_EXPECTED << assets/verify/verify-expected.md` node; create `assets/verify/verify-expected.md` with the expected-state checklist
   - If no explicit post-execution verification exists but the skill writes files or makes changes, add a `VERIFY_EXPECTED << assets/verify/verify-expected.md` node as the last step in the success branch and include it in the decision table with reason: "skill makes changes but has no verification step"
3. Ask: **"Which tree syntax? | Markdown list (`*`) | Box-drawing (tree characters)"**
4. Consult `framework-ops.md` (framework primitives — already loaded by the canopy tree) and any consumer-defined cross-skill ops the user mentions.
   - For each candidate op identified in step 2: if an equivalent already exists in primitives or consumer-shared ops, mark it as a shared reference — do not add it to the skill-local `references/ops.md`
   - For each candidate resource file: if equivalent content already exists, mark it as a shared reference — do not create a duplicate
5. Present a decision table before making any changes:

   | Content | Extracted from | Target file | Category | Reason |
   |---------|---------------|-------------|----------|--------|
   | `<description>` | `<source section>` | `<assets/<dir>/<filename>.md>` or shared ref | `<constants/policies/schemas/…>` | `<decision-rule rationale>` |

   Then show: tree structure preview | ops to create | skill name | shared references used. Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: CONVERT_TO_CANOPY` | `source: <source-file>` | `skill: <name>` | `tree-syntax: <markdown-list|box-drawing>` | `changes`.

6. Ask: **"Proceed? | Yes | Adjust | No"** — wait for response before touching any file.
7. Determine target skill name (infer from file name; ask if ambiguous).
8. Read `assets/policies/platform-targeting.md` and resolve the target platform. Resolve target location from `context.repo_context`:
   - `distribution` → `skills/<skill_name>/` at the repo root
   - `consumer` → `<skills_base>/<skill_name>/` per platform target
   If target directory already exists: Ask **"Directory exists. | Overwrite | Cancel"**
9. Create the Canopy skill directory and write all files. Skill file must be exactly `SKILL.md` (uppercase):
   - Copy the original `SKILL.md` to `SKILL.classic.md` before overwriting it (preserve the pre-conversion source)
   - `SKILL.md` in Canopy format with agentskills.io-compliant frontmatter — `name`, `description`, `compatibility` (declaring canopy-runtime requirement), `metadata` for non-spec fields. Body opens with safety preamble guard block. See `assets/policies/authoring-rules.md` for full composition rules.
   - `references/ops.md` only for ops not already covered
   - Category files (`assets/schemas/`, `assets/policies/`, etc.; `scripts/` for executables; `references/` for on-demand docs) only for content not already available elsewhere
10. Run VALIDATE inline. Report conversion notes and any items needing manual review.
11. Verify result against `assets/verify/convert-to-canopy-expected.md`.
12. Report: **Summary / Files created / Shared references used / Conversion notes / Manual review items**
