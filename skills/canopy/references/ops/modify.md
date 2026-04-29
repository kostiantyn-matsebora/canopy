# MODIFY

Make targeted changes to an existing Canopy skill.

1. Locate the skill directory using Glob.
2. Read all files: `SKILL.md`, `references/ops.md` (or legacy `ops.md`) if present, and all category subdir files (standard layout under `assets/` / `scripts/` / `references/`, or legacy flat layout at the skill root).
3. Understand the requested changes.
4. Present a decision table before making any changes:

   | Item | File | Change | Reason |
   |------|------|--------|--------|
   | `<symbol or section>` | `<file>` | `<what will change>` | `<why>` |

   Then list: new files to create | files to delete (if any). Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: MODIFY` | `skill: <name>` | `changes`.

5. Ask: **"Proceed? | Yes | Adjust | No"** — wait for response before touching any file.
6. Apply changes:
   - Read `assets/policies/preservation-rules.md` before making any edits
   - Edit `SKILL.md` and/or `references/ops.md` (or legacy `ops.md`) as needed
   - Create, edit, or remove category files as needed
   - Preserve the existing directory layout (legacy flat vs. standard `scripts/`/`references/`/`assets/`) — MODIFY does not silently restructure
   - If the skill has `## Tree` and is missing the `compatibility` field or safety preamble, add them (gap-fix is allowed because their absence violates compliance)
7. Verify result against `assets/verify/modify-expected.md`.
8. Report: **Summary / Files changed**
