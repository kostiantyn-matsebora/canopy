---
title: Getting Started
nav_order: 2
description: "Install Canopy on Claude Code or GitHub Copilot, run your first /canopy command, and trace what the agent does."
permalink: /getting-started/
---

# Getting Started

Canopy ships as three [Agent Skills](https://agentskills.io), split along **authoring vs. execution** lines. Same skills run on Claude Code and GitHub Copilot unchanged — only the install path differs.

| Skill | Role | Slash command | Notes |
|---|---|---|---|
| `canopy-runtime` | Execution engine — interprets canopy-flavored skills (platform detection, primitives, op lookup chain, category semantics, subagent contract). | hidden from `/` | Loaded ambiently via `CLAUDE.md` / `.github/copilot-instructions.md`. Install alone to just *execute* existing canopy skills. |
| `canopy` | Authoring agent — create / modify / validate / improve / scaffold / refactor / advise on / convert canopy skills. | `/canopy` | Depends on `canopy-runtime`. |
| `canopy-debug` | Trace wrapper — phase banners + per-node tracing for any canopy skill's execution. | `/canopy-debug <skill>` | Optional. |

## Authoring vs. execution

| If you want to… | Install | Always-on | When active¹ |
|---|---|---|---|
| Run canopy skills someone else wrote | `canopy-runtime` only | ~6 lines | ~2–5k tok |
| Author or edit canopy skills | `canopy` + `canopy-runtime` | ~6 lines | ~8k tok |
| Trace / debug a skill's execution | `canopy-debug` + `canopy-runtime` | ~6 lines | ~7k tok |
| Everything (default) | All three | ~6 lines | ~8k tok |

¹ **Context budget.** Canopy loads lazily, so the two size columns differ sharply:

- **Always-on** — the persistent marker block written to `CLAUDE.md` / `.github/copilot-instructions.md`. A trigger + pointer only (~6 lines), identical for every option. This is the *only* cost a session pays while no canopy skill is running.
- **When active** — context pulled in once a canopy skill runs or `/canopy` is invoked. Read this as two levels, not one number:
  - **Entry point (~2k tok)** — `canopy-runtime/SKILL.md`, what the marker block points to and what loads first for *any* canopy skill.
  - **Fully engaged** — the entry point plus the spec slices a skill actually touches: `skill-resources.md` (category semantics, tree format, op-lookup chain), one platform file (`runtime-{claude,copilot}.md`), and per-op slices on demand. A trivial skill stays near the ~2k floor; execution lands **~2–5k**. Authoring (`/canopy`) reads the full spec up front, so it sits higher at **~8k**.

Figures are rough (≈ tokens) and scale with skill size. Once loaded, the runtime spec rides the prompt cache across the agent loop — paid once, near-free on later turns. "Everything" loads per invocation, not all at once; the heaviest single active skill sets the ceiling.

The install script below installs all three by default. `gh skill install` and `/plugin install` let you pick individual skills.

---

## Install for Claude Code

Three install paths; pick whichever fits your workflow. All three land the same skill files; only the discovery and namespace differ.

### Option 1 — Claude Code plugin marketplace (recommended, no external CLI)

Inside a Claude Code session:

```
/plugin marketplace add kostiantyn-matsebora/canopy
/plugin install canopy@canopy
```

| Command | What it does | Scope |
|---|---|---|
| `/plugin marketplace add …` | Register the canopy marketplace | user — once per machine |
| `/plugin install canopy@canopy` | Adds `/canopy:canopy` + `/canopy:canopy-debug` (plugin-namespaced) | user — once per machine |

**Canopy-runtime self-activates on first load.** The runtime's `## Activation` section writes the marker block to `CLAUDE.md` automatically when an agent first loads `canopy-runtime/SKILL.md`. No manual `/canopy:canopy activate` step is required. The `activate` op is available if you need to force a marker-block re-write after upgrading to a release with new marker content.

Update: `/plugin update canopy@canopy`. The next agent invocation re-applies activation idempotently.

### Option 2 — `gh skill` (GitHub CLI v2.90.0+)

Skills land under `.claude/skills/<name>/` and become available as `/canopy` and `/canopy-debug` (no namespace).

```bash
gh skill install kostiantyn-matsebora/canopy canopy-runtime --agent claude-code --scope project --pin v0.22.0
gh skill install kostiantyn-matsebora/canopy canopy         --agent claude-code --scope project --pin v0.22.0
gh skill install kostiantyn-matsebora/canopy canopy-debug   --agent claude-code --scope project --pin v0.22.0
```

The marker block is written by the next agent invocation that loads `canopy-runtime/SKILL.md` (canopy-runtime self-activates). No manual activate step required.

#### Cross-client install (one location for both Claude Code and Copilot)

```bash
gh skill install kostiantyn-matsebora/canopy canopy-runtime --dir .agents/skills --pin v0.22.0
gh skill install kostiantyn-matsebora/canopy canopy         --dir .agents/skills --pin v0.22.0
gh skill install kostiantyn-matsebora/canopy canopy-debug   --dir .agents/skills --pin v0.22.0
```

`gh skill 2.91+` defaults Copilot installs to `.agents/skills/` automatically. Both Claude Code and GitHub Copilot read this root, so a single install serves both hosts without duplicating files. canopy-runtime self-identifies the active host at runtime.

### Option 3 — Install script (recommended — also wires ambient runtime activation in one step)

Installs all three skills + writes the canopy-runtime marker block to `CLAUDE.md` / `.github/copilot-instructions.md`. Idempotent — re-run to update. `--target claude|copilot|both` handles either platform in a single pass.

```bash
# macOS / Linux — defaults to --target claude
curl -sSL https://raw.githubusercontent.com/kostiantyn-matsebora/canopy/master/install.sh | bash
```

```powershell
# Windows (PowerShell) — defaults to -Target claude
irm https://raw.githubusercontent.com/kostiantyn-matsebora/canopy/master/install.ps1 | iex
```

Flags:

| Purpose | bash | PowerShell |
|---|---|---|
| Pin version | `--version 0.22.0` | `-Version 0.22.0` |
| Install a branch / tag / commit SHA (pre-release testing) | `--ref canopy-as-agent-skill` | `-Ref canopy-as-agent-skill` |
| Claude Code only | `--target claude` (default) | `-Target claude` (default) |
| GitHub Copilot only | `--target copilot` | `-Target copilot` |
| **Both platforms in one run** | `--target both` | `-Target both` |
| **Cross-client (`.agents/skills/`)** | `--target agents` | `-Target agents` |

Version resolution order:
1. `--ref` / `-Ref` flag (git branch/tag/SHA — bypasses version resolution; does NOT write `.canopy-version`)
2. `--version` / `-Version` flag (`v<version>` tag)
3. `.canopy-version` file — commit this to your repo to pin a version across collaborators
4. Latest release tag from GitHub

For version-pinned installs, the script writes `.canopy-version` after a successful install, so the next run reinstalls the same version unless you bump it. `--ref` installs skip this write (they're transient by design).

For user-scope install (available across all your projects), run the script from `~` instead of your project root.

---

## Install for GitHub Copilot

Skills land under `.github/skills/<name>/` and become available via `/canopy` and `/canopy-debug` in Copilot Chat. Copilot does not read `.claude/`, so the install target is different — but the skills themselves are identical.

### With `gh skill` (GitHub CLI v2.90.0+, recommended)

```bash
gh skill install kostiantyn-matsebora/canopy canopy-runtime --agent github-copilot --scope project --pin v0.22.0
gh skill install kostiantyn-matsebora/canopy canopy         --agent github-copilot --scope project --pin v0.22.0
gh skill install kostiantyn-matsebora/canopy canopy-debug   --agent github-copilot --scope project --pin v0.22.0
```

`gh skill 2.91+` defaults Copilot installs to `.agents/skills/` (cross-client root) — pass `--dir .github/skills` if you want the Copilot-only path. canopy-runtime self-activates on first load: the runtime writes the marker block to `.github/copilot-instructions.md` when an agent first loads `canopy-runtime/SKILL.md`. No manual activate step required.

### Install script (no external CLI required)

Same `install.sh` / `install.ps1` as the Claude Code section — just pass `--target copilot` (or `-Target copilot` on PowerShell). Use `--target both` to install for Claude Code and Copilot in one pass.

```bash
# macOS / Linux
curl -sSL https://raw.githubusercontent.com/kostiantyn-matsebora/canopy/master/install.sh | bash -s -- --target copilot
```

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/kostiantyn-matsebora/canopy/master/install.ps1 -OutFile install.ps1
pwsh ./install.ps1 -Target copilot
```

Flags + version resolution are identical to the Claude Code option above.

---

## Updating

- **Plugin:** `/plugin marketplace update canopy` then `/plugin install canopy@canopy` (overwrites with the latest).
- **`gh skill`:** `gh skill update kostiantyn-matsebora/canopy <skill> --pin vX.Y.Z` (per-skill).
- **Install script:** bump `.canopy-version` (or pass `--version`/`-Version`) and re-run the same one-liner.

Inspect a skill before installing: `gh skill preview kostiantyn-matsebora/canopy <skill>`.

---

## Usage

### Using the `canopy` Agent

The `canopy` agent handles the full skill lifecycle.

**Claude Code:**

```
/canopy improve bump-version
/canopy create a skill that bumps semantic versions
/canopy validate the bump-version skill
```

**GitHub Copilot:**

Same `/canopy` slash command via the wrapper skill installed at `.github/skills/canopy/`:

```
/canopy improve bump-version
/canopy create a skill that bumps semantic versions
```

Explicit form (always works):

```
Follow .github/skills/canopy/SKILL.md and improve bump-version
```

| Operation | Example |
|-----------|---------|
| **Create** | `/canopy create a skill that bumps semantic versions` |
| **Modify** | `/canopy add a dry-run option to the deploy-service skill` |
| **Scaffold** | `/canopy scaffold a blank skill called api-docs` |
| **Convert to Canopy** | `/canopy convert my deploy.md skill to canopy format` |
| **Validate** | `/canopy validate the bump-version skill` |
| **Improve** | `/canopy improve the deploy-service skill` |
| **Advise** | `/canopy how should I add a verify step to the review-api skill?` |
| **Refactor skills** | `/canopy refactor skills — extract shared ops` |
| **Convert to regular** | `/canopy convert the review-file skill back to a plain skill` |
| **Help** | `/canopy help` |

For **Create** and **Scaffold**, the agent asks your preferred tree syntax — **markdown list** (`*` nested bullets) or **box-drawing** (fenced tree characters) — before writing anything.

Every operation shows a plan and asks for confirmation before making changes.

### Getting Help

Run `/canopy help` (or just ask "help") to see the full operations reference — what each op does, example invocations, skill anatomy, and the op lookup order.

### Writing a Skill Manually

To write skills by hand, start with [Concepts](concepts/) for the model (skill anatomy, the `## Agent` block, ops, category resources, the execution stages) and [Reference](reference/) for the formal grammar (primitives, runtimes, frontmatter validation, directory-layout semantics).
