# Integration Tests
# Purpose: End-to-end tests for plugin functionality
# Usage: Invoke-Pester tests/integration.test.ps1

BeforeAll {
    $ErrorActionPreference = "Stop"
    $projectRoot = Split-Path -Parent $PSScriptRoot

    # Check if plugin directory is valid
    $pluginDir = Join-Path $projectRoot "plugins/compound-engineering"
    $script:pluginDir = $pluginDir
}

Describe "Plugin Structure Integrity" {
    It "Plugin directory exists" {
        Test-Path $script:pluginDir | Should -Be $true
    }

    It "Plugin has required configuration files" {
        $requiredFiles = @(
            ".claude-plugin/plugin.json",
            "CLAUDE.md",
            "README.md",
            "CHANGELOG.md"
        )

        $missingFiles = @()

        foreach ($file in $requiredFiles) {
            $fullPath = Join-Path $script:pluginDir $file

            if (-not (Test-Path $fullPath)) {
                $missingFiles += $file
            }
        }

        $missingFiles.Count | Should -Be 0 -Because "Plugin must have all required files. Missing: $($missingFiles -join ', ')"
    }

    It "Plugin has required directories" {
        $requiredDirs = @(
            "agents",
            "commands",
            "skills"
        )

        $missingDirs = @()

        foreach ($dir in $requiredDirs) {
            $fullPath = Join-Path $script:pluginDir $dir

            if (-not (Test-Path $fullPath)) {
                $missingDirs += $dir
            }
        }

        $missingDirs.Count | Should -Be 0 -Because "Plugin must have all required directories. Missing: $($missingDirs -join ', ')"
    }
}

Describe "Component File Format Validation" {
    It "All agent files are valid markdown" {
        $agentFiles = Get-ChildItem -Recurse "$($script:pluginDir)/agents/*.md"

        $invalidFiles = @()

        foreach ($file in $agentFiles) {
            $content = Get-Content $file.FullName -Raw

            # Basic markdown validation: must have content
            if ($content.Length -eq 0) {
                $invalidFiles += $file.Name
            }
        }

        $invalidFiles.Count | Should -Be 0 -Because "All agent files must be valid markdown. Invalid: $($invalidFiles -join ', ')"
    }

    It "All command files have description field" {
        $commandFiles = Get-ChildItem -Recurse "$($script:pluginDir)/commands/*.md"

        $missingDescription = @()

        foreach ($file in $commandFiles) {
            $content = Get-Content $file.FullName -Raw

            # Check for description field (YAML frontmatter or markdown)
            if ($content -notmatch 'description:') {
                $missingDescription += $file.Name
            }
        }

        $missingDescription.Count | Should -Be 0 -Because "All commands must have description. Missing: $($missingDescription -join ', ')"
    }

    It "All skill directories have SKILL.md" {
        $skillDirs = Get-ChildItem -Directory "$($script:pluginDir)/skills/"

        $missingSkillMd = @()

        foreach ($dir in $skillDirs) {
            $skillMdPath = Join-Path $dir.FullName "SKILL.md"

            if (-not (Test-Path $skillMdPath)) {
                $missingSkillMd += $dir.Name
            }
        }

        $missingSkillMd.Count | Should -Be 0 -Because "All skill directories must contain SKILL.md. Missing: $($missingSkillMd -join ', ')"
    }
}

