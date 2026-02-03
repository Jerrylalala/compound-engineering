# sync-to-targets.ps1
# 将本地插件同步安装到 Codex 和 Gemini CLI
# 用法: powershell -ExecutionPolicy Bypass -File scripts/sync-to-targets.ps1

param(
    [string]$GeminiHome = "$env:USERPROFILE",  # Gemini 输出目录（会创建 .gemini 子目录）
    [switch]$CodexOnly,                         # 只安装到 Codex
    [switch]$GeminiOnly,                        # 只安装到 Gemini
    [switch]$Verbose                            # 显示详细输出
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$PluginPath = Join-Path $ProjectRoot "plugins\compound-engineering"

Write-Host "=== 插件同步工具 ===" -ForegroundColor Cyan
Write-Host "插件路径: $PluginPath"
Write-Host ""

# 检查 bun 是否可用
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    Write-Host "错误: 未找到 bun，请先安装 bun" -ForegroundColor Red
    exit 1
}

# 构建命令参数
$targets = @()
if (-not $GeminiOnly) { $targets += "codex" }
if (-not $CodexOnly) { $targets += "gemini" }

if ($targets.Count -eq 0) {
    Write-Host "错误: 至少需要一个目标 (--codex 或 --gemini)" -ForegroundColor Red
    exit 1
}

# 执行安装
foreach ($target in $targets) {
    Write-Host "正在安装到 $target..." -ForegroundColor Yellow

    $args = @("run", "src/index.ts", "install", $PluginPath, "--to", $target)

    if ($target -eq "gemini") {
        $args += "--gemini-home"
        $args += $GeminiHome
    }

    if ($Verbose) {
        Write-Host "执行: bun $($args -join ' ')" -ForegroundColor Gray
    }

    Push-Location $ProjectRoot
    try {
        & bun @args
        if ($LASTEXITCODE -ne 0) {
            Write-Host "安装到 $target 失败" -ForegroundColor Red
            exit 1
        }
    } finally {
        Pop-Location
    }

    Write-Host "✓ 已安装到 $target" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== 同步完成 ===" -ForegroundColor Cyan

# 显示安装位置
if ($targets -contains "codex") {
    $codexPath = Join-Path $env:USERPROFILE ".codex"
    Write-Host "Codex: $codexPath" -ForegroundColor Gray
}
if ($targets -contains "gemini") {
    $geminiPath = Join-Path $GeminiHome ".gemini"
    Write-Host "Gemini: $geminiPath" -ForegroundColor Gray
}
