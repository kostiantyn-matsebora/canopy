---
title: Framework (moved)
description: "This page has moved. The framework spec now lives in the Reference subfolder."
---

# Framework Spec (moved)

The framework specification has moved to the **[Reference](reference/)** subfolder:

- **[Framework Spec](reference/FRAMEWORK_SPEC.md)** — skill anatomy, frontmatter rules, tree execution model, op-lookup order, category-resource subdirectories, skills-root resolution, the Compatibility field, runtime activation, debug mode.
- **[Primitives](reference/PRIMITIVES.md)** — `IF`, `SWITCH`, `FOR_EACH`, `ASK`, `SHOW_PLAN`, `VERIFY_EXPECTED`, etc. Auto-mirrored from `skills/canopy-runtime/references/ops.md` (index) + per-feature slices under `references/ops/` so the spec on this site is exactly what the runtime executes.
- **[Runtimes](reference/RUNTIMES.md)** — per-platform execution rules (Claude Code native subagents vs GitHub Copilot inline fallback). Auto-mirrored from `skills/canopy-runtime/references/runtime-{claude,copilot}.md`.

For narrative explanations of why the spec is shaped the way it is, see [Concepts](concepts/).
