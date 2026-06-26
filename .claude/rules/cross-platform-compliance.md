---
paths:
  - "skills/canopy-runtime/references/runtime-claude.md"
  - "skills/canopy-runtime/references/runtime-copilot.md"
  - "skills/canopy-runtime/references/skill-resources.md"
  - "skills/canopy-runtime/references/ops.md"
  - "skills/canopy-runtime/references/ops/*.md"
  - "skills/canopy-runtime/assets/constants/marker-block.md"
  - "skills/canopy/assets/policies/platform-targeting.md"
  - "install.sh"
  - "install.ps1"
  - ".claude-plugin/plugin.json"
  - ".claude-plugin/marketplace.json"
---

# Rule: cross-platform compliance — Claude Code AND GitHub Copilot

Canopy is a **two-platform** framework. Every feature must work on **both** Claude Code and GitHub Copilot. A change that ships on one platform is not "shipped" — it's incomplete.

This is project-wide and load-bearing. Treat it like a CI gate even though there isn't one yet (see Enforcement below).

## What "compatible" means in practice

A feature is cross-platform-compatible when:

1. **Spec parity** — the runtime spec covers both. `skills/canopy-runtime/references/runtime-claude.md` and `runtime-copilot.md` must describe the feature in matching shape (same headings, same operations, equivalent semantics).
2. **Install parity** — every install path supports the feature uniformly. `install.sh`, `install.ps1`, `gh skill install`, and (Claude-only) the plugin marketplace must produce equivalent on-disk state for both platforms after install.
3. **Runtime semantics parity** — execution outcomes match. The same `SKILL.md` invoked on Claude Code and on GitHub Copilot must produce equivalent results modulo platform-native rendering. Subagent fan-out (`PARALLEL`, S2 markers) must dispatch correctly on both — Task tool on Claude, fleet/agent dispatch on Copilot.
4. **No hardcoded platform paths in skill content** — see [`platform-targeting.md`](../../skills/canopy/assets/policies/platform-targeting.md): the same `SKILL.md` must run on any platform when the files are present. Hardcoded `.claude/` / `.github/` / `.agents/` references in tree nodes are bugs.

## Where divergence shows up — and where to look

| Concern | Claude Code surface | GitHub Copilot surface | Parity check |
|---|---|---|---|
| Runtime spec | `runtime-claude.md` | `runtime-copilot.md` | Same H2 sections, same operations covered, equivalent semantics. Add a section to one → add it to the other. |
| Ambient activation | `CLAUDE.md` (marker block) | `.github/copilot-instructions.md` (marker block) | Same marker content, written by the same install paths. Tracked in `marker-block-parity.md`. |
| Skills root | `.claude/skills/` | `.github/skills/` | Plus cross-client `.agents/skills/` recognized by both. canopy-runtime resolves first-match. |
| Native subagent dispatch | Task tool, `Task(subagent_type=...)` | `/fleet`, `@CUSTOM-AGENT-NAME`, sequential-inline fallback | Same `**OP_NAME**` (S2 marker) call-site dispatches via the platform's native mechanism. |
| Install paths | plugin marketplace (`/plugin install canopy@canopy`), `gh skill install`, `install.sh` / `install.ps1` | `gh skill install`, `install.sh` / `install.ps1` | Plugin marketplace is Claude-only by Anthropic's design — Copilot reaches feature parity via `gh skill install` or the install script. |
| Slash commands | `/canopy`, `/canopy-debug` (or `/canopy:canopy` etc. for plugin install) | `/canopy`, `/canopy-debug` (no plugin namespacing) | Both runtimes' invocation forms are documented in their `runtime-*.md`. |

## How to apply

1. **Before committing** a change to runtime spec, framework primitives, the marker block, install scripts, or any skill body — ask: does this read or write platform-specific state? If yes, walk the parity table above.
2. **When editing one of `runtime-claude.md` / `runtime-copilot.md`**, open the other in the same session. The `paths:` frontmatter on this rule plus the `cross-platform-compliance` reminder makes the second file's parity status part of the same edit.
3. **When adding a primitive or dispatch mode**, both `runtime-claude.md` and `runtime-copilot.md` must gain matching coverage. Otherwise the agent-driven path on the missing-coverage platform is undefined behavior.
4. **When divergence is unavoidable** — say the platform genuinely lacks a primitive, or the install mechanism truly differs — document the divergence explicitly in BOTH `runtime-*.md` files (each side notes "this is Claude-only" / "this is Copilot-only" and a rationale). Silent divergence is not acceptable.
5. **Verify before merging** — at minimum, manually invoke a representative skill on both platforms (the framework's own `/canopy create`/`improve`/`validate` are good probes). For framework-spec PRs, this is non-optional.

## Anti-patterns this rule prevents

- **Adding a primitive only on one runtime spec.** PARALLEL was almost shipped with `runtime-claude.md` updated and `runtime-copilot.md` skipped — caught only because the parity check ran during review. A primitive that the Copilot-side runtime doesn't describe is a primitive that doesn't exist on Copilot.
- **Hardcoded `.claude/` paths in user-facing skill content.** Easy to write `Read \`.claude/skills/<skill>/...\`` reflexively; that breaks on Copilot. Skill `Read` paths must be relative to the skill dir.
- **Marker block drift between `CLAUDE.md` and `.github/copilot-instructions.md`.** Already covered by [`marker-block-parity.md`](marker-block-parity.md), which enforces 4-source-of-truth byte-identity.
- **Install-script asymmetry.** `install.sh` adds a feature but `install.ps1` doesn't — Windows Copilot users get a degraded experience. Always touch both.

## Enforcement

This rule is currently **documentation-only and reviewer-enforced** — same caveat as `authoring-ops-sync.md` and `examples-sync.md`. If repeated drift recurs, automation candidates:

- **Section-parity check** in `scripts/validate.sh`: `runtime-claude.md` and `runtime-copilot.md` must have the same set of H2 section names. Fail CI on mismatch.
- **Mandatory-pair edit**: when a PR touches `runtime-claude.md`, require it to also touch `runtime-copilot.md` (or carry a `[platform-divergence-rationale: …]` token in the commit body).
- **Install-script symmetry**: structural diff of `install.sh` and `install.ps1` to detect features added on one but not the other.

## Related rules

- [`authoring-ops-sync.md`](authoring-ops-sync.md) — keep the canopy authoring agent aware of new framework features (different concern: agent visibility, not platform parity).
- [`marker-block-parity.md`](marker-block-parity.md) — the marker block is one of the cross-platform-bearing artifacts; this rule is the broader umbrella.
- [`examples-sync.md`](examples-sync.md) — user-facing demos must show the feature on both platforms (in practice: example skills should work unchanged on Claude and Copilot).
- `skills/canopy/assets/policies/platform-targeting.md` — authoring-time policy for ops that create skills; ensures produced skills have no hardcoded platform paths.
