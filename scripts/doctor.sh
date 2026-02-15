#!/bin/bash
# /doctor 健康检查脚本
# 用法: bash scripts/doctor.sh [--smoke]
# 检测 Codex/Gemini CLI 安装状态、模型版本、认证配置
# 可选 --smoke 参数启用冒烟测试

set -o pipefail

# ── 配置 ──────────────────────────────────────────────
CODEX_MODEL="${CODEX_MODEL:-gpt-5.3-codex}"
GEMINI_MODEL="${GEMINI_MODEL:-gemini-3-pro-preview}"
SMOKE_TIMEOUT=30
SMOKE=false

# 解析参数
for arg in "$@"; do
  case "$arg" in
    --smoke) SMOKE=true ;;
    *) echo "未知参数: $arg"; echo "用法: bash scripts/doctor.sh [--smoke]"; exit 1 ;;
  esac
done

# ── 状态计数 ─────────────────────────────────────────
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# 结果收集（用于汇总表格）
declare -a RESULTS=()
declare -a ACTIONS=()

status_icon() {
  case "$1" in
    PASS) echo "PASS" ;;
    WARN) echo "WARN" ;;
    FAIL) echo "FAIL" ;;
  esac
}

record() {
  # record STATUS CHECK DETAIL
  local status="$1" check="$2" detail="$3"
  RESULTS+=("$status|$check|$detail")
  case "$status" in
    PASS) ((PASS_COUNT++)) ;;
    WARN) ((WARN_COUNT++)) ;;
    FAIL) ((FAIL_COUNT++)) ;;
  esac
}

action() {
  ACTIONS+=("$1")
}

# ── Step 1: Codex CLI 安装检测 ───────────────────────
echo "=== Compound Engineering Doctor ==="
echo ""
echo "[1/7] 检测 Codex CLI..."

CODEX_PATH=$(command -v codex 2>/dev/null || true)
if [ -n "$CODEX_PATH" ]; then
  CODEX_VERSION=$(codex --version 2>/dev/null || echo "unknown")
  record "PASS" "Codex CLI" "已安装 ($CODEX_VERSION) @ $CODEX_PATH"
else
  record "FAIL" "Codex CLI" "未安装"
  action "安装 Codex: npm install -g @openai/codex"
fi

# ── Step 2: Gemini CLI 安装检测 ──────────────────────
echo "[2/7] 检测 Gemini CLI..."

GEMINI_PATH=$(command -v gemini 2>/dev/null || true)
if [ -n "$GEMINI_PATH" ]; then
  GEMINI_VERSION=$(gemini --version 2>/dev/null || echo "unknown")
  record "PASS" "Gemini CLI" "已安装 ($GEMINI_VERSION) @ $GEMINI_PATH"
else
  record "FAIL" "Gemini CLI" "未安装"
  action "安装 Gemini: npm install -g @anthropic-ai/gemini-cli 或参考 Google 官方文档"
fi

# ── Step 3: Codex 模型检测 ───────────────────────────
echo "[3/7] 检测 Codex 模型配置..."