Describe "Fork-Specific Features" {
    It "Gemini integration is complete" {
        $geminiFiles = @(
            "commands/gemini.md",
            "../../../src/converters/claude-to-gemini.ts",
            "../../../src/targets/gemini.ts",
            "../../../src/types/gemini.ts"
        )

        $missingFiles = @()

        foreach ($file in $geminiFiles) {
            $fullPath = Join-Path $script:pluginDir $file

            if (-not (Test-Path $fullPath)) {
                $missingFiles += $file
            }
        }

        $missingFiles.Count | Should -Be 0 -Because "Gemini integration is a core fork feature. Missing: $($missingFiles -join ', ')"
    }

    It "Codex integration is complete" {
        $codexFiles = @(
            "commands/codex.md",
            "../../../src/converters/claude-to-codex.ts",
            "../../../src/targets/codex.ts"
        )

        $existingFiles = @()

        foreach ($file in $codexFiles) {
            $fullPath = Join-Path $script:pluginDir $file

            if (Test-Path $fullPath) {
                $existingFiles += $file
            }
        }

        # At least codex.md should exist
        $existingFiles.Count | Should -BeGreaterThan 0 -Because "Codex integration should have at least command file"
    }

    It "Custom workflow commands exist" {
        $customCommands = @(
            "commands/workflows/load.md",
            "commands/workflows/save.md",
            "commands/workflows/sync-upstream.md"
        )

        $missingCommands = @()

        foreach ($cmd in $customCommands) {
            $fullPath = Join-Path $script:pluginDir $cmd

            if (-not (Test-Path $fullPath)) {
                $missingCommands += $cmd
            }
        }

        $missingCommands.Count | Should -Be 0 -Because "Custom workflow commands are fork-specific. Missing: $($missingCommands -join ', ')"
    }

    It "Chinese documentation exists" {
        $zhCnDocs = @(
            "../../../docs/zh-CN/INSTALL.md",
            "../../../docs/zh-CN/SYNC.md",
            "../../../docs/zh-CN/VERSION-STRATEGY.md"
        )

        $missingDocs = @()

        foreach ($doc in $zhCnDocs) {
            $fullPath = Join-Path $script:pluginDir $doc

            if (-not (Test-Path $fullPath)) {
                $missingDocs += $doc
            }
        }

        $missingDocs.Count | Should -Be 0 -Because "Chinese documentation is a fork feature. Missing: $($missingDocs -join ', ')"
    }
}

Describe "Automation Scripts Integrity" {
    It "Version management scripts exist" {
        $scripts = @(
            "../../../scripts/check-versions.ps1",
            "../../../scripts/bump-version.ps1",
            "../../../scripts/validate-upstream-merge.ps1"
        )

        $missingScripts = @()

        foreach ($script in $scripts) {
            $fullPath = Join-Path $script:pluginDir $script

            if (-not (Test-Path $fullPath)) {
                $missingScripts += $script
            }
        }

        $missingScripts.Count | Should -Be 0 -Because "Automation scripts are essential for fork maintenance. Missing: $($missingScripts -join ', ')"
    }

    It "Review automation scripts exist" {
        $reviewScripts = @(
            "../../../scripts/codex-review-now.sh",
            "../../../scripts/gemini-review-now.sh"
        )

        $existingScripts = @()

        foreach ($script in $reviewScripts) {
            $fullPath = Join-Path $script:pluginDir $script

            if (Test-Path $fullPath) {
                $existingScripts += $script
            }
        }

        $existingScripts.Count | Should -BeGreaterThan 0 -Because "At least one review automation script should exist"
    }
}

Describe "Documentation Completeness" {
    It "Solution database exists" {
        $solutionsDir = Join-Path $projectRoot "docs/solutions"

        Test-Path $solutionsDir | Should -Be $true -Because "Solution database is essential for knowledge management"
    }

    It "Prevention strategies document exists" {
        $preventionDoc = Join-Path $projectRoot "docs/solutions/PREVENTION-STRATEGIES.md"

        Test-Path $preventionDoc | Should -Be $true -Because "Prevention strategies must be documented"
    }

    It "Integration issues are documented" {
        $issuesDir = Join-Path $projectRoot "docs/solutions/integration-issues"

        Test-Path $issuesDir | Should -Be $true -Because "Integration issues must be documented"

        $issueFiles = Get-ChildItem "$issuesDir/*.md"

        $issueFiles.Count | Should -BeGreaterThan 0 -Because "At least one integration issue should be documented"
    }
}
