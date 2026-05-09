# Rule: Writing style — structured, not stream-of-consciousness

**Applies to every change you author in this repo and any repo it produces** — no surface is exempt:

- Docs (`docs/*.md`, `README.md`, `CONTRIBUTING.md`, `CLAUDE.md`)
- CHANGELOG entries
- Commit message bodies and PR descriptions
- GitHub Release notes (drafted from CHANGELOG; same rule applies)
- Status updates, summaries, and replies you write back to the user during a session
- **Skill content** — `SKILL.md` (preamble, tree nodes, `## Rules`, `## Response:` lines, the description in frontmatter), `references/ops.md` and `references/ops/*.md` (op signatures and bodies), `references/*.md` (supporting docs), `assets/policies/*.md`, `assets/constants/*.md`, `assets/checklists/*.md`, `assets/verify/*.md`, anything else inside a skill

A reader should grok the shape in one pass.

- **Lead with the claim, then break out the details.** No multi-clause prose paragraphs that bury the point.
- **Bullets, not run-on sentences.** Anything joined by `;` `—` `and also` `additionally` is a candidate for splitting.
- **Label the bullets.** `**Who writes the marker block:**`, `**By install path:**`, `**Idempotent —**` — short bold labels at the front of each bullet so the eye finds the relevant one fast.
- **Tables for matrices.** When information has two axes (e.g. install path × who writes the marker block), use a table or a labeled bulleted list. Never inline a 3-way comparison in prose.
- **Cross-reference instead of restating.** If the same content lives in two places, the second reference should link/point to the first, not repeat.
- **Consistent verb mood.** Imperative for instructions ("Write the marker block"), declarative for spec ("The marker block is written by…"). Don't mix within a single block.

Anti-pattern (mindflow):

> canopy-runtime self-activation: SKILL.md now includes an Activation section that writes the marker block to CLAUDE.md (Claude Code) or .github/copilot-instructions.md (Copilot) the first time an agent loads the runtime SKILL.md — no human /canopy:canopy activate needed. Note: this is agent-driven, not install-tool-driven. Pure CLI install paths (gh skill install, plugin marketplace) only place files; the marker block is written when the next agent invocation loads the runtime. install.sh/install.ps1 additionally write the marker block during install (shell-context scripts have no agent to defer to), so those paths leave the project fully activated.

Structured replacement:

> **canopy-runtime self-activation.** Replaces explicit `/canopy:canopy activate`.
>
> **Who writes the marker block, by install path:**
> - `install.sh` / `install.ps1` — script writes it during install. Project is fully activated when install completes.
> - `gh skill install` — file placement only. Block is written by the next agent invocation that loads `canopy-runtime/SKILL.md`.
> - Plugin marketplace — same as `gh skill install`.
>
> **Idempotent.** Running on a fully activated project is a no-op.

Apply this rule when authoring or editing any markdown in this repo. When you catch existing content that violates it, restructure it as part of your change.

> **No `paths` frontmatter** — this rule loads unconditionally because writing style applies to every artifact authored in this repo (markdown content, commit messages, PR descriptions, status updates), not just files matching a pattern.
