# Upstream Merge Validation Script
# Purpose: Detect conflicts before merging upstream changes
# Usage: powershell -ExecutionPolicy Bypass -File scripts/validate-upstream-merge.ps1

param(
    [string]$UpstreamBranch = "upstream/main",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Upstream Merge Validation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Verify upstream remote exists
Write-Host "[1/6] Checking upstream remote..." -ForegroundColor Yellow
$remotes = git remote
if ($remotes -notcontains "upstream") {
    Write-Host "ERROR: 'upstream' remote not configured" -ForegroundColor Red
    Write-Host "Add it with: git remote add upstream https://github.com/EveryInc/compound-engineering-plugin.git" -ForegroundColor Yellow
    exit 1
}
Write-Host "  ✓ Upstream remote exists" -ForegroundColor Green

# Step 2: Fetch latest upstream
Write-Host "`n[2/6] Fetching latest upstream changes..." -ForegroundColor Yellow
git fetch upstream 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to fetch upstream" -ForegroundColor Red
    exit 1
}
$upstreamCommits = (git rev-list --count HEAD..$UpstreamBranch)
Write-Host "  ✓ Fetched successfully ($upstreamCommits commits ahead)" -ForegroundColor Green

if ($upstreamCommits -eq 0) {
    Write-Host "`nNo upstream changes to merge. Already up to date." -ForegroundColor Green
    exit 0
}

# Step 3: Define protected fork-specific files/directories
Write-Host "`n[3/6] Defining protected fork resources..." -ForegroundColor Yellow
$protectedPaths = @(
    # Custom commands
    "plugins/compound-engineering/commands/codex.md",
    "plugins/compound-engineering/commands/gemini.md",
    "plugins/compound-engineering/commands/workflows/load.md",
    "plugins/compound-engineering/commands/workflows/save.md",
    "plugins/compound-engineering/commands/workflows/sync-upstream.md",

    # Hooks system
    "plugins/compound-engineering/hooks/",

    # Gemini integration infrastructure
    "src/converters/claude-to-gemini.ts",
    "src/targets/gemini.ts",
    "src/types/gemini.ts",
    "src/utils/filter-claude-code-only.ts",

    # Custom skills
    "skills-custom/",

    # Chinese documentation
    "docs/zh-CN/",

    # Solution database
    "docs/solutions/",

    # Sync reports
    "docs/sync-reports/",

    # Automation scripts
    "scripts/bump-version.ps1",
    "scripts/check-versions.ps1",
    "scripts/check-versions.sh",
    "scripts/codex-review-now.sh",
    "scripts/gemini-review-now.sh",
    "scripts/pre-commit",
    "scripts/sync-to-targets.ps1",

    # Fork metadata
    "README.zh-CN.md",
    "CLAUDE.md"
)
Write-Host "  ✓ Protecting $($protectedPaths.Count) paths" -ForegroundColor Green

# Step 4: Check for file deletions
Write-Host "`n[4/6] Checking for dangerous file deletions..." -ForegroundColor Yellow
$deletions = git diff --name-status HEAD $UpstreamBranch | Where-Object { $_ -match "^D\s+" }
$criticalDeletions = @()

foreach ($deletion in $deletions) {
    $file = ($deletion -split "\s+")[1]

    foreach ($protected in $protectedPaths) {
        if ($file -like "$protected*") {
            $criticalDeletions += $file
            break
        }
    }
}

if ($criticalDeletions.Count -gt 0) {
    Write-Host "  ✗ CRITICAL: Upstream would delete protected fork files!" -ForegroundColor Red
    Write-Host "`nProtected files at risk ($($criticalDeletions.Count) files):" -ForegroundColor Red
    foreach ($file in $criticalDeletions) {
        Write-Host "    - $file" -ForegroundColor Red
    }
    Write-Host "`n⚠️  DO NOT use 'git merge upstream/main'" -ForegroundColor Yellow
    Write-Host "   Use selective cherry-pick instead. See UPSTREAM-MERGE-RECOMMENDATION.md" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "  ✓ No protected files at deletion risk" -ForegroundColor Green
}

# Step 5: Check for modifications to critical shared files
Write-Host "`n[5/6] Checking for modifications to shared files..." -ForegroundColor Yellow
$modifications = git diff --name-status HEAD $UpstreamBranch | Where-Object { $_ -match "^M\s+" }
$criticalMods = @()

$sharedCritical = @(
    "plugins/compound-engineering/.claude-plugin/plugin.json",
    "plugins/compound-engineering/CLAUDE.md",
    ".claude-plugin/marketplace.json"
)

foreach ($mod in $modifications) {
    $file = ($mod -split "\s+")[1]

    foreach ($critical in $sharedCritical) {
        if ($file -eq $critical) {
            $criticalMods += $file
            break
        }
    }
}

if ($criticalMods.Count -gt 0) {
    Write-Host "  ⚠️  Upstream modified critical shared files:" -ForegroundColor Yellow
    foreach ($file in $criticalMods) {
        Write-Host "    - $file" -ForegroundColor Yellow
    }
    Write-Host "`n   These will require careful manual merge" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ No critical shared file modifications" -ForegroundColor Green
}

# Step 6: Summary and recommendations
Write-Host "`n[6/6] Generating recommendations..." -ForegroundColor Yellow

# Count upstream changes
$additions = (git diff --name-status HEAD $UpstreamBranch | Where-Object { $_ -match "^A\s+" }).Count
$allMods = $modifications.Count
$allDels = $deletions.Count

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Upstream changes:" -ForegroundColor White
Write-Host "  Commits ahead: $upstreamCommits" -ForegroundColor White
Write-Host "  Files added: $additions" -ForegroundColor White
Write-Host "  Files modified: $allMods" -ForegroundColor White
Write-Host "  Files deleted: $allDels" -ForegroundColor White

if ($criticalDeletions.Count -eq 0) {
    Write-Host "`n✓ SAFE: No protected files at risk" -ForegroundColor Green
    Write-Host "`nRecommended approach:" -ForegroundColor Cyan
    Write-Host "  1. Review upstream commits:" -ForegroundColor White
    Write-Host "     git log --oneline HEAD..$UpstreamBranch" -ForegroundColor Gray
    Write-Host "  2. Create integration branch:" -ForegroundColor White
    Write-Host "     git checkout -b integrate-upstream-$(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Gray
    Write-Host "  3. Cherry-pick valuable commits" -ForegroundColor White
    Write-Host "     See: UPSTREAM-MERGE-RECOMMENDATION.md" -ForegroundColor Gray
} else {
    Write-Host "`n✗ UNSAFE: Protected files at risk" -ForegroundColor Red
    Write-Host "`nYou MUST use selective cherry-pick strategy." -ForegroundColor Yellow
    Write-Host "See detailed guide: UPSTREAM-MERGE-RECOMMENDATION.md" -ForegroundColor Yellow
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

if ($Verbose) {
    Write-Host "Detailed file changes:" -ForegroundColor Cyan
    Write-Host "Run: git diff --stat HEAD $UpstreamBranch" -ForegroundColor Gray
}

# Exit with appropriate code
if ($criticalDeletions.Count -eq 0) {
    exit 0
} else {
    exit 1
}
