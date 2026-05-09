# Canopy <img src="../assets/icons/logo-ai-skills.svg" align="right" width="60%" />

[![Latest Release](https://img.shields.io/github/v/release/kostiantyn-matsebora/claude-canopy?label=release&color=0969da)](https://github.com/kostiantyn-matsebora/claude-canopy/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/kostiantyn-matsebora/claude-canopy/ci.yml?branch=master&label=CI)](https://github.com/kostiantyn-matsebora/claude-canopy/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-0969da)](../LICENSE)
[![VS Code Extension](https://vsmarketplacebadges.dev/version-short/canopy-ai.canopy-skills.svg?label=vscode)](https://marketplace.visualstudio.com/items?itemName=canopy-ai.canopy-skills)

[![agentskills.io](https://img.shields.io/badge/agentskills.io-compatible-0969da)](https://agentskills.io)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-D97757?logo=anthropic&logoColor=white)](https://code.claude.com/docs/en/skills)
[![GitHub Copilot](https://img.shields.io/badge/GitHub%20Copilot-compatible-000?logo=githubcopilot&logoColor=white)](https://code.visualstudio.com/docs/copilot/customization/agent-skills)

**AI skills as executable code, not prose.**

AI skills written as prose are instructions. Instructions get interpreted. Interpretations
drift. When a skill fails, you're re-reading sentences trying to figure out which one was
misunderstood. When it works, you're not entirely sure why it did.

**Canopy makes skills programs.**

> 📖 **Full documentation:** <https://kostiantyn-matsebora.github.io/claude-canopy>

---

## Why Canopy?

```
Canopy
├── 🎯 DETERMINISTIC
│   ├── skills run identically every time
│   └── the tree is explicit — no interpretation, no drift
│
├── ♻️ REUSABLE OPS
│   ├── define DEPLOY, VERIFY, ROLLBACK once in ops.md
│   └── one change keeps every skill that uses them in sync
│
├── 🔎 TRANSPARENT
│   ├── the tree shows execution order before anything runs
│   └── when it fails, the failing node is obvious — no re-reading prose
│
├── 📁 ORGANIZED RESOURCES
│   ├── schemas · templates · commands · constants · policies · verify
│   └── find what you need instantly; no hunting through paragraphs
│
├── 🔌 AGENTSKILLS-NATIVE
│   ├── meta-framework on top of agentskills.io — same SKILL.md, same install (`gh skill install`), same `compatibility` field
│   └── nothing canopy-specific leaks: an agent with zero canopy knowledge can install, resolve deps, activate, and execute using only the standard
│
├── 🤖 AUTONOMOUS-AGENT READY
│   ├── deterministic trees + explicit primitives let workflow engines (LangGraph, AutoGen, CrewAI, Goose) drive canopy skills without prompt-engineering the control flow
│   └── the LLM picks branches; the engine traces them — fits multi-step orchestration where free-form prose is brittle
│
├── 🌐 CROSS-PLATFORM
│   ├── write once; runs on Claude Code and GitHub Copilot unchanged
│   └── the interpreter adapts at runtime — same skill.md, zero changes
│
├── ✨ EDITOR-NATIVE
│   ├── VS Code extension: completions, hover docs, go-to-definition, live diagnostics
│   └── broken op references and signature errors surface before the skill runs
│
└── 🚀 ZERO LEARNING CURVE
    ├── /canopy scaffolds, validates, improves, and converts for you
    └── no syntax to memorize before you ship your first skill
```

---

## How it works

> The tree is the source of truth. The platform is just a detail.

Every Canopy skill is a `SKILL.md` file (uppercase, exact spelling per the agentskills.io spec) — platform-agnostic by design. When a skill runs, the `canopy` agent detects whether you're on Claude Code or GitHub Copilot, loads the matching runtime spec, then executes the tree using platform-appropriate primitives. The same skill file works on both platforms without modification.

Here's a complete skill — frontmatter, execution tree, and all:

```markdown
---
name: release
description: Bump version and update changelog.
compatibility: Requires canopy-runtime — kostiantyn-matsebora/claude-canopy
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

> Subagent dispatch via `**OP_NAME**` markers, multi-way `SWITCH/CASE`, parallel writes via `PARALLEL`, plus a plan/confirm gate and post-execution verify — this is **Canopy** in action.

---

## Quick Start

**Claude Code** — inside a session, no external CLI needed:

```
/plugin marketplace add kostiantyn-matsebora/claude-canopy
/plugin install canopy@claude-canopy
```

**GitHub Copilot** — one-shot install script:

```bash
curl -sSL https://raw.githubusercontent.com/kostiantyn-matsebora/claude-canopy/master/install.sh | bash -s -- --target copilot
```

```powershell
irm https://raw.githubusercontent.com/kostiantyn-matsebora/claude-canopy/master/install.ps1 | iex -Target copilot
```

Both install all three skills (`canopy-runtime`, `canopy`, `canopy-debug`) and self-activate the runtime on first agent load. After install, run `/canopy help` to see what's available.

For all install paths, flags, and the authoring-vs-execution split, see **[Getting Started](GETTING_STARTED.md)**.

Want a working project to copy from instead? **[claude-canopy-examples](https://github.com/kostiantyn-matsebora/claude-canopy-examples)** ships ready-to-run example skills with the framework vendored — clone it and the skills work in both Claude Code and GitHub Copilot without extra setup.

---

## Where to next

- **[Getting Started](GETTING_STARTED.md)** — full install paths, the `/canopy` operations reference, and a first-skill walkthrough.
- **[Concepts](CONCEPTS.md)** — how Canopy thinks about skills: tree, ops, subagents, execution model, the runtime/authoring split.
- **[Terminology](TERMINOLOGY.md)** — glossary of Canopy terms with one-sentence definitions and links to the relevant deep-dive.
- **[Cheatsheet](CHEATSHEET.md)** — one-page reference: skill anatomy, primitives, op syntax, category dirs.
- **[Reference](reference/)** — formal spec: framework grammar, primitives (auto-mirrored from canopy-runtime), per-platform runtime rules.
- **[VS Code Extension](VSCODE.md)** — IntelliSense, semantic diagnostics, hover docs, and go-to-definition for canopy skills.
- **[Examples](https://github.com/kostiantyn-matsebora/claude-canopy-examples)** — a working project to learn from.

---

## License

MIT — see [LICENSE](../LICENSE).
