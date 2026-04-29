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
   compatibility: Requires canopy-runtime for Claude Code (`gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`) or GitHub Copilot (`--agent github-copilot`). Execution on other platforms is not supported.
   metadata:
     argument-hint: "<required-arg> [optional-arg]"
   ---

   > **Runtime required:** This skill uses Canopy tree notation and requires the
   > canopy-runtime execution engine. If canopy-runtime is not active in your
   > current context, **stop immediately** — do not attempt to execute this skill.
   > Inform the user: "canopy-runtime must be installed and activated first.
   > Run: `gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`"

   <Preamble: parse $ARGUMENTS and set context variables here.>

   ---

   <!-- Optional: include ## Agent when the skill needs an explore subagent.
        Pick one of the three canonical shapes (A/B/C) — see
        `assets/policies/authoring-rules.md` → "## Agent body shape".

   ## Agent

   **explore** — <one-line task summary>. Output contract: `assets/schemas/explore-schema.json`.
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
   compatibility: Requires canopy-runtime for Claude Code (`gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`) or GitHub Copilot (`--agent github-copilot`). Execution on other platforms is not supported.
   metadata:
     argument-hint: "<required-arg> [optional-arg]"
   ---

   > **Runtime required:** This skill uses Canopy tree notation and requires the
   > canopy-runtime execution engine. If canopy-runtime is not active in your
   > current context, **stop immediately** — do not attempt to execute this skill.
   > Inform the user: "canopy-runtime must be installed and activated first.
   > Run: `gh skill install kostiantyn-matsebora/claude-canopy canopy-runtime --agent claude-code`"

   <Preamble: parse $ARGUMENTS and set context variables here.>

   ---

   <!-- Optional: include ## Agent when the skill needs an explore subagent.
        Pick one of the three canonical shapes (A/B/C) — see
        `assets/policies/authoring-rules.md` → "## Agent body shape".

   ## Agent

   **explore** — <one-line task summary>. Output contract: `assets/schemas/explore-schema.json`.
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
