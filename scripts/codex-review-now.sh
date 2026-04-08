#!/bin/bash
# Codex 智能审核脚本（v2 - 使用 codex exec 非交互模式）
# 用法: ./scripts/codex-review-now.sh [scope] [timeout_seconds]
# scope: uncommitted (默认), staged, branch, last-commit, all
# timeout_seconds: 超时秒数，默认 300 (5分钟)

set -e

# 切换到 git 仓库根目录，避免 Windows 工作目录错误（P2-C）
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || true

# 模型配置（支持环境变量覆盖）
CODEX_MODEL="${CODEX_MODEL:-gpt-5.3-codex}"

SCOPE=${1:-uncommitted}
TIMEOUT_SECONDS=${2:-300}

# 验证 TIMEOUT_SECONDS 必须是正整数（P2-G）
if ! [[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || [ "$TIMEOUT_SECONDS" -eq 0 ]; then
  echo "❌ timeout_seconds 必须是正整数，当前值: $TIMEOUT_SECONDS"
  exit 1
fi
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="${TEMP:-/tmp}/codex-review"
OUTPUT_FILE="$OUTPUT_DIR/result-$TIMESTAMP.md"
EVENTS_FILE="$OUTPUT_DIR/events-$TIMESTAMP.jsonl"
PID_FILE="$OUTPUT_DIR/pid-$TIMESTAMP"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo "=== Codex Code Review (v2) ==="
echo "Scope: $SCOPE"
echo "Timeout: ${TIMEOUT_SECONDS}s"
echo "Output: $OUTPUT_FILE"
echo ""

# 检查 codex 是否安装
if ! command -v codex &> /dev/null; then
    echo "❌ Codex CLI 未安装"
    echo "请运行: npm install -g @openai/codex"
    exit 1
fi

# 获取 diff
case $SCOPE in
  uncommitted)
    CHANGES=$(git diff --name-only HEAD 2>/dev/null || true)
    DIFF=$(git diff HEAD 2>/dev/null | head -500 || true)
    ;;
  staged)
    CHANGES=$(git diff --name-only --cached 2>/dev/null || true)
    DIFF=$(git diff --cached 2>/dev/null | head -500 || true)
    ;;
  branch)
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    CHANGES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || true)
    DIFF=$(git diff "$BASE_BRANCH"...HEAD 2>/dev/null | head -500 || true)
    ;;
  last-commit)
    # 审核最近一次提交（HEAD~1 到 HEAD 的差异）
    CHANGES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)
    DIFF=$(git diff HEAD~1 HEAD 2>/dev/null | head -500 || true)
    ;;
  all)
    CHANGES=$(git ls-files --modified --others --exclude-standard 2>/dev/null || true)
    DIFF=$(git diff HEAD 2>/dev/null | head -500 || true)
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
    DIFF=$(git diff HEAD~1 HEAD 2>/dev/null | head -500 || true)

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

# 构建 review prompt
# 用 XML 标签隔离用户可控内容，防止 diff 中的文本被误解为指令（Sec-P1-B）
REVIEW_PROMPT="You are a senior code reviewer. Review these changes and provide actionable feedback.

<files_changed count=\"$FILE_COUNT\">
$CHANGES
</files_changed>

