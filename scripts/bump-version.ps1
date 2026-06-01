# Legacy version bump script.
# Normal public releases are managed by release-please release PRs.
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -Version "2.30.0"
#   powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch

param(
    [string]$Version,
    [ValidateSet("major", "minor", "patch")]
    [string]$BumpType
)

$ErrorActionPreference = "Stop"

function Write-OK { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Err { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }

# File paths
$marketplaceFile = ".claude-plugin/marketplace.json"
$pluginFile = "plugins/compound-engineering/.claude-plugin/plugin.json"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Legacy Version Bump Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Normal feature PRs should not use this script; release-please owns public releases." -ForegroundColor Yellow
Write-Host ""

# Read current version
$plugin = Get-Content $pluginFile -Raw | ConvertFrom-Json
$currentVersion = $plugin.version
Write-Info "Current version: $currentVersion"

# Calculate new version
if ($Version) {
    $newVersion = $Version
} elseif ($BumpType) {
    $parts = $currentVersion -split '\.'
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]

    switch ($BumpType) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
    }
    $newVersion = "$major.$minor.$patch"
} else {
    Write-Err "Please specify -Version or -BumpType parameter"
    Write-Host "Usage:"
    Write-Host "  -Version '2.30.0'     Specify version directly"
    Write-Host "  -BumpType patch       Auto increment patch"
    Write-Host "  -BumpType minor       Auto increment minor"
    Write-Host "  -BumpType major       Auto increment major"
    exit 1
}

Write-Info "New version: $newVersion"

# Validate semver format
if ($newVersion -notmatch '^\d+\.\d+\.\d+$') {
    Write-Err "Invalid semver format: '$newVersion'. Expected X.Y.Z (e.g. 2.45.7)"
    exit 1
}

# Confirm
$confirm = Read-Host "Confirm update $currentVersion -> $newVersion ? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Cancelled" -ForegroundColor Yellow
    exit 0
}

# Update plugin.json
Write-Info "Updating $pluginFile..."
$plugin.version = $newVersion
$pluginJson = $plugin | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText((Resolve-Path $pluginFile), $pluginJson)
Write-OK "plugin.json updated"

# Note: marketplace.json does not store per-plugin version (only metadata.version which is the schema version)
# Version source of truth is plugin.json only

# Verify
Write-Host ""
Write-Info "Verifying..."
$verifyPlugin = (Get-Content $pluginFile -Raw | ConvertFrom-Json).version

if ($verifyPlugin -eq $newVersion) {
    Write-OK "Version synced to: $newVersion"

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Legacy-only flow" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. Explain in the PR why a manual version edit was required."
    Write-Host "2. Run: bun run release:sync-metadata"
    Write-Host "3. Run: bun run release:validate"
    Write-Host "4. Do not hand-author release notes unless you are fixing release automation itself."
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Documentation checklist before merge" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  When adding Skill/Agent/Command:"
    Write-Host "  [ ] README.md workflow table and component counts are updated"
    Write-Host "  [ ] docs/zh-CN/workflow.html workflow nodes are updated when links change"
    Write-Host "  [ ] release metadata validation passes"
    Write-Host "  [ ] release-please will generate release notes"
    Write-Host ""
    Write-Host "  When changing command or parameter behavior:"
    Write-Host "  [ ] README.md parameter docs are updated"
    Write-Host "  [ ] docs/zh-CN/workflow.html parameters/examples are updated"
    Write-Host "  [ ] release-please will generate release notes"
    Write-Host ""
} else {
    Write-Err "Verification failed, please check files manually"
    exit 1
}
