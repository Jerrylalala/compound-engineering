$ErrorActionPreference = 'Stop'

function Write-Heading([string]$text) {
  Write-Host ("=`" * 60)
  Write-Host $text
  Write-Host ("=`" * 60)
}

Write-Heading "Sync upstream"

git fetch upstream

git checkout main

git merge upstream/main

# Check for merge conflicts
$conflicts = git diff --name-only --diff-filter=U
if ($conflicts) {
  Write-Host "Merge conflicts detected:" -ForegroundColor Yellow
  $conflicts | ForEach-Object { Write-Host " - $_" }

  Write-Host "\nConflict summaries:" -ForegroundColor Yellow
  foreach ($file in $conflicts) {
    Write-Host "\n--- $file ---" -ForegroundColor Yellow
    $start = 1
    $end = 200
    $content = Get-Content $file -ErrorAction SilentlyContinue
    if ($content) {
      $slice = $content[$start-1..([Math]::Min($end-1, $content.Length-1))]
      $slice | Select-String -Pattern '<<<<<<<|=======|>>>>>>>' | ForEach-Object { Write-Host $_.Line }
    }
  }

  throw "Resolve conflicts then rerun the script."
}

Write-Heading "Push to origin"

git push origin main

Write-Heading "Install dependencies"

$bun = Join-Path $HOME '.bun\bin\bun.exe'
if (-not (Test-Path $bun)) {
  throw "bun not found at $bun. Please install bun first."
}

& $bun install

Write-Heading "Install plugin to Codex"

& $bun run src/index.ts install ./plugins/compound-engineering --to codex

$hash = git rev-parse HEAD
Write-Heading "Done"
Write-Host "Sync complete. Current commit: $hash"
