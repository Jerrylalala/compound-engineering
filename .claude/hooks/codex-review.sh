#!/bin/bash
# Codex 自动审核脚本
# 在 Claude Code 完成工作后自动触发

# 读取 hook 输入
INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# 如果已经是 stop hook 触发的，跳过避免无限循环
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# 检查是否有未提交的更改
CHANGES=$(git status --porcelain 2>/dev/null)
if [ -z "$CHANGES" ]; then
  echo '{"systemMessage": "No uncommitted changes to review."}'
  exit 0
fi

# 获取更改摘要
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null | head -10)
DIFF_SUMMARY=$(git diff --stat HEAD 2>/dev/null | tail -1)

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

# 调用 Codex 进行审核（异步，不阻塞）
echo "Starting Codex review..." >&2
codex "$REVIEW_PROMPT" 2>&1 | tee /tmp/codex-review-output.txt &

# 返回状态消息
echo '{"systemMessage": "Codex review started in background. Check /tmp/codex-review-output.txt for results."}'
