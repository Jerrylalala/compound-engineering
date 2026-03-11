# Version Consistency Tests
# Purpose: Ensure version numbers are synchronized across all configuration files
# Usage: Invoke-Pester tests/version-consistency.test.ps1

BeforeAll {
    $ErrorActionPreference = "Stop"
    $projectRoot = Split-Path -Parent $PSScriptRoot

    # Load JSON files
    $marketplaceFile = Join-Path $projectRoot ".claude-plugin/marketplace.json"
    $pluginFile = Join-Path $projectRoot "plugins/compound-engineering/.claude-plugin/plugin.json"
    $changelogFile = Join-Path $projectRoot "plugins/compound-engineering/CHANGELOG.md"

    $script:marketplace = Get-Content $marketplaceFile | ConvertFrom-Json
    $script:plugin = Get-Content $pluginFile | ConvertFrom-Json
    $script:changelog = Get-Content $changelogFile -Raw
}

Describe "Version Number Consistency" {
    It "marketplace.json and plugin.json versions match" {
        $marketplaceVersion = $script:marketplace.plugins[0].version
        $pluginVersion = $script:plugin.version

        $marketplaceVersion | Should -Be $pluginVersion -Because "Version numbers must be synchronized"
    }

    It "CHANGELOG.md contains current version" {
        $currentVersion = $script:plugin.version

        $script:changelog | Should -Match "## \[$currentVersion\]" -Because "CHANGELOG must document current version"
    }

    It "Version follows semantic versioning format" {
        $version = $script:plugin.version

        $version | Should -Match '^\d+\.\d+\.\d+$' -Because "Version must be in format X.Y.Z"
    }
}

Describe "Identity Information Consistency" {
    It "marketplace.json owner points to fork repository" {
        $ownerUrl = $script:marketplace.owner.url

        $ownerUrl | Should -Match "Jerrylalala" -Because "Fork must have unique owner identity"
    }

    It "plugin.json homepage points to fork repository" {
        $homepage = $script:plugin.homepage

        $homepage | Should -Match "Jerrylalala" -Because "Homepage must point to fork"
    }

    It "plugin.json repository points to fork" {
        $repository = $script:plugin.repository

        $repository | Should -Match "Jerrylalala" -Because "Repository must point to fork"
    }

    It "marketplace name is unique (not 'every-marketplace')" {
        $name = $script:marketplace.name

        $name | Should -Not -Be "every-marketplace" -Because "Fork must have unique marketplace name"
    }
}

Describe "Component Count Accuracy" {
    It "Actual agent count matches declared count" {
        $agentCount = (Get-ChildItem -Recurse "plugins/compound-engineering/agents/*.md").Count

        $description = $script:plugin.description
        if ($description -match '(\d+) agents?') {
            $declaredCount = [int]$Matches[1]
            $agentCount | Should -Be $declaredCount -Because "Agent count must be accurate"
        }
    }

    It "Actual command count matches declared count" {
        $commandCount = (Get-ChildItem -Recurse "plugins/compound-engineering/commands/*.md").Count

        $description = $script:plugin.description
        if ($description -match '(\d+) commands?') {
            $declaredCount = [int]$Matches[1]
            $commandCount | Should -Be $declaredCount -Because "Command count must be accurate"
        }
    }

    It "Actual skill count matches declared count" {
        $skillCount = (Get-ChildItem -Directory "plugins/compound-engineering/skills/").Count

        $description = $script:plugin.description
        if ($description -match '(\d+) skills?') {
            $declaredCount = [int]$Matches[1]
            $skillCount | Should -Be $declaredCount -Because "Skill count must be accurate"
        }
    }
}
