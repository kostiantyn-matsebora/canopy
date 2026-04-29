#!/usr/bin/env pwsh
<#
install.ps1 — Install or update Canopy skills in the current project.

Usage:
  # One-liner install/update (resolves version from .canopy-version, else latest):
  irm https://raw.githubusercontent.com/kostiantyn-matsebora/claude-canopy/master/install.ps1 | iex

  # Pin to a specific version:
  irm .../install.ps1 -OutFile install.ps1
  pwsh ./install.ps1 -Version 0.18.0

  # Install from a branch, tag, or commit SHA (pre-release testing):
  pwsh ./install.ps1 -Ref canopy-as-agent-skill

  # Install for GitHub Copilot instead of Claude Code:
  pwsh ./install.ps1 -Target copilot

  # Install for BOTH platforms in one pass (.claude/skills/ and .github/skills/):
  pwsh ./install.ps1 -Target both

  # Install to the cross-agent location (.agents/skills/):
  pwsh ./install.ps1 -Target agents

  # Local invocation:
  pwsh ./install.ps1 [-Version X.Y.Z | -Ref GIT_REF] [-Target claude|copilot|both|agents]

Canopy ships as THREE skills, all installed by this script:
  canopy         — authoring agent (create / modify / validate / improve / scaffold)
  canopy-debug   — trace wrapper (/canopy-debug <skill> emits phase banners + node traces)
  canopy-runtime — execution engine (platform detection, primitives spec, op lookup, category semantics).
                   Hidden from /; loaded ambiently via CLAUDE.md / .github/copilot-instructions.md.
                   Install this alone if you only want to EXECUTE canopy skills (not author them).

Version resolution order:
  1. -Ref parameter (git branch/tag/SHA; skips version resolution; does NOT write .canopy-version)
  2. -Version parameter (v<version> tag)
  3. .canopy-version file in the current directory (v<contents> tag)
  4. Latest release tag from GitHub API

Ambient runtime activation:
  On -Target claude|both, the script idempotently writes a marker-delimited
  canopy-runtime block to ./CLAUDE.md.
  On -Target copilot|both, same for ./.github/copilot-instructions.md.
  Re-running replaces the block in place; user content above/below is preserved.

Re-run to update: bump .canopy-version (or pass -Version / -Ref) then re-invoke.
The script is idempotent end-to-end.
#>

[CmdletBinding()]
param(
    [string]$Version = "",
    [string]$Ref = "",
    [ValidateSet("claude", "copilot", "both", "agents")]
    [string]$Target = "claude"
)

$ErrorActionPreference = "Stop"

$RepoUrl   = "https://github.com/kostiantyn-matsebora/claude-canopy"
$RepoOwner = "kostiantyn-matsebora"
$RepoName  = "claude-canopy"
$Skills    = @("canopy", "canopy-debug", "canopy-runtime")

$MarkerStart = "<!-- canopy-runtime-begin -->"
$MarkerEnd   = "<!-- canopy-runtime-end -->"

if (-not [string]::IsNullOrWhiteSpace($Version) -and -not [string]::IsNullOrWhiteSpace($Ref)) {
    Write-Error "install.ps1: -Version and -Ref are mutually exclusive"
    exit 2
}

# Resolve target(s) — Canopy is platform-agnostic, so both are supported.
# `agents` writes to .agents/skills/, the cross-agent install location used by
# gh skill install on Copilot and other hosts (gh 2.91+). canopy-runtime
# self-identifies the active platform at runtime, so a single .agents/ install
# serves both Claude Code and Copilot. The marker block goes to whichever
# instructions file already exists; if neither exists, CLAUDE.md is created.
switch ($Target) {
    "claude"  { $Targets = @(".claude/skills");                       $AmbientFiles = @("CLAUDE.md") }
    "copilot" { $Targets = @(".github/skills");                       $AmbientFiles = @(".github/copilot-instructions.md") }
    "both"    { $Targets = @(".claude/skills", ".github/skills");     $AmbientFiles = @("CLAUDE.md", ".github/copilot-instructions.md") }
    "agents"  {
        $Targets = @(".agents/skills")
        $AmbientFiles = @()
        if (Test-Path "CLAUDE.md") { $AmbientFiles += "CLAUDE.md" }
        if (Test-Path ".github/copilot-instructions.md") { $AmbientFiles += ".github/copilot-instructions.md" }
        if ($AmbientFiles.Count -eq 0) { $AmbientFiles = @("CLAUDE.md") }
    }
}

