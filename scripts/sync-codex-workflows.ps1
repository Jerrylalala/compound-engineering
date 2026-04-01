param(
    [string]$CodexHome = "$HOME\.codex"
)

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
    "ce-doctor",
    "ce-plan",
    "ce-pr",
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
    "ce-doctor.md",
    "ce-plan.md",
    "ce-pr.md",
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

foreach ($name in $staleSkillEntries) {
    $path = Join-Path $targetSkillsRoot $name
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path
        Write-Host "Removed stale skill: $name"
    }
}

foreach ($name in $stalePromptEntries) {
    $path = Join-Path $targetPromptsRoot $name
    if (Test-Path $path) {
        Remove-Item -Force $path
        Write-Host "Removed stale prompt: $name"
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
