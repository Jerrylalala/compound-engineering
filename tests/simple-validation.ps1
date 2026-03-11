# Simple Validation Script (No Pester Required)
# Purpose: Quick validation without external dependencies
# Usage: powershell -ExecutionPolicy Bypass -File tests/simple-validation.ps1

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Simple Validation (No Pester)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$passed = 0
$failed = 0
$warnings = 0

function Test-Check {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$FailMessage = "Check failed"
    )

    Write-Host "Checking: $Name..." -NoNewline

    try {
        $result = & $Test

        if ($result) {
            Write-Host " [OK]" -ForegroundColor Green
            $script:passed++
        } else {
            Write-Host " [FAIL]" -ForegroundColor Red
            Write-Host "  $FailMessage" -ForegroundColor Yellow
            $script:failed++
        }
    } catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Yellow
        $script:failed++
    }
}

# 1. Version Consistency
Write-Host "`n[1] Version Consistency" -ForegroundColor Cyan

Test-Check "marketplace.json exists" {
    Test-Path ".claude-plugin/marketplace.json"
} "File not found"

Test-Check "plugin.json exists" {
    Test-Path "plugins/compound-engineering/.claude-plugin/plugin.json"
} "File not found"

Test-Check "Versions match" {
    $marketplace = Get-Content .claude-plugin/marketplace.json | ConvertFrom-Json
    $plugin = Get-Content plugins/compound-engineering/.claude-plugin/plugin.json | ConvertFrom-Json

    $marketplace.plugins[0].version -eq $plugin.version
} "Version mismatch detected"

# 2. Component References
Write-Host "`n[2] Component References" -ForegroundColor Cyan

Test-Check "No phantom agent references" {
    $workflowFiles = Get-ChildItem plugins/compound-engineering/commands/workflows/*.md
    $agentFiles = Get-ChildItem plugins/compound-engineering/agents/**/*.md

    $referencedAgents = $workflowFiles | Select-String 'Task ([a-z-]+)\(' -AllMatches |
        ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique

    $existingAgents = $agentFiles | ForEach-Object { $_.BaseName } | Sort-Object -Unique

    $phantoms = $referencedAgents | Where-Object { $_ -notin $existingAgents }

    $phantoms.Count -eq 0
} "Found phantom agent references"

Test-Check "All skills have SKILL.md" {
    $skillDirs = Get-ChildItem -Directory plugins/compound-engineering/skills/

    $missing = $skillDirs | Where-Object {
        -not (Test-Path (Join-Path $_.FullName "SKILL.md"))
    }

    $missing.Count -eq 0
} "Some skills missing SKILL.md"

# 3. Cross-Platform Compatibility
Write-Host "`n[3] Cross-Platform Compatibility" -ForegroundColor Cyan

Test-Check "No Unicode circle numbers in commands" {
    $commandFiles = Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md

    $violations = $commandFiles | Select-String '[\u2460-\u2473]'

    $violations.Count -eq 0
} "Found Unicode circle numbers"

Test-Check "No emoji in CLI content" {
    $commandFiles = Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md

    $violations = $commandFiles | Select-String '[\u1F300-\u1F9FF]'

    $violations.Count -eq 0
} "Found emoji in CLI content"

# 4. Hook System Safety
Write-Host "`n[4] Hook System Safety" -ForegroundColor Cyan

Test-Check "hooks.json exists" {
    Test-Path "plugins/compound-engineering/hooks/hooks.json"
} "hooks.json not found"

Test-Check "No SessionStart hooks" {
    $hooksFile = "plugins/compound-engineering/hooks/hooks.json"

    if (Test-Path $hooksFile) {
        $hooks = Get-Content $hooksFile | ConvertFrom-Json

        $hasSessionStart = $hooks.hooks.PSObject.Properties.Name -contains "SessionStart"

        if ($hasSessionStart) {
            $sessionStartHooks = $hooks.hooks.SessionStart

            if ($sessionStartHooks -is [Array]) {
                return $sessionStartHooks.Count -eq 0
            }
        }

        return $true
    }

    return $false
} "SessionStart hooks detected (causes terminal blocking)"

# 5. Fork-Specific Features
Write-Host "`n[5] Fork-Specific Features" -ForegroundColor Cyan

Test-Check "Gemini integration intact" {
    $geminiFiles = @(
        "plugins/compound-engineering/commands/gemini.md",
        "src/converters/claude-to-gemini.ts",
        "src/targets/gemini.ts",
        "src/types/gemini.ts"
    )

    $missing = $geminiFiles | Where-Object { -not (Test-Path $_) }

    $missing.Count -eq 0
} "Gemini integration files missing"

Test-Check "Custom workflow commands exist" {
    $customCommands = @(
        "plugins/compound-engineering/commands/workflows/load.md",
        "plugins/compound-engineering/commands/workflows/save.md",
        "plugins/compound-engineering/commands/workflows/sync-upstream.md"
    )

    $missing = $customCommands | Where-Object { -not (Test-Path $_) }

    $missing.Count -eq 0
} "Custom workflow commands missing"

Test-Check "Chinese documentation exists" {
    $zhDocs = @(
        "docs/zh-CN/INSTALL.md",
        "docs/zh-CN/SYNC.md",
        "docs/zh-CN/VERSION-STRATEGY.md"
    )

    $missing = $zhDocs | Where-Object { -not (Test-Path $_) }

    $missing.Count -eq 0
} "Chinese documentation missing"

Test-Check "Automation scripts exist" {
    $scripts = @(
        "scripts/check-versions.ps1",
        "scripts/bump-version.ps1",
        "scripts/validate-upstream-merge.ps1"
    )

    $missing = $scripts | Where-Object { -not (Test-Path $_) }

    $missing.Count -eq 0
} "Automation scripts missing"

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Validation Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Passed:   $passed" -ForegroundColor Green
Write-Host "Failed:   $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "Warnings: $warnings" -ForegroundColor Yellow

if ($failed -eq 0) {
    Write-Host "`n[OK] ALL CHECKS PASSED" -ForegroundColor Green
    Write-Host "`n========================================`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "`n[FAILED] VALIDATION FAILED" -ForegroundColor Red
    Write-Host "`nPlease fix the issues above before committing." -ForegroundColor Yellow
    Write-Host "`n========================================`n" -ForegroundColor Cyan
    exit 1
}
