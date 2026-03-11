# Component Reference Integrity Tests
# Purpose: Ensure all component references (agents, skills, commands) are valid
# Usage: Invoke-Pester tests/component-references.test.ps1

BeforeAll {
    $ErrorActionPreference = "Stop"
    $projectRoot = Split-Path -Parent $PSScriptRoot

    # Get all existing agents
    $script:existingAgents = Get-ChildItem "$projectRoot/plugins/compound-engineering/agents/**/*.md" |
        ForEach-Object { $_.BaseName } | Sort-Object -Unique

    # Get all existing skills
    $script:existingSkills = Get-ChildItem -Directory "$projectRoot/plugins/compound-engineering/skills/" |
        ForEach-Object { $_.Name } | Sort-Object -Unique

    # Get all workflow files
    $script:workflowFiles = Get-ChildItem "$projectRoot/plugins/compound-engineering/commands/workflows/*.md"

    # Get all markdown files
    $script:allMdFiles = Get-ChildItem -Recurse "$projectRoot/plugins/compound-engineering/**/*.md"
}

Describe "Agent Reference Integrity" {
    It "All Task() calls reference existing agents" {
        $taskCalls = $script:allMdFiles | Select-String "Task\(([a-z-]+)\)" -AllMatches |
            ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique

        $invalidReferences = @()

        foreach ($task in $taskCalls) {
            if ($task -notin $script:existingAgents) {
                $invalidReferences += $task
            }
        }

        $invalidReferences.Count | Should -Be 0 -Because "All Task() calls must reference existing agents. Invalid: $($invalidReferences -join ', ')"
    }

    It "No phantom agent references in workflow commands" {
        $referencedAgents = $script:workflowFiles | Select-String "Task ([a-z-]+)\(" -AllMatches |
            ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique

        $phantoms = $referencedAgents | Where-Object { $_ -notin $script:existingAgents }

        $phantoms.Count | Should -Be 0 -Because "Workflow commands must not reference non-existent agents. Phantoms: $($phantoms -join ', ')"
    }
}

Describe "Skill Reference Integrity" {
    It "Skills are not directly called via Task()" {
        # Skills should be referenced via 'skill: skill-name' or in Task descriptions
        # NOT directly as Task(skill-name)

        $taskCalls = $script:allMdFiles | Select-String "Task\(([a-z-]+)\)" -AllMatches |
            ForEach-Object { $_.Matches.Groups[1].Value }

        # Check if any Task() call matches a skill name
        $invalidCalls = $taskCalls | Where-Object { $_ -in $script:existingSkills }

        $invalidCalls.Count | Should -Be 0 -Because "Skills must not be called directly via Task(). Use 'skill: skill-name' instead. Invalid: $($invalidCalls -join ', ')"
    }

    It "All skill directories contain SKILL.md" {
        $skillDirs = Get-ChildItem -Directory "$projectRoot/plugins/compound-engineering/skills/"

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

Describe "Component Naming Conventions" {
    It "Agent names follow recommended patterns" {
        # Recommended patterns: xxx-reviewer, xxx-analyzer, xxx-specialist, xxx-guardian, xxx-oracle

        $recommendedPatterns = @(
            '-reviewer$',
            '-analyzer$',
            '-specialist$',
            '-guardian$',
            '-oracle$',
            '-strategist$',
            '-sentinel$',
            '-detective$'
        )

        $nonConformingAgents = @()

        foreach ($agent in $script:existingAgents) {
            $matchesPattern = $false
            foreach ($pattern in $recommendedPatterns) {
                if ($agent -match $pattern) {
                    $matchesPattern = $true
                    break
                }
            }

            if (-not $matchesPattern) {
                $nonConformingAgents += $agent
            }
        }

        # This is a warning, not a hard failure
        if ($nonConformingAgents.Count -gt 0) {
            Write-Warning "Some agents don't follow recommended naming patterns: $($nonConformingAgents -join ', ')"
        }

        # Always pass, but log warning
        $true | Should -Be $true
    }
}

Describe "Cross-Reference Consistency" {
    It "README.md mentions all workflow commands" {
        $readmePath = "$projectRoot/plugins/compound-engineering/README.md"
        $readme = Get-Content $readmePath -Raw

        $workflowCommands = $script:workflowFiles | ForEach-Object { $_.BaseName }

        $missingInReadme = @()

        foreach ($cmd in $workflowCommands) {
            if ($readme -notmatch "/workflows:$cmd") {
                $missingInReadme += $cmd
            }
        }

        # This is informational, not a hard requirement
        if ($missingInReadme.Count -gt 0) {
            Write-Warning "Some workflow commands not mentioned in README: $($missingInReadme -join ', ')"
        }

        $true | Should -Be $true
    }
}
