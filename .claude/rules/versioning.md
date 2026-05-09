---
paths:
  - ".canopy-version"
  - ".claude-plugin/plugin.json"
  - ".claude-plugin/marketplace.json"
  - "docs/CHANGELOG.md"
  - ".github/workflows/release.yml"
  - "skills/canopy/SKILL.md"
  - "skills/canopy-runtime/SKILL.md"
  - "skills/canopy-debug/SKILL.md"
---

# Rule: Versioning & release

The version string lives in **seven places** that must stay in sync:

1. `.canopy-version`
2. `.claude-plugin/plugin.json` → `version`
3. `.claude-plugin/marketplace.json` → `metadata.version` AND `plugins[0].version`
4. `skills/canopy/SKILL.md` → frontmatter `metadata.version`
5. `skills/canopy-runtime/SKILL.md` → frontmatter `metadata.version`
6. `skills/canopy-debug/SKILL.md` → frontmatter `metadata.version`
7. The git tag `vX.Y.Z`

The three per-skill `metadata.version` fields are easy to forget because:

- They're inside YAML frontmatter rather than top-level files.
- `gh skill install --pin vX.Y.Z` only pins the *git ref* it pulls from; it does **not** rewrite the `metadata.version` text inside the file.
- Drift here is silent — there's no CI gate (yet), so consumers run `gh skill install` and see a stale version embedded in the file even though the tag itself is current.

A pre-tag sanity check, run it before pushing:

```bash
grep -nE 'version:\s*"' skills/*/SKILL.md
cat .canopy-version
node -e "console.log(require('./.claude-plugin/plugin.json').version)"
```

All seven values must agree.

## How to bump

There is no `/bump-version` skill in this repo (it was removed; manual procedure is small enough). To bump:

1. **Edit all six in-repo files** to the new `X.Y.Z`:
   - `.canopy-version` (one-line file)
   - `.claude-plugin/plugin.json` → `version`
   - `.claude-plugin/marketplace.json` → `metadata.version` AND `plugins[0].version`
   - `skills/canopy/SKILL.md` → frontmatter `metadata.version`
   - `skills/canopy-runtime/SKILL.md` → frontmatter `metadata.version`
   - `skills/canopy-debug/SKILL.md` → frontmatter `metadata.version`
2. **Add a `docs/CHANGELOG.md` entry** under `## [X.Y.Z] — YYYY-MM-DD` (format below). Required — `release.yml` extracts this block as the GitHub Release notes.
3. **Verify all seven** by running the grep + cat + node check above; values must agree.
4. **Commit + push to master.**
5. **Tag from master** (signed):

```bash
git tag -s vX.Y.Z -m "vX.Y.Z — <one-line summary>"
git push origin vX.Y.Z
```

Pushing the tag fires `.github/workflows/release.yml`. The tag and the master push are deliberate, separate steps.

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
