# Test Runner Script
# Purpose: Run all test suites and generate summary report
# Usage: powershell -ExecutionPolicy Bypass -File tests/run-all-tests.ps1

param(
    [switch]$Verbose,
    [switch]$CI  # Continuous Integration mode
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Compound Engineering Plugin Tests" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if Pester is installed
$pesterModule = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [Version]"5.0" }

if (-not $pesterModule) {
    Write-Host "Pester 5.0+ not found. Installing..." -ForegroundColor Yellow

    try {
        # Uninstall old versions first
        $oldPester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -lt [Version]"5.0" }
        if ($oldPester) {
            Write-Host "Removing old Pester versions..." -ForegroundColor Yellow
            $oldPester | ForEach-Object { Uninstall-Module -Name Pester -RequiredVersion $_.Version -Force -ErrorAction SilentlyContinue }
        }

        # Install Pester 5.x
        Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber
        Write-Host "Pester installed successfully.`n" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install Pester: $_" -ForegroundColor Red
        Write-Host "`nPlease install manually:" -ForegroundColor Yellow
        Write-Host "  Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber" -ForegroundColor Gray
        exit 1
    }
}

# Import Pester
try {
    Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
} catch {
    Write-Host "Failed to import Pester: $_" -ForegroundColor Red
    Write-Host "`nTry closing and reopening PowerShell, then run again." -ForegroundColor Yellow
    exit 1
}

# Define test files
$testFiles = @(
    "tests/version-consistency.test.ps1",
    "tests/component-references.test.ps1",
    "tests/cross-platform.test.ps1",
    "tests/hooks.test.ps1",
    "tests/upstream-sync.test.ps1",
    "tests/integration.test.ps1"
)

# Configure Pester
$pesterConfig = New-PesterConfiguration

$pesterConfig.Run.Path = $testFiles
$pesterConfig.Run.PassThru = $true

if ($Verbose) {
    $pesterConfig.Output.Verbosity = "Detailed"
} else {
    $pesterConfig.Output.Verbosity = "Normal"
}

if ($CI) {
    # CI mode: Generate NUnit XML report
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    $pesterConfig.TestResult.OutputPath = "test-results.xml"
}

# Run tests
Write-Host "Running test suites...`n" -ForegroundColor Yellow

$result = Invoke-Pester -Configuration $pesterConfig

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Total Tests:  $($result.TotalCount)" -ForegroundColor White
Write-Host "Passed:       $($result.PassedCount)" -ForegroundColor Green
Write-Host "Failed:       $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host "Skipped:      $($result.SkippedCount)" -ForegroundColor Yellow
Write-Host "Duration:     $($result.Duration.TotalSeconds) seconds" -ForegroundColor White

if ($result.FailedCount -gt 0) {
    Write-Host "`n❌ TESTS FAILED" -ForegroundColor Red
    Write-Host "`nFailed tests:" -ForegroundColor Red

    foreach ($test in $result.Failed) {
        Write-Host "  - $($test.ExpandedName)" -ForegroundColor Red
        Write-Host "    $($test.ErrorRecord.Exception.Message)" -ForegroundColor Yellow
    }

    Write-Host "`n========================================`n" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "`n✅ ALL TESTS PASSED" -ForegroundColor Green
    Write-Host "`n========================================`n" -ForegroundColor Cyan
    exit 0
}
