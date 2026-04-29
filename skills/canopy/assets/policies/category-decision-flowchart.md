# Category Decision Flowchart

For every distinct block of content, apply these tests in order — use the **first matching test**:

| # | Test | → Category (standard layout) |
|---|------|------------------------------|
| 1 | Contains `- [ ]` evaluation/compliance items | `assets/checklists/` |
| 2 | Is a fillable output document with placeholder slots (`<…>`, `{{…}}`) | `assets/templates/` |
| 3 | Is a JSON/YAML structure or report shape definition | `assets/schemas/` |
| 4 | Is a shell/PowerShell script or command invocation | `scripts/` |
| 5 | Tells the agent what it **must** or **must not** do, or prescribes a sequence the agent must follow (includes "always read X", "write in this order", "do not flag X") | `assets/policies/` |
| 6 | Is a reference table or list the agent **looks values up from** but does not follow as instructions (parameter tables, metric definitions, error code maps, delta thresholds) | `assets/constants/` |
| 7 | Is supporting documentation loaded on demand (workflow guide, protocol explanation, design notes) | `references/` |
| 8 | Is a sequential step or conditional | tree node or named op in `references/ops.md` (or `references/ops/<name>.md`) |
| 9 | Is post-execution state to verify | `assets/verify/` |

A file is misplaced when the flowchart assigns it to a different category than its current location.

## Legacy flat layout

Skills authored before the agentskills.io alignment use a flat layout where category dirs live at the skill root (`schemas/`, `templates/`, `commands/`, `constants/`, `checklists/`, `policies/`, `verify/`, `ops.md`, `ops/`). Both layouts work; new skills use the standard layout above. Mapping: `commands/`→`scripts/`, `ops.md`→`references/ops.md`, all other root-level category dirs → `assets/<dir>/`.