# Resolve version / ref
if (-not [string]::IsNullOrWhiteSpace($Ref)) {
    $GitRef = $Ref
    Write-Host "install.ps1: using explicit ref: $GitRef"
} else {
    if ([string]::IsNullOrWhiteSpace($Version)) {
        if (Test-Path ".canopy-version") {
            $Version = (Get-Content ".canopy-version" -Raw).Trim()
            Write-Host "install.ps1: resolved version from .canopy-version: $Version"
        } else {
            Write-Host "install.ps1: fetching latest release tag from GitHub..."
            try {
                $latest = Invoke-RestMethod "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
            } catch {
                Write-Error "install.ps1: could not resolve latest release tag from GitHub: $_"
                exit 1
            }
            $Version = $latest.tag_name -replace '^v', ''
            Write-Host "install.ps1: resolved latest version: $Version"
        }
    }
    $Version = $Version -replace '^v', ''
    if ($Version -notmatch '^\d+\.\d+\.\d+') {
        Write-Error "install.ps1: version '$Version' does not look like semver (MAJOR.MINOR.PATCH)"
        exit 2
    }
    $GitRef = "v$Version"
}

# Download to temp dir
$TmpDir = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) "canopy-install-$([guid]::NewGuid())")

try {
    Write-Host "install.ps1: downloading canopy from $RepoUrl at ref '$GitRef'..."
    $cloneTarget = Join-Path $TmpDir "canopy"
    git clone --depth 1 --branch $GitRef $RepoUrl $cloneTarget 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "install.ps1: failed to clone canopy at ref '$GitRef' from $RepoUrl. Does the ref exist? Check $RepoUrl/branches and $RepoUrl/tags"
        exit 1
    }

    foreach ($skill in $Skills) {
        $skillMd = Join-Path $cloneTarget "skills" $skill "SKILL.md"
        if (-not (Test-Path $skillMd)) {
            Write-Error "install.ps1: ref '$GitRef' does not contain skills/$skill/SKILL.md"
            exit 1
        }
    }

    # Install (idempotent: overwrites existing skill dirs)
    foreach ($skillsBase in $Targets) {
        New-Item -ItemType Directory -Path $skillsBase -Force | Out-Null
        foreach ($skill in $Skills) {
            $dest = Join-Path $skillsBase $skill
            Write-Host "install.ps1: installing $dest"
            if (Test-Path $dest) {
                Remove-Item -Recurse -Force $dest
            }
            Copy-Item -Recurse (Join-Path $cloneTarget "skills" $skill) $dest
        }
    }

    # Record installed version (only for version-pinned installs, NOT for -Ref)
    if ([string]::IsNullOrWhiteSpace($Ref)) {
        Set-Content -Path ".canopy-version" -Value $Version -NoNewline
        Add-Content -Path ".canopy-version" -Value ([System.Environment]::NewLine) -NoNewline
    }

    # --- Idempotent ambient-file write: CLAUDE.md and/or copilot-instructions.md ---

    function Build-MarkerBlock {
        return @"
<!-- canopy-runtime-begin -->
## Canopy Runtime

**Trigger:** any ``SKILL.md`` declaring a ``## Tree`` section is a canopy-flavored skill. Before interpreting it, load ``<skills-root>/canopy-runtime/SKILL.md`` and apply its execution model.

- **``<skills-root>`` resolution** — first match wins:
  - ``.agents/skills/`` — cross-agent install (gh skill install default on Copilot and other hosts)
  - ``.claude/skills/`` — Claude Code
  - ``.github/skills/`` — GitHub Copilot
- **Platform detection** — at runtime, the agent self-identifies the active host:
  - Claude Code → apply ``<skills-root>/canopy-runtime/references/runtime-claude.md``
  - GitHub Copilot → apply ``<skills-root>/canopy-runtime/references/runtime-copilot.md``
  - Other hosts → halt with unsupported-platform error
- **Sections** — ``## Agent``, ``## Tree``, ``## Rules``, ``## Response:``
- **Tree notation** — ``<<`` input, ``>>`` output, ``|`` separator
- **Primitives** (defined in canopy-runtime's ``references/framework-ops.md``):
  - control flow — ``IF``, ``ELSE_IF``, ``ELSE``, ``SWITCH``, ``CASE``, ``DEFAULT``, ``FOR_EACH``, ``BREAK``, ``END``
  - interaction — ``ASK``, ``SHOW_PLAN``
  - execution — ``EXPLORE``, ``VERIFY_EXPECTED``
- **Op lookup chain** — first match wins:
  - skill-local: ``<skill>/references/ops.md`` or ``<skill>/references/ops/<name>.md`` (legacy ``<skill>/ops.md`` at root also supported)
  - consumer-defined cross-skill ops, if any
  - framework primitives in canopy-runtime's ``references/framework-ops.md``
- **Category layout** (under each skill):
  - ``scripts/`` — executable code
  - ``references/`` — docs loaded on demand (including ops)
  - ``assets/{templates,constants,schemas,checklists,policies,verify}/`` — static resources
  - Legacy flat layout (these dirs at skill root) remains supported.
- **Subagent contract** — ``EXPLORE`` is the first tree node when ``## Agent`` declares ``**explore**``.
<!-- canopy-runtime-end -->
"@
    }

    function Write-MarkerBlock {
        param([string]$TargetFile)

        $block = Build-MarkerBlock

        # Resolve TargetFile against PowerShell's current location, not .NET's
        # static CurrentDirectory (which doesn't track Set-Location). Without
        # this, [System.IO.File]::WriteAllText with a relative path writes to
        # the wrong directory.
        if (-not [System.IO.Path]::IsPathRooted($TargetFile)) {
            $TargetFile = Join-Path (Get-Location).Path $TargetFile
        }

        # Case 1: file doesn't exist → create with platform-native line endings
        if (-not (Test-Path $TargetFile)) {
            $dir = Split-Path -Parent $TargetFile
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            $nl = [System.Environment]::NewLine
            $blockNewFile = $block -replace "`r?`n", $nl
            [System.IO.File]::WriteAllText($TargetFile, $blockNewFile + $nl)
            Write-Host "install.ps1: created $TargetFile with canopy-runtime block"
            return
        }

        $content = [System.IO.File]::ReadAllText($TargetFile)
        # Detect line-ending style: if file has any CRLF, preserve CRLF; else LF.
        $useCrlf = $content.Contains("`r`n")
        $nl = if ($useCrlf) { "`r`n" } else { "`n" }

        $beginCount = ([regex]::Matches($content, [regex]::Escape($MarkerStart))).Count
        $endCount   = ([regex]::Matches($content, [regex]::Escape($MarkerEnd))).Count

        # Case 5: malformed → refuse
        if ($beginCount -ne $endCount) {
            Write-Error "install.ps1: malformed canopy-runtime block in $TargetFile (begin=$beginCount, end=$endCount). Fix manually before re-running."
            return
        }

        # Normalize block to file's line-ending style (so splice doesn't introduce mixed endings)
        $blockNormalized = $block -replace "`r?`n", $nl

        if ($beginCount -eq 0) {
            # Case 2: no existing block → append with separating blank line
            if ($content.Length -gt 0 -and -not $content.EndsWith($nl)) {
                $content += $nl
            }
            $content += $nl + $blockNormalized + $nl
            [System.IO.File]::WriteAllText($TargetFile, $content)
            Write-Host "install.ps1: appended canopy-runtime block to $TargetFile"
            return
        }

        # Case 3 & 4: one or more existing pairs → replace first, warn if >1.
        # Direct string splice (no regex) — avoids .NET regex replacement-string
        # pitfalls with $ literals inside the block body.
        if ($beginCount -gt 1) {
            # Write to stderr (not Warning stream) so shell-style `2> file` captures it.
            [Console]::Error.WriteLine("install.ps1: warning — $TargetFile has $beginCount canopy-runtime marker pairs; rewriting only the first.")
        }
        $startIdx = $content.IndexOf($MarkerStart)
        $endAt    = $content.IndexOf($MarkerEnd, $startIdx)
        if ($startIdx -lt 0 -or $endAt -lt 0) {
            Write-Error "install.ps1: internal error locating markers in $TargetFile"
            return
        }
        $endIdx = $endAt + $MarkerEnd.Length
        $newContent = $content.Substring(0, $startIdx) + $blockNormalized + $content.Substring($endIdx)

        [System.IO.File]::WriteAllText($TargetFile, $newContent)
        Write-Host "install.ps1: updated canopy-runtime block in $TargetFile"
    }

    foreach ($ambient in $AmbientFiles) {
        Write-MarkerBlock -TargetFile $ambient
    }

    Write-Host ""
    Write-Host "install.ps1: installed canopy (ref '$GitRef') to: $($Targets -join ', ')"
    if ([string]::IsNullOrWhiteSpace($Ref)) {
        Write-Host "install.ps1: wrote .canopy-version = $Version"
    } else {
        Write-Host "install.ps1: .canopy-version NOT written (-Ref install is transient)"
    }
    Write-Host ""
    Write-Host "Slash commands now available:"
    Write-Host "  /canopy            (authoring agent)"
    Write-Host "  /canopy-debug      (trace wrapper)"
    Write-Host "  (canopy-runtime is hidden — loaded ambiently via $($AmbientFiles -join ', '))"
} finally {
    if (Test-Path $TmpDir) {
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
    }
}
