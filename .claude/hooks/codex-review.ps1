# Codex 自动审核脚本 (Windows PowerShell 版本)
# 在 Claude Code 完成工作后自动触发

param(
    [Parameter(ValueFromPipeline=$true)]
    [string]$InputJson
)

# 解析输入
try {
    $input = $InputJson | ConvertFrom-Json
    $stopHookActive = $input.stop_hook_active
} catch {
    $stopHookActive = $false
}

# 如果已经是 stop hook 触发的，跳过避免无限循环
if ($stopHookActive -eq $true) {
    exit 0
}

# 检查是否有未提交的更改
$changes = git status --porcelain 2>$null
if ([string]::IsNullOrEmpty($changes)) {
    Write-Output '{"systemMessage": "No uncommitted changes to review."}'
    exit 0
}

# 获取更改摘要
$changedFiles = (git diff --name-only HEAD 2>$null | Select-Object -First 10) -join "`n"
$diffSummary = (git diff --stat HEAD 2>$null | Select-Object -Last 1)

# 构建审核提示
$reviewPrompt = @"
Review the following uncommitted changes for this Claude Code plugin project:

Files changed:
$changedFiles

Summary: $diffSummary

Focus on:
1. Bugs and logic errors
2. Security vulnerabilities
3. Code style and best practices
4. Documentation accuracy
5. Workflow command consistency

Provide a concise structured report with severity levels (CRITICAL/WARNING/INFO).
"@

# 调用 Codex 进行审核（异步）
Write-Host "Starting Codex review..." -ForegroundColor Yellow
Start-Job -ScriptBlock {
    param($prompt)
    codex $prompt 2>&1 | Out-File -FilePath "$env:TEMP\codex-review-output.txt"
} -ArgumentList $reviewPrompt | Out-Null

# 返回状态消息
Write-Output '{"systemMessage": "Codex review started in background. Check %TEMP%\codex-review-output.txt for results."}'
