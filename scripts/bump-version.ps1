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
    Write-Host "2. 提交并推送 PR：git add . ; git commit -m 'chore: 升级版本至 v$newVersion'"
    Write-Host "3. PR 合并到 main 后，tag 由 GitHub Actions 自动创建，无需手动打。"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  文档核查清单（合并前必须全部完成）" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  新增 Skill/Agent/Command 时："
    Write-Host "  [ ] README.md — 工作流表、组件数量是否已更新"
    Write-Host "  [ ] docs/zh-CN/workflow.html — 工作流节点是否已更新（如链路有变）"
    Write-Host "  [ ] CHANGELOG.md — 变更内容是否已记录"
    Write-Host "  [ ] plugin.json description — 组件数量字符串是否已更新"
    Write-Host ""
    Write-Host "  修改已有命令/参数行为时："
    Write-Host "  [ ] README.md — 参数说明是否同步"
    Write-Host "  [ ] docs/zh-CN/workflow.html — 参数/示例是否同步"
    Write-Host "  [ ] CHANGELOG.md — 变更是否已记录"
    Write-Host ""
} else {
    Write-Err "Verification failed, please check files manually"
    exit 1
}
