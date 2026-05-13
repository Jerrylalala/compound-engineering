param(
    [string]$CodexHome
)
if (-not $CodexHome) {
    $CodexHome = Join-Path $HOME ".codex"
}

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$repoSkillsRoot = Join-Path $repoRoot ".codex\skills"
$targetSkillsRoot = Join-Path $CodexHome "skills"
$targetPromptsRoot = Join-Path $CodexHome "prompts"

$workflowSkills = @(
    "workflows-brainstorm",
    "workflows-plan",
    "workflows-review"
)

$staleSkillEntries = @(
    "ce-brainstorm",
    "ce-compound",
    "ce-compound-refresh",
    "ce-doctor",
    "ce-ideas",
    "ce-ideate",
    "ce-plan",
    "ce-pr",
    "ce-resume",
    "ce-review",
    "ce-sync-upstream",
    "ce-work",
    "workflows-compound",
    "workflows-load",
    "workflows-pr",
    "workflows-save",
    "workflows-sync-upstream",
    "workflows-work",
    "compound-workflow-documents"
)

$stalePromptEntries = @(
    "ce-brainstorm.md",
    "ce-compound.md",
    "ce-compound-refresh.md",
    "ce-doctor.md",
    "ce-ideas.md",
    "ce-ideate.md",
    "ce-plan.md",
    "ce-pr.md",
    "ce-resume.md",
    "ce-review.md",
    "ce-sync-upstream.md",
    "ce-work.md",
    "workflows-brainstorm.md",
    "workflows-compound.md",
    "workflows-load.md",
    "workflows-plan.md",
    "workflows-pr.md",
    "workflows-review.md",
    "workflows-save.md",
    "workflows-sync-upstream.md",
    "workflows-work.md"
)

New-Item -ItemType Directory -Force $targetSkillsRoot | Out-Null
New-Item -ItemType Directory -Force $targetPromptsRoot | Out-Null

function Test-ManagedCompoundEntry {
    param([string]$Path)

    $skillFile = Join-Path $Path "SKILL.md"
    if (-not (Test-Path $skillFile)) {
        return $false
    }

    $content = Get-Content -Raw $skillFile
    return $content -match "(?m)^name:\s*workflows-" -or $content -match "(?m)^# workflows-"
}

foreach ($name in $staleSkillEntries) {
    $path = Join-Path $targetSkillsRoot $name
    if (Test-Path $path) {
        if (Test-ManagedCompoundEntry $path) {
            Remove-Item -Recurse -Force $path
            Write-Host "Removed stale skill: $name"
        } else {
            Write-Host "Skipped user skill with stale name: $name"
        }
    }
}

function Test-ManagedCompoundPrompt {
    param([string]$Path)

    $content = Get-Content -Raw $Path
    return $content -match "(?m)^# workflows-" -or $content -match "Use the workflows-"
}

foreach ($name in $stalePromptEntries) {
    $path = Join-Path $targetPromptsRoot $name
    if (Test-Path $path) {
        if (Test-ManagedCompoundPrompt $path) {
            Remove-Item -Force $path
            Write-Host "Removed stale prompt: $name"
        } else {
            Write-Host "Skipped user prompt with stale name: $name"
        }
    }
}

foreach ($name in $workflowSkills) {
    $source = Join-Path $repoSkillsRoot $name
    $target = Join-Path $targetSkillsRoot $name

    if (-not (Test-Path $source)) {
        throw "Missing repo skill: $source"
    }

    if (Test-Path $target) {
        Remove-Item -Recurse -Force $target
    }

    Copy-Item -Recurse -Force $source $target
    Write-Host "Synced skill: $name"
}

Write-Host ""
Write-Host "Codex workflow sync complete."
Write-Host "Kept skills:"
foreach ($name in $workflowSkills) {
    Write-Host " - $name"
}
