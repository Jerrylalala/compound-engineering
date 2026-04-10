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
    Write-Host "  发版流程" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. 更新 CHANGELOG.md（添加 v$newVersion 的变更内容）"
    Write-Host "2. 更新 README.md 组件数量（如有变更）"
    Write-Host "3. 提交并推送 PR：git add . && git commit -m 'chore: 升级版本至 v$newVersion'"
    Write-Host "4. PR 合并到 main 后，打 tag 触发自动 Release："
    Write-Host ""
    Write-Host "     git tag v$newVersion && git push origin v$newVersion" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   GitHub Actions 将自动从 CHANGELOG.md 提取内容并创建 Release。" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Err "Verification failed, please check files manually"
    exit 1
}
