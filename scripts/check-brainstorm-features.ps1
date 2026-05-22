$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$brainstorm = Join-Path $root 'plugins/compound-engineering/skills/ce-brainstorm/SKILL.md'
$partyMode = Join-Path $root 'plugins/compound-engineering/skills/party-mode/SKILL.md'
$requirements = Join-Path $root 'plugins/compound-engineering/skills/ce-brainstorm/references/requirements-capture.md'

$checks = @(
    @{ Path = $brainstorm; Pattern = '\[P\]'; Label = 'ce-brainstorm documents [P]' },
    @{ Path = $brainstorm; Pattern = '\[P\+\]'; Label = 'ce-brainstorm documents [P+]' },
    @{ Path = $brainstorm; Pattern = 'PARTY_MODE_ENABLED'; Label = 'ce-brainstorm sets PARTY_MODE_ENABLED' },
    @{ Path = $brainstorm; Pattern = 'PARTY_MODE_LEVEL'; Label = 'ce-brainstorm sets PARTY_MODE_LEVEL' },
    @{ Path = $brainstorm; Pattern = 'Skill\("party-mode"\)'; Label = 'ce-brainstorm explicitly invokes party-mode' },
    @{ Path = $brainstorm; Pattern = 'Reuse opportunities'; Label = 'ce-brainstorm requires reuse analysis' },
    @{ Path = $brainstorm; Pattern = 'Glue boundary'; Label = 'ce-brainstorm requires glue boundary analysis' },
    @{ Path = $partyMode; Pattern = 'Reuse Opportunities|复用机会'; Label = 'party-mode exits with reuse opportunities' },
    @{ Path = $partyMode; Pattern = 'Build Boundary|构建边界'; Label = 'party-mode exits with build boundary' },
    @{ Path = $partyMode; Pattern = 'Candidate Priorities|候选优先级'; Label = 'party-mode exits with priorities' },
    @{ Path = $requirements; Pattern = 'P1 .+Must Have'; Label = 'requirements template includes P1' },
    @{ Path = $requirements; Pattern = 'P2 .+Should Have'; Label = 'requirements template includes P2' },
    @{ Path = $requirements; Pattern = 'P3 .+Could Have'; Label = 'requirements template includes P3' },
    @{ Path = $requirements; Pattern = 'P4 .+Later / Parking Lot'; Label = 'requirements template includes P4' },
    @{ Path = $requirements; Pattern = 'Reuse / Build Boundary'; Label = 'requirements template includes reuse/build boundary' }
)

$failed = @()

foreach ($check in $checks) {
    if (-not (Test-Path $check.Path)) {
        $failed += "MISSING FILE: $($check.Path)"
        continue
    }

    $content = Get-Content -Raw -Path $check.Path
    if ($content -notmatch $check.Pattern) {
        $failed += "FAILED: $($check.Label) [$($check.Pattern)] in $($check.Path)"
    } else {
        Write-Host "OK: $($check.Label)"
    }
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Brainstorm feature contract check failed:"
    $failed | ForEach-Object { Write-Host $_ }
    exit 1
}

Write-Host ""
Write-Host "Brainstorm feature contract check passed."
