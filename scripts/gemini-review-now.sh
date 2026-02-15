#!/bin/bash
# Gemini 智能审核脚本（简化版 - 基于 Gemini 官方建议）
# 用法: ./scripts/gemini-review-now.sh [scope] [timeout_seconds]
# scope: uncommitted (默认), staged, branch, last-commit, all
# timeout_seconds: 超时秒数，默认 300 (5分钟)

set -e

SCOPE=${1:-uncommitted}
TIMEOUT_SECONDS=${2:-300}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="${TEMP:-/tmp}/gemini-review"
OUTPUT_FILE="$OUTPUT_DIR/result-$TIMESTAMP.json"
LOG_FILE="$OUTPUT_DIR/log-$TIMESTAMP.txt"
INPUT_FILE="$OUTPUT_DIR/input-$TIMESTAMP.txt"

mkdir -p "$OUTPUT_DIR"

# 清理函数
cleanup() {
  rm -f "$INPUT_FILE" 2>/dev/null
}
trap cleanup EXIT INT TERM

echo "=== Gemini Code Review ==="
echo "Scope: $SCOPE | Timeout: ${TIMEOUT_SECONDS}s"

# 检查 Gemini CLI
if ! command -v gemini &> /dev/null; then
    echo "❌ Gemini CLI 未安装"
    echo "请运行: npm install -g @google/gemini-cli"
    exit 1
fi

# 检查 Git 仓库
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ 当前目录不是 Git 仓库"
    exit 1
fi

# 验证超时参数
if ! [[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]]; then
    echo "❌ timeout 必须是正整数"
    exit 1
fi

# 获取 diff（不截断 - Gemini 支持 1M+ tokens）
case $SCOPE in
  uncommitted)
    CHANGES=$(git diff --name-only HEAD 2>/dev/null || true)
    DIFF=$(git diff HEAD 2>/dev/null || true)
    ;;
  staged)
    CHANGES=$(git diff --name-only --cached 2>/dev/null || true)
    DIFF=$(git diff --cached 2>/dev/null || true)
    ;;
  branch)
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    CHANGES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || true)
    DIFF=$(git diff "$BASE_BRANCH"...HEAD 2>/dev/null || true)
    ;;
  last-commit)
    # 审核最近一次提交（HEAD~1 到 HEAD 的差异）
    CHANGES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)
    DIFF=$(git diff HEAD~1 HEAD 2>/dev/null || true)
    ;;
  all)
    CHANGES=$(git ls-files --modified --others --exclude-standard 2>/dev/null || true)
    DIFF=$(git diff HEAD 2>/dev/null || true)
    ;;
  *)
    echo "Unknown scope: $SCOPE"
    echo "Usage: $0 [uncommitted|staged|branch|last-commit|all] [timeout_seconds]"
    exit 1
    ;;
esac

if [ -z "$CHANGES" ]; then
  # 智能 fallback：uncommitted 没有更改时自动切换到 last-commit
  if [ "$SCOPE" = "uncommitted" ]; then
    echo "⚠️ 没有未提交的更改，自动切换到 last-commit 模式..."
    echo ""
    SCOPE="last-commit"
    CHANGES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)
    DIFF=$(git diff HEAD~1 HEAD 2>/dev/null || true)

    if [ -z "$CHANGES" ]; then
      echo "✅ No changes to review (including last commit)."
      exit 0
    fi
  else
    echo "✅ No changes to review."
    exit 0
  fi
fi

FILE_COUNT=$(echo "$CHANGES" | wc -l | tr -d ' ')
echo "📁 Files to review: $FILE_COUNT"
echo "$CHANGES" | head -10
[ "$FILE_COUNT" -gt 10 ] && echo "... and $((FILE_COUNT - 10)) more"
echo ""

# 构建输入（Diff + Prompt 组合，通过 stdin 传递 - Gemini 官方推荐方式）
cat > "$INPUT_FILE" << 'PROMPT_END'
You are a senior code reviewer. Review these changes and provide actionable feedback.

## Review Focus
1. **CRITICAL**: Security vulnerabilities, data loss risks, breaking changes
2. **WARNING**: Logic errors, performance issues, race conditions
3. **INFO**: Code style, best practices, documentation

## Output Format
### Summary
[1-2 sentence overview of the changes]

### Findings

#### 🔴 CRITICAL
- [Issue with file:line and explanation]

#### 🟡 WARNING
- [Issue with file:line and explanation]

#### 🔵 INFO
- [Suggestion with file:line]

### Recommendations
1. [Most important action]
2. [Second priority]
3. [Third priority]

## Code Changes to Review
PROMPT_END

echo '```diff' >> "$INPUT_FILE"
echo "$DIFF" >> "$INPUT_FILE"
echo '```' >> "$INPUT_FILE"

echo "🚀 Calling Gemini (--yolo -o json)..."

# 调用 Gemini（使用系统 timeout 命令）
# --yolo: 自动批准所有操作（非交互模式，不需要实验性功能）
# -p "": 使用 stdin 作为 prompt
# -o json: 结构化输出，方便解析
if timeout "$TIMEOUT_SECONDS" bash -c "cat '$INPUT_FILE' | gemini -m gemini-3-pro-preview --yolo -p '' -o json > '$OUTPUT_FILE' 2> '$LOG_FILE'"; then
  EXIT_CODE=$?
  echo ""

  if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "=== ✅ Review Complete ==="
    echo ""

    # 解析 JSON 输出（提取 .response 字段）
    if command -v jq &> /dev/null; then
      RESULT=$(jq -r '.response // .' "$OUTPUT_FILE" 2>/dev/null || cat "$OUTPUT_FILE")
    else
      # 使用 node 解析（通过环境变量传递路径，避免注入风险）
      RESULT=$(OUTPUT_FILE="$OUTPUT_FILE" node -e "
        const fs = require('fs');
        const data = JSON.parse(fs.readFileSync(process.env.OUTPUT_FILE, 'utf8'));
        console.log(data.response || JSON.stringify(data, null, 2));
      " 2>/dev/null || cat "$OUTPUT_FILE")
    fi

    echo "$RESULT"
    echo ""
    echo "---"
    echo "📄 Full output: $OUTPUT_FILE"
    echo "📊 Log file: $LOG_FILE"
  else
    echo "=== ⚠️ Review completed but no output ==="
    [ -f "$LOG_FILE" ] && echo "Log:" && cat "$LOG_FILE"
  fi
else
  EXIT_CODE=$?
  echo ""

  if [ $EXIT_CODE -eq 124 ]; then
    echo "=== ⏱️ Review Timed Out (${TIMEOUT_SECONDS}s) ==="
    echo ""
    echo "可能原因："
    echo "  - 代码量较大，需要更多时间"
    echo "  - 网络问题或 API 响应慢"
    echo ""
    echo "备选方案："
    echo "  1. 增加超时时间: ./scripts/gemini-review-now.sh $SCOPE 600"
    echo "  2. 手动运行: gemini"
  else
    echo "=== ❌ Review Failed (exit code: $EXIT_CODE) ==="
    [ -f "$LOG_FILE" ] && echo "Log:" && tail -10 "$LOG_FILE"
  fi

  exit $EXIT_CODE
fi
