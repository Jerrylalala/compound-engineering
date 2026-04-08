#!/bin/bash
# 检查 workflow 命令的 Handoff 完整性
# 用法: bash scripts/check-handoff.sh

COMMANDS_DIR="plugins/compound-engineering/commands/workflows"
SKIP_FILES="save.md doctor.md"  # 终端命令，无需 Handoff
MAIN_CHAIN="brainstorm.md plan.md work.md review.md compound.md"  # 主链档：6 条全满足
ERRORS=0

echo "=== Workflow Handoff 检查 ==="
echo ""

for f in "$COMMANDS_DIR"/*.md; do
  filename=$(basename "$f")

  # 跳过终端命令（-qF 使用字面匹配，防止文件名被当作正则）
  if echo "$SKIP_FILES" | grep -qF "$filename"; then
    echo "SKIP: $filename (终端命令)"
    continue
  fi

  # 判断档位
  if echo "$MAIN_CHAIN" | grep -qF "$filename"; then
    tier="主链档"
  else
    tier="工具档"
  fi

  # 检查 AskUserQuestion
  if ! grep -qF "AskUserQuestion" "$f"; then
    echo "FAIL: $filename [$tier] - 缺少 AskUserQuestion (无 Handoff)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # 检查 Based on selection
  if ! grep -qF "Based on selection" "$f"; then
    echo "FAIL: $filename [$tier] - 缺少 Based on selection (无行为约束)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  echo "PASS: $filename [$tier]"
done

# 也检查非 workflow 的关键命令
EXTRA_COMMANDS="plugins/compound-engineering/commands/plan_review.md plugins/compound-engineering/commands/deepen-plan.md"
for f in $EXTRA_COMMANDS; do
  if [ -f "$f" ]; then
    filename=$(basename "$f")
    has_ask=$(grep -c "AskUserQuestion" "$f" || true)
    has_based=$(grep -c "Based on selection" "$f" || true)

    if [ "$has_ask" -eq 0 ]; then
      echo "FAIL: $filename [工具档] - 缺少 AskUserQuestion"
      ERRORS=$((ERRORS + 1))
    elif [ "$has_based" -eq 0 ]; then
      echo "FAIL: $filename [工具档] - 缺少 Based on selection"
      ERRORS=$((ERRORS + 1))
    else
      echo "PASS: $filename [工具档]"
    fi
  fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "全部通过！所有 workflow 命令都有完整 Handoff。"
else
  echo "发现 $ERRORS 个命令 Handoff 不完整，请修复。"
  exit 1
fi
