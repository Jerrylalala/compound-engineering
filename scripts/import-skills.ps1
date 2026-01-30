[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$inbox = Join-Path $repoRoot 'plugins\compound-engineering\skills-inbox'
$custom = Join-Path $repoRoot 'plugins\compound-engineering\skills-custom'

if (-not (Test-Path $inbox)) {
  throw "skills-inbox not found: $inbox"
}
if (-not (Test-Path $custom)) {
  New-Item -ItemType Directory -Path $custom | Out-Null
}

$success = 0
$failed = 0
$skipped = 0

$dirs = Get-ChildItem -Path $inbox -Directory -ErrorAction SilentlyContinue
if (-not $dirs) {
  Write-Host "No skill directories found in skills-inbox."
}

foreach ($dir in $dirs) {
  $skillName = $dir.Name
  $src = $dir.FullName
  $dest = Join-Path $custom $skillName

  if (Test-Path $dest) {
    $skipped++
    Write-Host "SKIP: $skillName (destination exists)"
    continue
  }

  try {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    $items = Get-ChildItem -Path $src -Force -ErrorAction SilentlyContinue
    if ($items) {
      Copy-Item -Path $items.FullName -Destination $dest -Recurse -Force
    }

    $srcSkill = Join-Path $src 'SKILL.md'
    $destSkill = Join-Path $dest 'SKILL.md'

    if (Test-Path $srcSkill) {
      $success++
      Write-Host "OK: $skillName"
    } else {
      @'
# <skill-name>

## Purpose
- 1-2 sentences describing what this skill does.

## Usage
- Trigger:
- Inputs:
- Outputs:

## Constraints / Notes
- Safety, permissions, prerequisites, etc.

## Structure (optional)
```
<skill-dir>/
  SKILL.md
  assets/
  references/
  scripts/
```

## Examples
```
# Example invocation
```
'@ | Set-Content -Path $destSkill -Encoding UTF8

      $failed++
      Write-Warning "MISSING SKILL.md: $skillName -> template created (please fill in)"
    }
  } catch {
    $failed++
    Write-Warning "FAIL: $skillName -> $($_.Exception.Message)"
  }
}

Write-Host "Import summary: success=$success failed=$failed skipped=$skipped"
