# Version consistency check script
# Usage: powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

$ErrorActionPreference = "Stop"

# Color output functions
function Write-OK { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Err { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Version Consistency Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$hasError = $false

# Define files to check
$marketplaceFile = ".claude-plugin/marketplace.json"
$pluginFile = "plugins/compound-engineering/.claude-plugin/plugin.json"

# 1. Check file existence
Write-Info "Checking file existence..."
$files = @($marketplaceFile, $pluginFile)
foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        Write-Err "File not found: $file"
        $hasError = $true
    }
}

if ($hasError) {
    Write-Host ""
    Write-Host "Check failed: Missing required files" -ForegroundColor Red
    exit 1
}

# 2. Read version numbers
Write-Info "Reading version numbers..."
try {
    $marketplace = Get-Content $marketplaceFile -Raw | ConvertFrom-Json
    $plugin = Get-Content $pluginFile -Raw | ConvertFrom-Json

    $marketplaceVersion = $marketplace.plugins[0].version
    $pluginVersion = $plugin.version

    Write-Host "  marketplace.json: $marketplaceVersion"
    Write-Host "  plugin.json:      $pluginVersion"
} catch {
    Write-Err "JSON parse failed: $_"
    exit 1
}

# 3. Compare versions
Write-Info "Comparing versions..."
if ($marketplaceVersion -eq $pluginVersion) {
    Write-OK "Versions match: $pluginVersion"
} else {
    Write-Err "Version mismatch!"
    Write-Host "  marketplace.json: $marketplaceVersion" -ForegroundColor Red
    Write-Host "  plugin.json:      $pluginVersion" -ForegroundColor Red
    $hasError = $true
}

# 4. Check identity info
Write-Host ""
Write-Info "Checking identity info..."

$expectedOwner = "Jerrylalala"

$marketplaceOwnerUrl = $marketplace.owner.url
$pluginHomepage = $plugin.homepage
$pluginRepository = $plugin.repository

if ($marketplaceOwnerUrl -notmatch $expectedOwner) {
    Write-Err "marketplace.json owner.url missing $expectedOwner"
    Write-Host "  Current: $marketplaceOwnerUrl" -ForegroundColor Yellow
    $hasError = $true
} else {
    Write-OK "marketplace.json owner.url OK"
}

if ($pluginHomepage -notmatch $expectedOwner) {
    Write-Err "plugin.json homepage missing $expectedOwner"
    Write-Host "  Current: $pluginHomepage" -ForegroundColor Yellow
    $hasError = $true
} else {
    Write-OK "plugin.json homepage OK"
}

if ($pluginRepository -notmatch $expectedOwner) {
    Write-Err "plugin.json repository missing $expectedOwner"
    Write-Host "  Current: $pluginRepository" -ForegroundColor Yellow
    $hasError = $true
} else {
    Write-OK "plugin.json repository OK"
}

# 5. Check component counts
Write-Host ""
Write-Info "Checking component counts..."

$agentCount = (Get-ChildItem -Recurse "plugins/compound-engineering/agents/*.md" -ErrorAction SilentlyContinue).Count
$commandCount = (Get-ChildItem -Recurse "plugins/compound-engineering/commands/*.md" -ErrorAction SilentlyContinue).Count
$skillCount = (Get-ChildItem -Directory "plugins/compound-engineering/skills/" -ErrorAction SilentlyContinue).Count

Write-Host "  Actual: Agents=$agentCount, Commands=$commandCount, Skills=$skillCount"

# Extract counts from plugin.json description
$pattern = '(\d+) agents?, (\d+) commands?, (\d+) skills?'
if ($plugin.description -match $pattern) {
    $descAgents = [int]$Matches[1]
    $descCommands = [int]$Matches[2]
    $descSkills = [int]$Matches[3]

    Write-Host "  Declared: Agents=$descAgents, Commands=$descCommands, Skills=$descSkills"

    if ($descAgents -ne $agentCount -or $descCommands -ne $commandCount -or $descSkills -ne $skillCount) {
        Write-Warn "Component counts mismatch with plugin.json description"
    } else {
        Write-OK "Component counts match"
    }
} else {
    Write-Warn "Cannot parse component counts from plugin.json description"
}

# 6. Output result
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($hasError) {
    Write-Host "  FAILED - Please fix issues above" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 1
} else {
    Write-Host "  ALL CHECKS PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}
