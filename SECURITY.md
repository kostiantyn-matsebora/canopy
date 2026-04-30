# Security Policy

## Reporting a Vulnerability

If you discover a security issue in Canopy, please **do not open a public issue**. Instead:

- Use GitHub's private vulnerability reporting: https://github.com/kostiantyn-matsebora/claude-canopy/security/advisories/new
- Or email: **kmatsebora@gmail.com** with `[canopy-security]` in the subject line

Please include:

- A clear description of the issue and its impact
- Reproduction steps or a proof-of-concept
- The affected version(s) (`.canopy-version` or git ref)
- Whether you've disclosed the issue elsewhere

You can expect:

- An acknowledgement within **3 business days**
- A first assessment within **7 business days**
- A coordinated disclosure timeline once the impact is clear

## Supported Versions

Only the latest minor version on `master` is actively supported. Older minor versions receive security fixes only when the upgrade path is non-trivial.

| Version | Supported |
|---------|-----------|
| 0.18.x  | ✅ |
| < 0.18  | ❌ |

## Release Integrity

Each tagged release at `https://github.com/kostiantyn-matsebora/claude-canopy/releases` is the authoritative install artifact for `gh skill install` and `/plugin install`.

- **Tags are GPG/SSH-signed** by the maintainer. Verify with `git tag -v vX.Y.Z`.
- **Releases publish SLSA build provenance** via [GitHub Attestations](https://docs.github.com/en/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds). Verify with `gh attestation verify <artifact> --owner kostiantyn-matsebora`.
- **CI** runs `scripts/validate.sh` on every push to `master` to enforce the agentskills.io spec invariants (frontmatter shape, `compatibility` field presence, safety preamble, version sync across `.canopy-version` / `plugin.json` / `marketplace.json`).

## What Canopy Skills Execute

Canopy skills are interpreted by `canopy-runtime` inside an agent host (Claude Code or GitHub Copilot). Trees describe orchestration only; concrete actions run through the host's tool surface (file edits, shell commands, etc.) under whatever permission model the host enforces. **Canopy itself does not bypass or relax the host's permission prompts.**

Skill-shipped scripts (`scripts/*.sh`, `scripts/*.ps1`) execute directly when the skill invokes them. Treat them like any other dependency: review before installing skills you don't trust.

## Scope

In-scope for security reports:

- Bypass of `compatibility` / `safety preamble` enforcement that lets a non-canopy-runtime host execute a `## Tree` skill silently
- Path-traversal or injection in install scripts (`install.sh`, `install.ps1`)
- Marker-block writers producing content that escapes the marker bounds
- Validator (`scripts/validate.sh`) producing false negatives on malformed frontmatter
- Privilege issues in the GitHub Actions workflows (`.github/workflows/*.yml`)

Out of scope:

- Misuse of the `canopy` authoring agent to produce arbitrary skill content (this is the agent's purpose)
- Vulnerabilities in third-party agent hosts (Claude Code, Copilot) — report those upstream

## Public Disclosure

After a fix lands, the vulnerability is recorded in `docs/CHANGELOG.md` under the patching version's `### Security` block, with a CVE if assigned and credit to the reporter (unless they prefer anonymity).
