#!/bin/bash
# 跨平台包装脚本：自动选择正确的 Codex 审核脚本
# 在 Windows 上使用 PowerShell，其他系统使用 Bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# 检测操作系统
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
  # Windows 环境：检查是否有 PowerShell
  if command -v pwsh &> /dev/null; then
    # 使用 PowerShell Core
    pwsh -File "$SCRIPT_DIR/codex-review.ps1"
  elif command -v powershell &> /dev/null; then
    # 使用 Windows PowerShell
    powershell -ExecutionPolicy Bypass -File "$SCRIPT_DIR/codex-review.ps1"
  else
    # 回退到 Bash 脚本
    bash "$SCRIPT_DIR/codex-review.sh"
  fi
else
  # Unix/Linux/macOS：使用 Bash 脚本
  bash "$SCRIPT_DIR/codex-review.sh"
fi
