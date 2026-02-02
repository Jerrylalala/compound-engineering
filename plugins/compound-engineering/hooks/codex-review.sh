#!/bin/bash
# Codex 自动审核脚本
# 在 Claude Code 完成工作后自动触发
# 支持：已跟踪文件更改 + 未跟踪新文件

# 读取 hook 输入
INPUT=$(cat)

# 解析 stop_hook_active（优先用 jq，fallback 用 grep）
if command -v jq &> /dev/null; then
  STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
else
  # jq 未安装，使用 grep 简单匹配
  if echo "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    STOP_HOOK_ACTIVE="true"
  else
    STOP_HOOK_ACTIVE="false"
  fi
fi

# 如果已经是 stop hook 触发的，跳过避免无限循环
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# 检查是否有未提交的更改（包括未跟踪文件）
CHANGES=$(git status --porcelain 2>/dev/null)
if [ -z "$CHANGES" ]; then
  echo '{"systemMessage": "No uncommitted changes to review."}'
  exit 0
fi

# 获取已跟踪文件的更改
TRACKED_FILES=$(git diff --name-only HEAD 2>/dev/null | head -10)
DIFF_SUMMARY=$(git diff --stat HEAD 2>/dev/null | tail -1)

# 获取未跟踪的新文件
UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null | head -10)

# 合并文件列表
CHANGED_FILES="$TRACKED_FILES"
if [ -n "$UNTRACKED_FILES" ]; then
  if [ -n "$CHANGED_FILES" ]; then
    CHANGED_FILES="$CHANGED_FILES
[Untracked new files:]
$UNTRACKED_FILES"
  else
    CHANGED_FILES="[Untracked new files:]
$UNTRACKED_FILES"
  fi
fi

# 构建审核提示
REVIEW_PROMPT="Review the following uncommitted changes for this Claude Code plugin project:

Files changed:
$CHANGED_FILES

Summary: $DIFF_SUMMARY

Focus on:
1. Bugs and logic errors
2. Security vulnerabilities
3. Code style and best practices
4. Documentation accuracy
5. Workflow command consistency

Provide a concise structured report with severity levels (CRITICAL/WARNING/INFO)."

# 调用 Codex 进行审核（使用 review 子命令，非交互式）
echo "Starting Codex review..." >&2
OUTPUT_FILE="${TEMP:-/tmp}/codex-review-output.txt"
codex review --uncommitted --title "Auto-review on Stop" > "$OUTPUT_FILE" 2>&1 &

# 返回状态消息
echo "{\"systemMessage\": \"Codex review started in background. Check $OUTPUT_FILE for results.\"}"