CODEX_CONFIG="$HOME/.codex/config.toml"
if [ -f "$CODEX_CONFIG" ]; then
  CONFIGURED_MODEL=$(grep -E '^model\s*=' "$CODEX_CONFIG" 2>/dev/null | sed 's/.*=\s*["'\'']\?\([^"'\'']*\)["'\'']\?/\1/' | tr -d ' ' || true)
  if [ -n "$CONFIGURED_MODEL" ]; then
    if [ "$CONFIGURED_MODEL" = "$CODEX_MODEL" ]; then
      record "PASS" "Codex 模型" "$CONFIGURED_MODEL (最新)"
    else
      record "WARN" "Codex 模型" "配置: $CONFIGURED_MODEL, 推荐: $CODEX_MODEL"
      action "更新 Codex 模型: 编辑 $CODEX_CONFIG 设置 model = \"$CODEX_MODEL\""
    fi
  else
    record "WARN" "Codex 模型" "配置文件中未指定 model，将使用默认值"
  fi
else
  if [ -n "$CODEX_PATH" ]; then
    record "WARN" "Codex 模型" "配置文件不存在 ($CODEX_CONFIG)，将使用默认模型"
    action "运行 codex 进行首次配置以生成 $CODEX_CONFIG"
  else
    record "FAIL" "Codex 模型" "Codex 未安装，跳过模型检测"
  fi
fi

# ── Step 4: Gemini 认证检测 ──────────────────────────
echo "[4/7] 检测 Gemini 认证..."

GEMINI_SETTINGS="$HOME/.gemini/settings.json"
if [ -f "$GEMINI_SETTINGS" ]; then
  record "PASS" "Gemini 认证" "配置文件存在 ($GEMINI_SETTINGS)"
else
  if [ -n "$GEMINI_PATH" ]; then
    # 检查是否有 API key 环境变量
    if [ -n "$GEMINI_API_KEY" ] || [ -n "$GOOGLE_API_KEY" ]; then
      record "PASS" "Gemini 认证" "通过环境变量配置"
    else
      record "WARN" "Gemini 认证" "配置文件不存在，可能需要登录"
      action "运行 gemini 进行首次登录"
    fi
  else
    record "FAIL" "Gemini 认证" "Gemini 未安装，跳过认证检测"
  fi
fi

# ── Step 5: Codex 冒烟测试 ───────────────────────────
if [ "$SMOKE" = true ]; then
  echo "[5/7] Codex 冒烟测试..."
  if [ -n "$CODEX_PATH" ]; then
    SMOKE_TMP="${TEMP:-/tmp}/doctor-codex-smoke-$$.md"
    if timeout "$SMOKE_TIMEOUT" bash -c "echo 'Respond with exactly: OK' | codex exec -m $CODEX_MODEL --output-last-message \"$SMOKE_TMP\" -" 2>/dev/null; then
      SMOKE_RESULT=$(cat "$SMOKE_TMP" 2>/dev/null || true)
      if echo "$SMOKE_RESULT" | grep -qi "OK"; then
        record "PASS" "Codex 冒烟测试" "响应正常"
      else
        record "WARN" "Codex 冒烟测试" "响应异常: $(echo "$SMOKE_RESULT" | head -c 100)"
      fi
    else
      record "FAIL" "Codex 冒烟测试" "超时或执行失败 (${SMOKE_TIMEOUT}s)"
      action "检查 Codex 认证和网络连接"
    fi
    rm -f "$SMOKE_TMP"
  else
    record "FAIL" "Codex 冒烟测试" "Codex 未安装，跳过"
  fi
else
  echo "[5/7] Codex 冒烟测试... 跳过 (使用 --smoke 启用)"
  record "WARN" "Codex 冒烟测试" "跳过 (使用 --smoke 启用)"
fi

# ── Step 6: Gemini 冒烟测试 ──────────────────────────
if [ "$SMOKE" = true ]; then
  echo "[6/7] Gemini 冒烟测试..."
  if [ -n "$GEMINI_PATH" ]; then
    GEMINI_SMOKE_RESULT=""
    if GEMINI_SMOKE_RESULT=$(timeout "$SMOKE_TIMEOUT" gemini -m "$GEMINI_MODEL" -p "Respond with exactly: OK" 2>/dev/null); then
      if echo "$GEMINI_SMOKE_RESULT" | grep -qi "OK"; then
        record "PASS" "Gemini 冒烟测试" "响应正常"
      else
        record "WARN" "Gemini 冒烟测试" "响应异常: $(echo "$GEMINI_SMOKE_RESULT" | head -c 100)"
      fi
    else
      record "FAIL" "Gemini 冒烟测试" "超时或执行失败 (${SMOKE_TIMEOUT}s)"
      action "检查 Gemini 认证和网络连接"
    fi
  else
    record "FAIL" "Gemini 冒烟测试" "Gemini 未安装，跳过"
  fi
else
  echo "[6/7] Gemini 冒烟测试... 跳过 (使用 --smoke 启用)"
  record "WARN" "Gemini 冒烟测试" "跳过 (使用 --smoke 启用)"
fi

# ── Step 7: 汇总报告 ────────────────────────────────
echo "[7/7] 生成报告..."
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║         Compound Engineering Health Report          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
printf "%-6s %-20s %s\n" "状态" "检查项" "详情"
printf "%-6s %-20s %s\n" "------" "--------------------" "----------------------------------------"

for result in "${RESULTS[@]}"; do
  IFS='|' read -r status check detail <<< "$result"
  printf "%-6s %-20s %s\n" "$status" "$check" "$detail"
done

echo ""
echo "── 汇总 ──"
echo "PASS: $PASS_COUNT  WARN: $WARN_COUNT  FAIL: $FAIL_COUNT"

if [ ${#ACTIONS[@]} -gt 0 ]; then
  echo ""
  echo "── 修复建议 ──"
  for i in "${!ACTIONS[@]}"; do
    echo "  $((i+1)). ${ACTIONS[$i]}"
  done
fi

echo ""

# ── 退出码 ───────────────────────────────────────────
if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "结果: 有 $FAIL_COUNT 项失败，需要修复"
  exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
  echo "结果: 有 $WARN_COUNT 项警告，建议检查"
  exit 2
else
  echo "结果: 全部通过"
  exit 0
fi
