---
title: VS Code Extension
nav_order: 6
description: "Canopy Skills for VS Code — IntelliSense, semantic diagnostics, hover docs, and go-to-definition for canopy-flavored skills."
permalink: /vscode/
---

# VS Code Extension

[**Canopy Skills**](https://marketplace.visualstudio.com/items?itemName=canopy-ai.canopy-skills) is the official VS Code extension for authoring Canopy skills. It turns `SKILL.md` and `ops.md` files into a first-class editor experience — autocomplete for primitives and custom ops, real-time semantic diagnostics, hover docs on every `ALL_CAPS` identifier, and `F12` go-to-definition across the skill → project → framework op-lookup chain.

Source repo: [github.com/kostiantyn-matsebora/claude-canopy-vscode](https://github.com/kostiantyn-matsebora/claude-canopy-vscode).

---

## Install

**From the VS Code Marketplace** (recommended):

```bash
code --install-extension canopy-ai.canopy-skills
```

Or open the **Extensions** panel in VS Code, search **"Canopy Skills"**, and click Install.

For offline installs, every release ships a `.vsix` on the [Releases page](https://github.com/kostiantyn-matsebora/claude-canopy-vscode/releases/latest):

```bash
code --install-extension canopy-skills-<version>.vsix
```

**Requirements:** VS Code 1.85+. Some commands additionally require `git`, `gh skill` (≥2.90.0), or `claude` on `PATH` — the extension shows availability badges in its install picker.

---

## Features

**Syntax highlighting** for five language IDs covering every Canopy file type — `SKILL.md`, `ops.md`, verify checklists, templates, constants, policies, schemas, and command scripts. Both the agentskills.io standard layout (`assets/`, `scripts/`, `references/`) and the legacy flat layout are recognised.

**IntelliSense** in `SKILL.md` and `ops.md`:

| Completion | What it suggests |
|---|---|
| Op names | Skill-local ops, project-level ops, and framework primitives — with the right tree-node prefix (`* ` or `├── `) auto-inserted |
| Primitives | All framework built-ins (`IF`, `SWITCH`, `FOR_EACH`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`, …) with descriptions |
| Frontmatter | `name`, `description`, `compatibility`, `license`, `metadata`, `allowed-tools` (agentskills.io spec); `argument-hint` and `user-invocable` inside `metadata` |
| Category resources | ``Read `category/path` `` directives for `constants/`, `policies/`, `templates/`, `schemas/`, `checklists/`, `verify/`, `references/` |

**Hover documentation** on every framework primitive and custom op — signature, description, and a usage example. No context-switch to the framework docs.

**Go-to-definition** (`F12`) on any `ALL_CAPS` identifier. Resolves through the standard op-lookup chain: current skill's `ops.md` → consumer-defined cross-skill ops → framework primitives.

**Semantic diagnostics** with Quick Fixes. Real-time squiggles for:

| Check | Catches |
|---|---|
| Frontmatter | Missing `name`/`description`, unknown root keys, `argument-hint`/`user-invocable` at root (must live in `metadata`) |
| `compatibility` field | Block-form / inline-flow maps (must be free-text per spec); >500 chars; missing canopy-runtime mention on `## Tree` skills |
| Tree syntax | `>>` before `<<`, empty operator slots |
| Primitive signatures | `IF`/`ELSE_IF` without `<<`; `ASK` without options; `SHOW_PLAN` without `>>`; `VERIFY_EXPECTED` wrong path prefix; `EXPLORE` without `>>` |
| Resource references | `Read` paths use a recognised category and the file exists on disk |
| Unknown ops | Configurable severity for `ALL_CAPS` names not found in any registry |
| Op conformance hints | Tree node's `<<`/`>>` doesn't match the op's declared signature |

---

## Commands

All commands are in the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`), grouped into three categories that sort alphabetically into a natural workflow order:

### `Canopy Install` — install Canopy into your project

| Command | What it does |
|---|---|
| **Install...** | Unified entry point — Quick Pick of three install methods with availability badges based on which CLIs are on PATH |
| **Install (via install script)** | Clones canopy and runs `install.sh`/`install.ps1` (Claude / Copilot / Both / Cross-client `.agents/skills/`); writes the canopy-runtime marker block proactively |
| **Install as Agent Skill (gh skill)** | `gh skill install` per skill (Claude Code / Copilot / Cross-client) |
| **Install as Claude Code Plugin** | Copies the `/plugin` slash commands to clipboard for paste in a Claude Code session |

### `Canopy Skill` — describe it, let AI write it

Auto-detects the installed AI target (Claude Code or Copilot) and invokes `claude` or `gh copilot suggest`. Start here when you don't want to learn the framework yet — describe what you want and the agent does the rest.

| Command | What it does |
|---|---|
| **Create Skill** | Describe a skill; the agent writes it end-to-end |
| **Modify Skill** | Pick a skill, describe the change |
| **Scaffold Skill** | Provide a name; the agent creates the blank structure |
| **Convert to Canopy** | Converts a plain-markdown skill to Canopy tree format |
| **Validate Skill** | Checks a skill against all framework rules |
| **Improve Skill** | Aligns a skill with the latest framework conventions |
| **Advise** | Ask the agent a design question about Canopy |
| **Refactor Skills** | Extracts shared ops and resources across multiple skills |
| **Convert to Regular Skill** | Converts a Canopy skill back to plain markdown |
| **Help** | Lists all available agent operations |

### `Canopy Template` — manual scaffolding

For authors who know the framework and prefer to hand-write skills. Each command drops a correctly-structured blank file at the right path; you fill in the content.

| Command | Description |
|---|---|
| **New Skill** | Creates `SKILL.md` + `ops.md` for a new skill |
| **New Verify File** | Scaffolds a `verify/` checklist |
| **New Template** | Scaffolds a `templates/` file (`.md`, `.yaml`, `.yaml.gotmpl`) |
| **New Constants File** | Scaffolds a `constants/` lookup file |
| **New Policy File** | Scaffolds a `policies/` rule file |
| **New Script File** | Scaffolds a `scripts/` script (`.ps1` or `.sh`) |
| **New Schema** | Scaffolds a `schemas/` file |

---

## Settings

| Setting | Default | Description |
|---|---|---|
| `canopy.frameworkUrl` | `https://github.com/kostiantyn-matsebora/claude-canopy` | Framework repo URL used by install commands |
| `canopy.validate.enabled` | `true` | Enable/disable all real-time validation |
| `canopy.validate.unknownOps` | `"warning"` | Severity for unresolved op names: `error`, `warning`, `hint`, `none` |
| `canopy.validate.opConformance` | `true` | Show hints when `<<`/`>>` usage doesn't match the op's declared signature |

---

## Versioning

The extension tracks the framework version it supports — see the **Tracks Canopy** badge in the [extension's README](https://github.com/kostiantyn-matsebora/claude-canopy-vscode#readme). When the framework adds a new primitive, category directory, or signature change, the extension publishes a matching release that recognises it.

---

## Where to learn more

- [Extension repo + full README](https://github.com/kostiantyn-matsebora/claude-canopy-vscode) — feature deep dives, screenshots, dev setup
- [Marketplace listing](https://marketplace.visualstudio.com/items?itemName=canopy-ai.canopy-skills) — install + reviews
- [Extension changelog](https://github.com/kostiantyn-matsebora/claude-canopy-vscode/blob/master/CHANGELOG.md) — per-release notes
- [Issue tracker](https://github.com/kostiantyn-matsebora/claude-canopy-vscode/issues) — bug reports and feature requests