<diff note=\"truncated to 500 lines\">
\`\`\`diff
$DIFF
\`\`\`
</diff>

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
3. [Third priority]"

# 启动 Codex（后台执行，带超时保护）
echo "🚀 Starting Codex review..."
echo "   ⏱️  Timeout: ${TIMEOUT_SECONDS}s"
echo "   📊 Progress: watching JSONL events"
echo ""

# 使用 codex exec 非交互模式
# --json: 输出 JSONL 事件流到 stderr
# --output-last-message: 将最终结果写入文件
# 通过 stdin 传递 prompt（避免超长参数）

# 启动后台进程
(
  printf "%s" "$REVIEW_PROMPT" | \
    codex exec -m "$CODEX_MODEL" --json --output-last-message "$OUTPUT_FILE" - \
    2> "$EVENTS_FILE"
) &
CODEX_PID=$!
echo $CODEX_PID > "$PID_FILE"

echo "   PID: $CODEX_PID"

# 进度监控函数
show_progress() {
  local last_event=""
  local dots=0

  while kill -0 $CODEX_PID 2>/dev/null; do
    if [ -f "$EVENTS_FILE" ]; then
      # 读取最新事件类型
      local current_event=$(tail -1 "$EVENTS_FILE" 2>/dev/null | grep -o '"type":"[^"]*"' | head -1 || true)

      if [ -n "$current_event" ] && [ "$current_event" != "$last_event" ]; then
        last_event="$current_event"
        case "$current_event" in
          *thread.started*) echo "   ✓ Thread started" ;;
          *turn.started*) echo "   ✓ Processing..." ;;
          *agentMessage*)
            dots=$((dots + 1))
            printf "\r   ⏳ Generating%s" "$(printf '.%.0s' $(seq 1 $((dots % 4 + 1))))"
            ;;
          *turn.completed*) echo -e "\n   ✓ Turn completed" ;;
        esac
      fi
    fi
    sleep 2
  done
}

# 超时监控
timeout_monitor() {
  local elapsed=0
  local check_interval=5

  while [ $elapsed -lt $TIMEOUT_SECONDS ]; do
    if ! kill -0 $CODEX_PID 2>/dev/null; then
      return 0  # 进程已结束
    fi
    sleep $check_interval
    elapsed=$((elapsed + check_interval))

    # 每 30 秒输出一次等待提示
    if [ $((elapsed % 30)) -eq 0 ]; then
      echo "   ⏳ Still waiting... (${elapsed}s / ${TIMEOUT_SECONDS}s)"
    fi
  done

  # 超时，终止进程
  echo ""
  echo "⚠️  Timeout reached (${TIMEOUT_SECONDS}s)"
  kill $CODEX_PID 2>/dev/null || true
  return 1
}

# 并行运行进度和超时监控
show_progress &
PROGRESS_PID=$!

if timeout_monitor; then
  # 正常完成
  wait $CODEX_PID
  EXIT_CODE=$?
  kill $PROGRESS_PID 2>/dev/null || true

  echo ""
  if [ $EXIT_CODE -eq 0 ] && [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "=== ✅ Review Complete ==="
    echo ""
    cat "$OUTPUT_FILE"
    echo ""
    echo "---"
    echo "📄 Full output: $OUTPUT_FILE"
    echo "📊 Events log: $EVENTS_FILE"
  else
    echo "=== ⚠️ Review Failed ==="
    echo "Exit code: $EXIT_CODE"
    [ -f "$EVENTS_FILE" ] && echo "Last events:" && tail -5 "$EVENTS_FILE"
  fi
else
  # 超时
  kill $PROGRESS_PID 2>/dev/null || true

  echo "=== ⏱️ Review Timed Out ==="
  echo ""
  echo "Codex 审核超时。可能原因："
  echo "  - 代码量较大，需要更多时间"
  echo "  - 网络问题或 API 响应慢"
  echo ""
  echo "备选方案："
  echo "  1. 增加超时时间重试："
  echo "     ./scripts/codex-review-now.sh $SCOPE 600"
  echo ""
  echo "  2. 手动运行交互式 Codex："
  echo "     codex"
  echo "     > /review"
  echo ""

  # 检查是否有部分输出
  if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "📄 部分输出已保存: $OUTPUT_FILE"
    echo "---"
    cat "$OUTPUT_FILE"
  fi

  if [ -f "$EVENTS_FILE" ]; then
    echo ""
    echo "📊 最后的事件日志:"
    tail -10 "$EVENTS_FILE"
  fi

  exit 124  # 标准超时退出码
fi

# 清理 PID 文件
rm -f "$PID_FILE"
