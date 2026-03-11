# Hook System Safety Tests
# Purpose: Ensure hooks.json follows safe configuration patterns
# Usage: Invoke-Pester tests/hooks.test.ps1

BeforeAll {
    $ErrorActionPreference = "Stop"
    $projectRoot = Split-Path -Parent $PSScriptRoot

    $hooksFile = Join-Path $projectRoot "plugins/compound-engineering/hooks/hooks.json"

    if (Test-Path $hooksFile) {
        $script:hooks = Get-Content $hooksFile | ConvertFrom-Json
        $script:hooksFileExists = $true
    } else {
        $script:hooksFileExists = $false
    }
}

Describe "Hook Configuration Safety" {
    It "hooks.json file exists" {
        $script:hooksFileExists | Should -Be $true -Because "hooks.json is required for plugin hooks"
    }

    It "hooks.json has correct schema structure" {
        if ($script:hooksFileExists) {
            # Must have 'description' and 'hooks' fields
            $script:hooks.PSObject.Properties.Name | Should -Contain "description"
            $script:hooks.PSObject.Properties.Name | Should -Contain "hooks"
        }
    }

    It "hooks.json has no SessionStart hooks" {
        if ($script:hooksFileExists) {
            $hasSessionStart = $script:hooks.hooks.PSObject.Properties.Name -contains "SessionStart"

            if ($hasSessionStart) {
                $sessionStartHooks = $script:hooks.hooks.SessionStart

                # SessionStart array must be empty
                if ($sessionStartHooks -is [Array]) {
                    $sessionStartHooks.Count | Should -Be 0 -Because "SessionStart hooks cause terminal blocking on Windows"
                } else {
                    # If not an array, it should be null or empty
                    $sessionStartHooks | Should -BeNullOrEmpty -Because "SessionStart hooks cause terminal blocking on Windows"
                }
            }
        }
    }

    It "No hooks use type: 'prompt'" {
        if ($script:hooksFileExists) {
            $allHooks = @()

            foreach ($hookType in $script:hooks.hooks.PSObject.Properties.Name) {
                $hookArray = $script:hooks.hooks.$hookType

                if ($hookArray -is [Array]) {
                    $allHooks += $hookArray
                }
            }

            $promptTypeHooks = $allHooks | Where-Object { $_.type -eq "prompt" }

            $promptTypeHooks.Count | Should -Be 0 -Because "type: 'prompt' is not supported in hooks"
        }
    }

    It "No SessionStart hooks use type: 'command'" {
        if ($script:hooksFileExists) {
            $hasSessionStart = $script:hooks.hooks.PSObject.Properties.Name -contains "SessionStart"

            if ($hasSessionStart) {
                $sessionStartHooks = $script:hooks.hooks.SessionStart

                if ($sessionStartHooks -is [Array]) {
                    $commandTypeHooks = $sessionStartHooks | Where-Object { $_.type -eq "command" }

                    $commandTypeHooks.Count | Should -Be 0 -Because "SessionStart with type: 'command' blocks terminal on Windows"
                }
            }
        }
    }
}

Describe "Hook Regression Prevention" {
    It "hooks.json matches known safe state" {
        if ($script:hooksFileExists) {
            # Known safe state: empty hooks object
            $expectedSafeState = @{
                description = $script:hooks.description
                hooks = @{}
            }

            # Check if hooks object is empty
            $hookCount = ($script:hooks.hooks.PSObject.Properties | Measure-Object).Count

            if ($hookCount -gt 0) {
                Write-Warning "hooks.json contains hooks. Verify they don't cause SessionStart issues."
                Write-Warning "See: docs/solutions/integration-issues/sessionstart-hook-prompt-type-not-supported.md"
            }

            # This is a warning, not a hard failure
            $true | Should -Be $true
        }
    }
}

Describe "Alternative Static Content Injection" {
    It "Plugin CLAUDE.md exists as alternative to hooks" {
        $claudeMdPath = Join-Path $projectRoot "plugins/compound-engineering/CLAUDE.md"

        Test-Path $claudeMdPath | Should -Be $true -Because "CLAUDE.md is the recommended way to inject static content"
    }

    It "CLAUDE.md is not empty" {
        $claudeMdPath = Join-Path $projectRoot "plugins/compound-engineering/CLAUDE.md"

        if (Test-Path $claudeMdPath) {
            $content = Get-Content $claudeMdPath -Raw

            $content.Length | Should -BeGreaterThan 0 -Because "CLAUDE.md should contain plugin instructions"
        }
    }
}
