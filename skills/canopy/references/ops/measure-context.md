# MEASURE_CONTEXT

Estimate how many lines of context a Canopy skill costs to load, broken down by source. Useful as a sanity check when authors want to keep their skill's footprint small.

This op reads no skill state besides files on disk; it makes no changes; it asks no questions. Pure inspection.

## Procedure

1. Locate the skill directory using Glob — `<skills-root>/<skill-name>/SKILL.md`.
2. Read `SKILL.md` and parse its frontmatter. Extract `metadata.canopy-features` (may be absent).
3. Resolve the `<skills-root>` and locate `canopy-runtime/SKILL.md` alongside it.
4. **Compute the canopy-runtime baseline** — lines that load on every skill invocation regardless of features:
   - Marker block — read `<skills-root>/canopy-runtime/assets/constants/marker-block.md`. The block content (between `<!-- canopy-runtime-begin -->` and `<!-- canopy-runtime-end -->` inclusive) is what's materialized into ambient instructions. Count its lines. Record as `marker-block`.
   - canopy-runtime SKILL.md — `wc -l <skills-root>/canopy-runtime/SKILL.md`. Record as `runtime-skill`.
   - skill-resources.md — `wc -l <skills-root>/canopy-runtime/references/skill-resources.md`. Record as `skill-resources`.
   - Active runtime spec — pick `runtime-claude.md` or `runtime-copilot.md` based on the host (or report both if the host is unknown). Record as `runtime-{claude,copilot}`.
   - Always-loaded primitive slice — `<skills-root>/canopy-runtime/references/ops/core.md`. Record as `slice:core`.
5. **Compute the manifest-driven slice load** — for each entry in `metadata.canopy-features`, count its slice file:
   - `interaction` → `ops/interaction.md`
   - `control-flow` → `ops/control-flow.md`
   - `parallel` → `ops/parallel.md`
   - `subagent` → `ops/subagent.md`
   - `explore` → `ops/explore.md`
   - `verify` → `ops/verify.md`
   Record each as `slice:<feature>`.

   If the manifest is absent, record every slice file under `slice:*` and note `manifest absent — load-everything fallback`.
6. **Compute the skill-local load** — files the runtime reads when interpreting this specific skill:
   - `SKILL.md` itself — record as `skill`.
   - `references/ops.md` if present — record as `ops`.
   - Every file under `references/ops/` if present — record per-file under `ops:<name>`.
   - Every `Read \`<category>/<file>\`` reference appearing in `SKILL.md` or any `references/ops*.md` file — count the referenced file's lines. Record as `read:<path>`. Note: this is a static estimate; actual loading is conditional on the tree path taken at runtime.
7. **Total** all line counts. Report as a structured breakdown:

   ```
   Skill: <name>
   Manifest: <feature list, or "absent — load-everything fallback">

   Canopy runtime baseline:
     marker-block         <N> lines
     runtime-skill        <N> lines
     skill-resources      <N> lines
     runtime-<platform>   <N> lines
     slice:core           <N> lines
   Manifest-driven slices:
     slice:interaction    <N> lines    ← if declared
     slice:control-flow   <N> lines    ← if declared
     ... (one per declared feature)
   Skill-local:
     skill                <N> lines    (SKILL.md)
     ops                  <N> lines    (references/ops.md)
     ops:<name>           <N> lines    (one per references/ops/<name>.md)
     read:<path>          <N> lines    (one per Read ref)

   TOTAL: <N> lines
   ```

8. **Highlight comparisons**:
   - If manifest is absent, also show what the load would be **if a manifest were added** — recompute slices from the tree (apply the mapping in `validate.md` step 3), and report the savings.
   - Flag any read-ref file >100 lines as a candidate for splitting.
   - Flag any `references/ops/<name>.md` file >150 lines as a candidate for splitting (large op definitions inflate every invocation).

## Notes

- **Lines, not tokens.** Different tokenizers count differently; line counts are deterministic and good enough for sanity-check purposes. A 75-line file is roughly ~600–900 tokens depending on density.
- **Static estimate.** Conditional reads (inside `IF` branches, behind `Read` refs that fire only on certain code paths) are counted as if they always load. Worst-case footprint, not average.
- **No side effects.** This op is pure inspection. It does not modify any file.

## Reference

Procedure for callers: `/canopy measure-context <skill-name>`. Output is informational; no apply block, no follow-up confirmation.
