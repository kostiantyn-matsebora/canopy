# FETCH_DISPATCH_CONTEXT

Resolve the full dispatch context required for the canopy agent to route an incoming `$ARGUMENTS` to the correct operation procedure. Output matches `assets/schemas/dispatch-schema.json`.

* FETCH_DISPATCH_CONTEXT
  * Classify intent — apply `assets/constants/operation-detection.md` to `$ARGUMENTS` and conversation context; bind `operation`
  * Detect platforms — apply `assets/constants/platform-detection.md` to the working directory; bind `platform` (active execution platform) and `available_platforms` (all detected)
  * Resolve explicit target — apply `assets/constants/target-platform-triggers.md` to `$ARGUMENTS`; bind `explicit_target_platform` (or `null` if no trigger matches)
  * Detect repo context — check the working directory:
    * IF `skills/` directory exists at the repo root (typically with `.claude-plugin/`) → bind `repo_context = "distribution"`
    * ELSE → bind `repo_context = "consumer"`
  * Identify target skill — extract the skill name from `$ARGUMENTS` when the operation requires one; bind `target_skill` (or `null`)
  * Gather extra context — capture any operation-specific parameters from `$ARGUMENTS`; bind `extra_context`
