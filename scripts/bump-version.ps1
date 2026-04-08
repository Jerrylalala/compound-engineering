# Version bump and sync script
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
Write-Host "  Version Bump Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
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
    Write-Host "  Next Steps" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. Update CHANGELOG.md"
    Write-Host "2. Update component counts in README.md (if changed)"
    Write-Host "3. Update component counts in CLAUDE.md (if changed)"
    Write-Host "4. Commit: git add . && git commit -m 'Release v$newVersion'"
    Write-Host ""
} else {
    Write-Err "Verification failed, please check files manually"
    exit 1
}
