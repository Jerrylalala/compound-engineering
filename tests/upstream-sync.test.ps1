# Upstream Sync Safety Tests
# Purpose: Ensure fork-specific files are protected during upstream merges
# Usage: Invoke-Pester tests/upstream-sync.test.ps1

BeforeAll {
    $ErrorActionPreference = "Stop"
    $projectRoot = Split-Path -Parent $PSScriptRoot

    # Define protected fork-specific files
    $script:protectedFiles = @(
        # Custom commands
        "plugins/compound-engineering/commands/codex.md",
        "plugins/compound-engineering/commands/gemini.md",
        "plugins/compound-engineering/commands/workflows/load.md",
        "plugins/compound-engineering/commands/workflows/save.md",
        "plugins/compound-engineering/commands/workflows/sync-upstream.md",

        # Gemini integration infrastructure
        "src/converters/claude-to-gemini.ts",
        "src/targets/gemini.ts",
        "src/types/gemini.ts",
        "src/utils/filter-claude-code-only.ts",

        # Chinese documentation
        "docs/zh-CN/INSTALL.md",
        "docs/zh-CN/SYNC.md",
        "docs/zh-CN/VERSION-STRATEGY.md",

        # Solution database
        "docs/solutions/PREVENTION-STRATEGIES.md",

        # Automation scripts
        "scripts/bump-version.ps1",
        "scripts/check-versions.ps1",
        "scripts/validate-upstream-merge.ps1"
    )

    # Define protected directories
    $script:protectedDirs = @(
        "plugins/compound-engineering/hooks",
        "skills-custom",
        "docs/zh-CN",
        "docs/solutions",
        "docs/sync-reports",
        "tests"
    )
}

Describe "Protected Fork Files Exist" {
    It "All Tier 1 protected files exist" {
        $missingFiles = @()

        foreach ($file in $script:protectedFiles) {
            $fullPath = Join-Path $projectRoot $file

            if (-not (Test-Path $fullPath)) {
                $missingFiles += $file
            }
        }

        $missingFiles.Count | Should -Be 0 -Because "Protected fork files must exist. Missing: $($missingFiles -join ', ')"
    }

    It "All protected directories exist" {
        $missingDirs = @()

        foreach ($dir in $script:protectedDirs) {
            $fullPath = Join-Path $projectRoot $dir

            if (-not (Test-Path $fullPath)) {
                $missingDirs += $dir
            }
        }

        $missingDirs.Count | Should -Be 0 -Because "Protected directories must exist. Missing: $($missingDirs -join ', ')"
    }
}

Describe "Fork Identity Preservation" {
    It "Gemini integration files are intact" {
        $geminiFiles = @(
            "src/converters/claude-to-gemini.ts",
            "src/targets/gemini.ts",
            "src/types/gemini.ts"
        )

        $missingGeminiFiles = @()

        foreach ($file in $geminiFiles) {
            $fullPath = Join-Path $projectRoot $file

            if (-not (Test-Path $fullPath)) {
                $missingGeminiFiles += $file
            }
        }

        $missingGeminiFiles.Count | Should -Be 0 -Because "Gemini integration is a core fork feature. Missing: $($missingGeminiFiles -join ', ')"
    }

    It "Custom workflow commands exist" {
        $customCommands = @(
            "plugins/compound-engineering/commands/workflows/load.md",
            "plugins/compound-engineering/commands/workflows/save.md",
            "plugins/compound-engineering/commands/workflows/sync-upstream.md"
        )

        $missingCommands = @()

        foreach ($cmd in $customCommands) {
            $fullPath = Join-Path $projectRoot $cmd

            if (-not (Test-Path $fullPath)) {
                $missingCommands += $cmd
            }
        }

        $missingCommands.Count | Should -Be 0 -Because "Custom workflow commands are fork-specific. Missing: $($missingCommands -join ', ')"
    }
}

Describe "Component Reference Integrity After Sync" {
    It "No phantom agent references in workflows" {
        $workflowFiles = Get-ChildItem "$projectRoot/plugins/compound-engineering/commands/workflows/*.md"
        $agentFiles = Get-ChildItem "$projectRoot/plugins/compound-engineering/agents/**/*.md"

        $referencedAgents = $workflowFiles | Select-String "Task ([a-z-]+)\(" -AllMatches |
            ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique

        $existingAgents = $agentFiles | ForEach-Object { $_.BaseName } | Sort-Object -Unique

        $phantoms = $referencedAgents | Where-Object { $_ -notin $existingAgents }

        $phantoms.Count | Should -Be 0 -Because "Upstream sync must not introduce phantom agent references. Phantoms: $($phantoms -join ', ')"
    }

    It "Workflow commands reference correct number of agents" {
        # After upstream sync, ensure workflow commands don't reference removed agents

        $reviewFile = "$projectRoot/plugins/compound-engineering/commands/workflows/review.md"

        if (Test-Path $reviewFile) {
            $content = Get-Content $reviewFile -Raw

            # Check for known removed agents (from phantom-agent-references issue)
            $removedAgents = @(
                "rails-turbo-expert",
                "dependency-detective",
                "code-philosopher",
                "devops-harmony-analyst",
                "cora-test-reviewer"
            )

            $foundRemovedAgents = @()

            foreach ($agent in $removedAgents) {
                if ($content -match "Task\($agent\)") {
                    $foundRemovedAgents += $agent
                }
            }

            $foundRemovedAgents.Count | Should -Be 0 -Because "Removed agents must not be referenced. Found: $($foundRemovedAgents -join ', ')"
        }
    }
}

Describe "Upstream Merge Validation Script" {
    It "validate-upstream-merge.ps1 script exists" {
        $scriptPath = Join-Path $projectRoot "scripts/validate-upstream-merge.ps1"

        Test-Path $scriptPath | Should -Be $true -Because "Validation script is required for safe upstream merges"
    }

    It "validate-upstream-merge.ps1 is executable" {
        $scriptPath = Join-Path $projectRoot "scripts/validate-upstream-merge.ps1"

        if (Test-Path $scriptPath) {
            $content = Get-Content $scriptPath -Raw

            $content.Length | Should -BeGreaterThan 0 -Because "Validation script must not be empty"
        }
    }
}

Describe "Documentation Consistency After Sync" {
    It "SYNC.md documents upstream merge strategy" {
        $syncMdPath = Join-Path $projectRoot "docs/zh-CN/SYNC.md"

        if (Test-Path $syncMdPath) {
            $content = Get-Content $syncMdPath -Raw

            $content | Should -Match "上游同步|upstream.*merge|cherry-pick" -Because "SYNC.md must document merge strategy"
        }
    }

    It "Solution database contains upstream merge analysis" {
        $analysisFile = Join-Path $projectRoot "docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md"

        Test-Path $analysisFile | Should -Be $true -Because "Upstream merge analysis must be preserved"
    }
}
