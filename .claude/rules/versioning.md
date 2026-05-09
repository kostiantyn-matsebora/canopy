---
paths:
  - ".canopy-version"
  - ".claude-plugin/plugin.json"
  - ".claude-plugin/marketplace.json"
  - "docs/CHANGELOG.md"
  - ".github/workflows/release.yml"
---

# Rule: Versioning & release

The version string lives in **four places** that must stay in sync:

1. `.canopy-version`
2. `.claude-plugin/plugin.json` → `version`
3. `.claude-plugin/marketplace.json` → `metadata.version` AND `plugins[0].version`
4. The git tag `vX.Y.Z`

## How to bump

Use the `/bump-version X.Y.Z` skill (at `.claude/skills/bump-version/`) to update all four + draft a `docs/CHANGELOG.md` entry + create the local tag in one step. The skill never pushes; pushing is deliberate and manual:

```bash
git push origin master vX.Y.Z
```

## What the tag triggers

Pushing a `v*` tag fires `.github/workflows/release.yml`, which:

- Extracts the matching `## [X.Y.Z] — …` block from `docs/CHANGELOG.md`
- Creates a GitHub Release with those notes
- Attaches SLSA build provenance (Sigstore-signed via `actions/attest-build-provenance@v2`) over the install tarball, each `SKILL.md`, and both plugin manifests

The git tag is also the install artifact for:
- `gh skill install --pin vX.Y.Z`
- `/plugin install canopy@claude-canopy` (which picks up `plugin.json`'s `version`)

## Bump tier guidance

- **Major (X.0.0)** — breaking changes (removed primitives, removed sections, removed/renamed compatibility fields)
- **Minor (0.X.0)** — new feature (new primitive, new section, new dispatch mode, new convention). Default for "feat" PRs.
- **Patch (0.0.X)** — bug fixes, doc edits, internal refactors with no surface change

## CHANGELOG format

Each release block in `docs/CHANGELOG.md`:

```markdown
## [X.Y.Z] — YYYY-MM-DD

### Added
- ...

### Changed
- ...

### Fixed
- ...

### Notes
- ...
```

Only include non-empty groups. Keep entries scannable — bullets with bold lead labels.

## Tag verification

Tags are SSH-signed. Verify with:

```bash
git verify-tag vX.Y.Z
```

The local clone has `tag.gpgsign true`; the public key is registered as a Signing Key on GitHub. SLSA provenance verification:

```bash
gh attestation verify canopy-X.Y.Z.tar.gz --owner kostiantyn-matsebora
```
