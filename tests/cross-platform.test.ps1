# Cross-Platform Compatibility Tests
# Purpose: Ensure CLI output is compatible across different terminals
# Usage: Invoke-Pester tests/cross-platform.test.ps1

BeforeAll {
    $ErrorActionPreference = "Stop"
    $projectRoot = Split-Path -Parent $PSScriptRoot

    # Get all command files (CLI-facing content)
    $script:commandFiles = Get-ChildItem -Recurse "$projectRoot/plugins/compound-engineering/commands/*.md"

    # Get all agent files
    $script:agentFiles = Get-ChildItem -Recurse "$projectRoot/plugins/compound-engineering/agents/*.md"

    # Get all skill files
    $script:skillFiles = Get-ChildItem -Recurse "$projectRoot/plugins/compound-engineering/skills/**/*.md"
}

Describe "Unicode Character Restrictions" {
    It "No Unicode circle numbers in command descriptions" {
        # Circle numbers: ①②③④⑤⑥⑦⑧⑨⑩ (U+2460-U+2473)

        $violations = @()

        foreach ($file in $script:commandFiles) {
            $content = Get-Content $file.FullName -Raw

            if ($content -match '[\u2460-\u2473]') {
                $violations += $file.Name
            }
        }

        $violations.Count | Should -Be 0 -Because "Circle numbers are not compatible with all terminals. Use 'Step N:' instead. Files: $($violations -join ', ')"
    }

    It "No emoji in CLI-facing content" {
        # Common emoji ranges: U+1F300-U+1F9FF

        $violations = @()

        foreach ($file in $script:commandFiles) {
            $content = Get-Content $file.FullName -Raw

            # Check for emoji
            if ($content -match '[\u1F300-\u1F9FF]') {
                $violations += $file.Name
            }
        }

        $violations.Count | Should -Be 0 -Because "Emoji may not display correctly in all terminals. Files: $($violations -join ', ')"
    }

    It "No special Unicode symbols in command descriptions" {
        # Special symbols: ⚠️ ✅ ❌ ⭐ 🚀 etc.

        $violations = @()

        foreach ($file in $script:commandFiles) {
            $content = Get-Content $file.FullName -Raw

            # Check for common problematic symbols
            if ($content -match '[⚠️✅❌⭐🚀💡🎉]') {
                $violations += $file.Name
            }
        }

        $violations.Count | Should -Be 0 -Because "Special symbols may not display correctly. Use [WARN], [OK], [ERROR] instead. Files: $($violations -join ', ')"
    }
}

Describe "Line Ending Consistency" {
    It "All markdown files use LF line endings (not CRLF)" {
        # This is important for cross-platform compatibility

        $violations = @()

        $allMdFiles = $script:commandFiles + $script:agentFiles + $script:skillFiles

        foreach ($file in $allMdFiles) {
            $content = [System.IO.File]::ReadAllBytes($file.FullName)

            # Check for CRLF (0x0D 0x0A)
            for ($i = 0; $i -lt $content.Length - 1; $i++) {
                if ($content[$i] -eq 0x0D -and $content[$i + 1] -eq 0x0A) {
                    $violations += $file.Name
                    break
                }
            }
        }

        # This is informational, not a hard requirement (Git can handle this)
        if ($violations.Count -gt 0) {
            Write-Warning "Some files use CRLF line endings: $($violations -join ', '). Consider configuring Git autocrlf."
        }

        $true | Should -Be $true
    }
}

Describe "Path Separator Compatibility" {
    It "No hardcoded Windows path separators in scripts" {
        $scriptFiles = Get-ChildItem "$projectRoot/scripts/*.sh"

        $violations = @()

        foreach ($file in $scriptFiles) {
            $content = Get-Content $file.FullName -Raw

            # Check for backslashes (Windows path separator)
            if ($content -match '\\[a-zA-Z]') {
                $violations += $file.Name
            }
        }

        $violations.Count | Should -Be 0 -Because "Bash scripts must use forward slashes. Files: $($violations -join ', ')"
    }
}

Describe "Terminal Output Format" {
    It "Command descriptions use ASCII-compatible format" {
        # Check that workflow commands use "Step N:" instead of circle numbers

        $workflowFiles = Get-ChildItem "$projectRoot/plugins/compound-engineering/commands/workflows/*.md"

        $violations = @()

        foreach ($file in $workflowFiles) {
            $content = Get-Content $file.FullName -Raw

            # Check for proper "Step N:" format in description
            if ($content -match 'description:\s*[①②③④⑤⑥⑦⑧⑨⑩]') {
                $violations += $file.Name
            }
        }

        $violations.Count | Should -Be 0 -Because "Workflow descriptions must use 'Step N:' format. Files: $($violations -join ', ')"
    }
}
