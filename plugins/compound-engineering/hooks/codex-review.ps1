# Codex 自动审核脚本 (Windows PowerShell 版本)
# 在 Claude Code 完成工作后自动触发
# 支持：已跟踪文件更改 + 未跟踪新文件

param(
    [Parameter(ValueFromPipeline=$true)]
    [string]$InputJson
)

# 解析输入
try {
    $hookInput = $InputJson | ConvertFrom-Json
    $stopHookActive = $hookInput.stop_hook_active
} catch {
    $stopHookActive = $false
}

# 如果已经是 stop hook 触发的，跳过避免无限循环
if ($stopHookActive -eq $true) {
    exit 0
}

# 检查是否有未提交的更改（包括未跟踪文件）
$changes = git status --porcelain 2>$null
if ([string]::IsNullOrEmpty($changes)) {
    Write-Output '{"systemMessage": "No uncommitted changes to review."}'
    exit 0
}

# 获取已跟踪文件的更改
$trackedFiles = (git diff --name-only HEAD 2>$null | Select-Object -First 10) -join "`n"
$diffSummary = (git diff --stat HEAD 2>$null | Select-Object -Last 1)

# 获取未跟踪的新文件
$untrackedFiles = (git ls-files --others --exclude-standard 2>$null | Select-Object -First 10) -join "`n"

# 合并文件列表
$changedFiles = $trackedFiles
if (-not [string]::IsNullOrEmpty($untrackedFiles)) {
    if (-not [string]::IsNullOrEmpty($changedFiles)) {
        $changedFiles = "$changedFiles`n[Untracked new files:]`n$untrackedFiles"
    } else {
        $changedFiles = "[Untracked new files:]`n$untrackedFiles"
    }
}

# 调用 Codex 进行审核（使用 review 子命令，非交互式）
Write-Host "Starting Codex review..." -ForegroundColor Yellow
$outputFile = "$env:TEMP\codex-review-output.txt"
Start-Job -ScriptBlock {
    param($outFile)
    codex review --uncommitted --title "Auto-review on Stop" 2>&1 | Out-File -FilePath $outFile
} -ArgumentList $outputFile | Out-Null

# 返回状态消息
Write-Output "{`"systemMessage`": `"Codex review started in background. Check $outputFile for results.`"}"
