---
title: Home
description: "Canopy — AI skills as executable code, not prose."
permalink: /
---

# Canopy

[![Latest Release](https://img.shields.io/github/v/release/kostiantyn-matsebora/canopy?label=release&color=0969da)](https://github.com/kostiantyn-matsebora/canopy/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/kostiantyn-matsebora/canopy/ci.yml?branch=master&label=CI)](https://github.com/kostiantyn-matsebora/canopy/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-0969da)](https://github.com/kostiantyn-matsebora/canopy/blob/master/LICENSE)
[![VS Code Extension](https://vsmarketplacebadges.dev/version-short/canopy-ai.canopy-skills.svg?label=vscode)](https://marketplace.visualstudio.com/items?itemName=canopy-ai.canopy-skills)

[![agentskills.io](https://img.shields.io/badge/agentskills.io-compatible-0969da)](https://agentskills.io)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-D97757?logo=anthropic&logoColor=white)](https://code.claude.com/docs/en/skills)
[![GitHub Copilot](https://img.shields.io/badge/GitHub%20Copilot-compatible-000?logo=githubcopilot&logoColor=white)](https://code.visualstudio.com/docs/copilot/customization/agent-skills)

**AI skills as executable code, not prose.**

AI skills written as prose are instructions. Instructions get interpreted. Interpretations
drift. When a skill fails, you're re-reading sentences trying to figure out which one was
misunderstood. When it works, you're not entirely sure why it did.

**Canopy makes skills programs.**

---

## Why Canopy?

<div class="why-canopy-grid">
  <article class="why-card">
    <h3><span class="why-emoji">🎯</span> Deterministic</h3>
    <p>Skills run identically every time. The tree is explicit — no interpretation, no drift.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">♻️</span> Reusable ops</h3>
    <p>Define <code>DEPLOY</code>, <code>VERIFY</code>, <code>ROLLBACK</code> once in <code>ops.md</code>. One change keeps every skill that uses them in sync.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🔎</span> Transparent</h3>
    <p>The tree shows execution order before anything runs. When it fails, the failing node is obvious — no re-reading prose.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">📁</span> Organized resources</h3>
    <p>schemas · templates · commands · constants · policies · verify. Find what you need instantly.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🔌</span> agentskills.io-native</h3>
    <p>Meta-framework on the spec — same <code>SKILL.md</code>, same install, same <code>compatibility</code> field. Nothing canopy-specific leaks.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🤖</span> Autonomous-agent ready</h3>
    <p>Deterministic trees + explicit primitives let workflow engines (LangGraph, AutoGen, CrewAI, Goose) drive skills without prompt-engineering the control flow.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🌐</span> Cross-platform</h3>
    <p>Write once; runs on Claude Code and GitHub Copilot unchanged. The interpreter adapts at runtime.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">✨</span> Editor-native</h3>
    <p>VS Code extension: completions, hover docs, go-to-definition, live diagnostics. Broken op references surface before the skill runs.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🚀</span> Zero learning curve</h3>
    <p><code>/canopy</code> scaffolds, validates, improves, and converts for you. No syntax to memorize before you ship your first skill.</p>
  </article>
</div>

---

## How it works

> The tree is the source of truth. The platform is just a detail.

Every Canopy skill is a `SKILL.md` file (uppercase, exact spelling per the agentskills.io spec) — platform-agnostic by design. When a skill runs, the `canopy` agent detects whether you're on Claude Code or GitHub Copilot, loads the matching runtime spec, then executes the tree using platform-appropriate primitives. The same skill file works on both platforms without modification.

Here's a complete skill — frontmatter, execution tree, and all:

<div class="skill-example" markdown="1">

```markdown
---
name: release
description: Bump version and update changelog.
compatibility: Requires canopy-runtime — kostiantyn-matsebora/canopy
metadata:
  argument-hint: "[major|minor|patch]"
---

> **Runtime required.** canopy-runtime must be active.

Parse `$ARGUMENTS` for bump tier (defaults to `patch`).

## Tree
* release
  * **EXPLORE_TARGET** >> ctx
  * SWITCH << $ARGUMENTS
    * CASE << major
      * BUMP_MAJOR << ctx.version >> new
    * CASE << minor
      * BUMP_MINOR << ctx.version >> new
    * DEFAULT
      * BUMP_PATCH << ctx.version >> new
  * SHOW_PLAN >> new | ctx.files | changelog
  * ASK << Proceed? | Yes | No
  * IF << No
    * END Cancelled.
  * PARALLEL
    * **WRITE_VERSION** << ctx.files | new
    * **WRITE_CHANGELOG** << new
  * VERIFY_EXPECTED << assets/verify/release.md

## Rules
* Never write without SHOW_PLAN + ASK confirmation.

## Response: new | files_bumped | changelog_status
```

</div>

> Subagent dispatch via `**OP_NAME**` markers, multi-way `SWITCH/CASE`, parallel writes via `PARALLEL`, plus a plan/confirm gate and post-execution verify — this is **Canopy** in action.

---

## Quick Start

**Claude Code** — inside a session, no external CLI needed:

```
/plugin marketplace add kostiantyn-matsebora/canopy
/plugin install canopy@canopy
```

**GitHub Copilot** — one-shot install script:

```bash
curl -sSL https://raw.githubusercontent.com/kostiantyn-matsebora/canopy/master/install.sh | bash -s -- --target copilot
```

```powershell
irm https://raw.githubusercontent.com/kostiantyn-matsebora/canopy/master/install.ps1 | iex -Target copilot
```

Both install all three skills (`canopy-runtime`, `canopy`, `canopy-debug`) and self-activate the runtime on first agent load. After install, run `/canopy help` to see what's available.

For all install paths, flags, the authoring-vs-execution split, updating, and the `/canopy` operations reference, see **[Getting Started](./getting-started/)**.

---

## Where to next

<div class="why-canopy-grid">
  <article class="why-card">
    <h3>Getting Started</h3>
    <p>Full install paths, the <code>/canopy</code> operations reference, and a first-skill walkthrough. <a href="./getting-started/">→</a></p>
  </article>
  <article class="why-card">
    <h3>Concepts</h3>
    <p>How Canopy thinks about skills — tree, ops, subagents, the execution model, the runtime/authoring split. <a href="./concepts/">→</a></p>
  </article>
  <article class="why-card">
    <h3>Terminology</h3>
    <p>Glossary — one-sentence definitions for every Canopy term, each linked to the relevant deep-dive. <a href="./terminology/">→</a></p>
  </article>
  <article class="why-card">
    <h3>Reference</h3>
    <p>Formal spec: framework grammar, primitives, per-platform runtime rules. <a href="./reference/">→</a></p>
  </article>
  <article class="why-card">
    <h3>VS Code Extension</h3>
    <p>IntelliSense, semantic diagnostics, hover docs, and go-to-definition for canopy skills. <a href="./vscode/">→</a></p>
  </article>
  <article class="why-card">
    <h3>Examples</h3>
    <p>A working project to learn from — example skills, vendored framework. <a href="https://github.com/kostiantyn-matsebora/canopy-examples">GitHub →</a></p>
  </article>
</div>

---

## License

MIT — see [LICENSE](https://github.com/kostiantyn-matsebora/canopy/blob/master/LICENSE).
