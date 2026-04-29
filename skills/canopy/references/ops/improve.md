# IMPROVE

Align an existing Canopy skill with the current Canopy framework rules — fix structural violations, re-categorise misplaced resources, extract any remaining inline content, and (when appropriate) migrate legacy flat layout to the standard agentskills.io layout. Logic and intent are preserved; only structure and resource placement change.

1. Locate the skill directory using Glob.
2. Read all files: `SKILL.md`, `references/ops.md` or legacy `ops.md` (if present), and all category subdir files. Detect layout (standard vs. legacy flat).
3. Run VALIDATE inline to collect all Errors, Warnings, and Optimizations. Record as `validate_findings`.
4. Consult `framework-ops.md` (framework primitives — already loaded by the canopy tree) and any consumer-defined cross-skill ops the user mentions.
   - Note any ops or resources in the skill that duplicate primitives or consumer-shared content — record as `shared_findings`
5. Audit every category subdir file using the **Category Decision Flowchart** from `assets/policies/category-decision-flowchart.md` (in order — use the first matching test). Record all misplacements as `audit_findings`.

   A file is misplaced when the flowchart assigns it to a different category than its current directory.

   > **Do not proceed to step 6 until every category file has been evaluated against every row in the flowchart.**
   > The decision table must contain rows from all three sources: `validate_findings`, `shared_findings`, and `audit_findings`.
   > An empty `audit_findings` is only valid when every category file has been explicitly checked and found correctly placed.

6. If the skill uses legacy flat layout, optionally include a **layout migration** to the standard agentskills.io layout in the decision table:
   - `commands/` → `scripts/`
   - `ops.md` → `references/ops.md` (or `ops/` → `references/ops/`)
   - `templates/` → `assets/templates/`
   - `constants/` → `assets/constants/`
   - `schemas/` → `assets/schemas/`
   - `checklists/` → `assets/checklists/`
   - `policies/` → `assets/policies/`
   - `verify/` → `assets/verify/`

   Layout migration is optional (legacy layout still works) — present it as a single row in the decision table with action `migrate-layout` and let the user opt in.

7. Present a decision table combining all finding sets:

   | Content | Current file | Target file | Action | Source | Reason |
   |---------|-------------|-------------|--------|--------|--------|
   | `<description>` | `<current location>` | `<target location>` | move / extract / fix / replace with shared ref / create / delete / migrate-layout | VALIDATE / shared / audit | `<decision-rule rationale>` |

   Then list: new files to create | files to delete | shared references to introduce. Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: IMPROVE` | `skill: <name>` | `changes`.

8. Ask: **"Proceed? | Yes | Adjust | No"** — wait for response before touching any file.
9. Apply all changes:
   - Read `assets/policies/preservation-rules.md` before modifying any file
   - Fix every Error and Warning from VALIDATE — including agentskills.io compliance gaps: missing `compatibility` field, missing safety preamble, `argument-hint`/`user-invocable` at frontmatter root (move to `metadata`), lowercase `skill.md` filename (rename to `SKILL.md`)
   - Relocate misplaced category file content per `audit_findings`
   - Extract any remaining inline blocks from `SKILL.md` to the correct category files
   - Replace skill-local op definitions or resource files that duplicate shared content: delete the local copy and update the reference in `SKILL.md` / `references/ops.md` to point to the shared location
   - If layout migration was approved: move directories per the mapping above and rewrite every `Read` reference in `SKILL.md` and op files
   - If the skill makes changes to files but has no `VERIFY_EXPECTED` node, include a row in the decision table: `— | — | assets/verify/verify-expected.md | create` with reason "skill makes changes but has no verification step"; add `VERIFY_EXPECTED << assets/verify/verify-expected.md` as the last node inside the success branch and create `assets/verify/verify-expected.md` with an appropriate expected-state checklist (use `verify/` instead of `assets/verify/` for legacy-layout skills)
   - Preserve existing tree syntax (do not switch `*` ↔ box-drawing unless asked)
   - Do not change skill logic or intent
10. Run VALIDATE inline on all modified files. Fix every remaining Error and Warning — not just newly introduced ones, but any violation still present after the changes. Repeat until VALIDATE reports no Errors or Warnings on any file.
11. Verify result against `assets/verify/improve-expected.md`.
12. Report: **Summary / Issues fixed / Shared references introduced / Files changed / Files created / Files deleted**
