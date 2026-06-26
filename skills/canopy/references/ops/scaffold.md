# SCAFFOLD

Generate a blank skill skeleton with the standard agentskills.io directory layout.

1. If no skill name given, ask for it. Validate it is kebab-case; refuse if not.
2. Read `assets/policies/platform-targeting.md` and resolve the target platform.
3. Resolve target skill location from `context.repo_context`:
   - `distribution` → `skills/<skill_name>/` at the repo root
   - `consumer` → `<skills_base>/<skill_name>/` per platform target (`.claude/skills/` or `.github/skills/`)
   Check if the target directory already exists — if so, `END Skill already exists.`
4. Ask: **"Which tree syntax? | Markdown list (`*`) | Box-drawing (tree characters)"**
5. Show plan: skill name | target location | files to create | directories to create. Then emit an apply block per `assets/constants/apply-block-protocol.md` with fields: `op: SCAFFOLD` | `skill: <name>` | `target: <full-path>` | `tree-syntax: <markdown-list|box-drawing>` | `platform: <claude|copilot>`.

6. Ask: **"Proceed? | Yes | No"**
7. Create the target directory and write `SKILL.md` (uppercase, exact spelling). Use the appropriate variant per chosen tree syntax. Both variants are based on `assets/templates/skill.md`:

   `SKILL.md` (markdown list variant):
   ```markdown
   ---
   name: <skill-name>
   description: <one-line description>
   compatibility: Requires the canopy-runtime skill (published at github.com/kostiantyn-matsebora/canopy). Install with any agentskills.io-compatible tool — e.g. `gh skill install`, `git clone`, the repo's `install.sh`/`install.ps1`, or the Claude Code plugin marketplace. Supports Claude Code and GitHub Copilot.
   metadata:
     argument-hint: "<required-arg> [optional-arg]"
     canopy-features: [interaction]
   ---

   > **Runtime required.** This skill uses Canopy tree notation; canopy-runtime must be active.
   >
   > **Detect canopy-runtime** — present if either:
   > - `canopy-runtime/SKILL.md` exists under `.claude/skills/`, `.github/skills/`, or `.agents/skills/`, OR
   > - a canopy-runtime marker block exists in `CLAUDE.md` or `.github/copilot-instructions.md`.
   >
   > **If neither is present** — install canopy-runtime first (see the `compatibility` field for the source and install options), then re-invoke this skill.
   >
   > Do not interpret the `## Tree` without canopy-runtime active.

   <Preamble: parse $ARGUMENTS and set context variables here.>

   ---

   <!-- Optional: when the skill needs an explore subagent, define EXPLORE
        as a marked op in references/ops.md (preferred) and use **EXPLORE**
        (bold) as the first tree node. See `assets/policies/authoring-rules.md`
        → "## Subagent contract" for the marker shape.
   -->

   ## Tree

   * <skill-name>
     * SHOW_PLAN >> <field1> | <field2>
     * ASK << Proceed? | Yes | No
     * <do the thing>

   ## Rules

   - <invariant that applies throughout execution>

   ## Response: Summary / Changes / Notes
   ```

   `SKILL.md` (box-drawing variant):
   ```markdown
   ---
   name: <skill-name>
   description: <one-line description>
   compatibility: Requires the canopy-runtime skill (published at github.com/kostiantyn-matsebora/canopy). Install with any agentskills.io-compatible tool — e.g. `gh skill install`, `git clone`, the repo's `install.sh`/`install.ps1`, or the Claude Code plugin marketplace. Supports Claude Code and GitHub Copilot.
   metadata:
     argument-hint: "<required-arg> [optional-arg]"
     canopy-features: [interaction]
   ---

   > **Runtime required.** This skill uses Canopy tree notation; canopy-runtime must be active.
   >
   > **Detect canopy-runtime** — present if either:
   > - `canopy-runtime/SKILL.md` exists under `.claude/skills/`, `.github/skills/`, or `.agents/skills/`, OR
   > - a canopy-runtime marker block exists in `CLAUDE.md` or `.github/copilot-instructions.md`.
   >
   > **If neither is present** — install canopy-runtime first (see the `compatibility` field for the source and install options), then re-invoke this skill.
   >
   > Do not interpret the `## Tree` without canopy-runtime active.

   <Preamble: parse $ARGUMENTS and set context variables here.>

   ---

   <!-- Optional: when the skill needs an explore subagent, define EXPLORE
        as a marked op in references/ops.md (preferred) and use **EXPLORE**
        (bold) as the first tree node. See `assets/policies/authoring-rules.md`
        → "## Subagent contract" for the marker shape.
   -->

   ## Tree

   \`\`\`
   <skill-name>
   ├── SHOW_PLAN >> <field1> | <field2>
   ├── ASK << Proceed? | Yes | No
   └── <do the thing>
   \`\`\`

   ## Rules

   - <invariant that applies throughout execution>

   ## Response: Summary / Changes / Notes
   ```

   `references/ops.md`:
   ```markdown
   # <skill-name> — Local Ops

   ---

   ## MY_OP << input >> output

   <Description of what this op does.>

   * MY_OP << input >> output
     * IF << condition
       * branch action
     * ELSE
       * other action
   ```

8. Create the standard agentskills.io subdirectory tree:
   - `scripts/` (executable code)
   - `references/` (with `ops.md` from step 7)
   - `assets/templates/`, `assets/constants/`, `assets/schemas/`, `assets/checklists/`, `assets/policies/`, `assets/verify/`
9. Verify result against `assets/verify/scaffold-expected.md`.
10. Report: **Summary / Files created / Next steps**
