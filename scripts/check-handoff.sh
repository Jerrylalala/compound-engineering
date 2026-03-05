#!/bin/bash
# 检查 workflow 命令的 Handoff 完整性
# 用法: bash scripts/check-handoff.sh

COMMANDS_DIR="plugins/compound-engineering/commands/workflows"
SKIP_FILES="save.md doctor.md"  # 终端命令，无需 Handoff
ERRORS=0

echo "=== Workflow Handoff 检查 ==="
echo ""

for f in "$COMMANDS_DIR"/*.md; do
  filename=$(basename "$f")

  # 跳过终端命令
  if echo "$SKIP_FILES" | grep -q "$filename"; then
    echo "SKIP: $filename (终端命令)"
    continue
  fi

  # 检查 AskUserQuestion
  if ! grep -q "AskUserQuestion" "$f"; then
    echo "FAIL: $filename - 缺少 AskUserQuestion (无 Handoff)"
    ERRORS=$((ERRORS + 1))
  else
    echo "PASS: $filename"
  fi
done

# 也检查非 workflow 的关键命令
EXTRA_COMMANDS="plugins/compound-engineering/commands/plan_review.md"
for f in $EXTRA_COMMANDS; do
  if [ -f "$f" ]; then
    filename=$(basename "$f")
    if ! grep -q "AskUserQuestion" "$f"; then
      echo "FAIL: $filename - 缺少 AskUserQuestion (无 Handoff)"
      ERRORS=$((ERRORS + 1))
    else
      echo "PASS: $filename"
    fi
  fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "全部通过！所有 workflow 命令都有 Handoff。"
else
  echo "发现 $ERRORS 个命令缺少 Handoff，请修复。"
  exit 1
fi
