#!/bin/bash
# /doctor 健康检查与自动配置脚本
# 用法: bash scripts/doctor.sh [--fix] [--smoke]
# 检测 CLI 工具、MCP 服务器、认证状态，支持一键修复
# --fix   自动安装缺失的必需项
# --smoke 启用冒烟测试

set -o pipefail

# ── 配置 ──────────────────────────────────────────────
CODEX_MODEL="${CODEX_MODEL:-gpt-5.3-codex}"
GEMINI_MODEL="${GEMINI_MODEL:-gemini-3-pro-preview}"
SMOKE_TIMEOUT=30
SMOKE=false
FIX=false

# 解析参数
for arg in "$@"; do
  case "$arg" in
    --smoke) SMOKE=true ;;
    --fix) FIX=true ;;
    *) echo "未知参数: $arg"; echo "用法: bash scripts/doctor.sh [--fix] [--smoke]"; exit 1 ;;
  esac
done

# ── 总步数计算 ────────────────────────────────────────
TOTAL_STEPS=10

# ── 状态计数 ─────────────────────────────────────────
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
FIX_COUNT=0

# 结果收集（用于汇总表格）
declare -a RESULTS=()
declare -a ACTIONS=()
declare -a FIXED=()

status_icon() {
  case "$1" in
    PASS) echo "PASS" ;;
    WARN) echo "WARN" ;;
    FAIL) echo "FAIL" ;;
    FIXD) echo "FIXD" ;;
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
    FIXD) ((FIX_COUNT++)) ;;
  esac
}

action() {
  ACTIONS+=("$1")
}

fixed() {
  FIXED+=("$1")
}

# ── Step 1: Codex CLI 安装检测 ───────────────────────
echo "=== Compound Engineering Doctor ==="
if [ "$FIX" = true ]; then
  echo "    模式: 自动修复 (--fix)"
fi
echo ""
echo "[1/$TOTAL_STEPS] 检测 Codex CLI..."

CODEX_PATH=$(command -v codex 2>/dev/null || true)
if [ -n "$CODEX_PATH" ]; then
  CODEX_VERSION=$(codex --version 2>/dev/null || echo "unknown")
  record "PASS" "Codex CLI" "已安装 ($CODEX_VERSION) @ $CODEX_PATH"
else
  if [ "$FIX" = true ]; then
    echo "  → 安装 Codex CLI..."
    if npm install -g @openai/codex 2>&1; then
      CODEX_PATH=$(command -v codex 2>/dev/null || true)
      CODEX_VERSION=$(codex --version 2>/dev/null || echo "unknown")
      record "FIXD" "Codex CLI" "已自动安装 ($CODEX_VERSION)"
      fixed "Codex CLI 已安装"
    else
      record "FAIL" "Codex CLI" "自动安装失败"
      action "手动安装 Codex: npm install -g @openai/codex"
    fi
  else
    record "FAIL" "Codex CLI" "未安装"
    action "安装 Codex: npm install -g @openai/codex"
  fi
fi

# ── Step 2: Gemini CLI 安装检测 ──────────────────────
echo "[2/$TOTAL_STEPS] 检测 Gemini CLI..."

GEMINI_PATH=$(command -v gemini 2>/dev/null || true)
if [ -n "$GEMINI_PATH" ]; then
  GEMINI_VERSION=$(gemini --version 2>/dev/null || echo "unknown")
  record "PASS" "Gemini CLI" "已安装 ($GEMINI_VERSION) @ $GEMINI_PATH"
else
  if [ "$FIX" = true ]; then
    echo "  → 安装 Gemini CLI..."
    if npm install -g @anthropic-ai/gemini-cli 2>&1; then
      GEMINI_PATH=$(command -v gemini 2>/dev/null || true)
      GEMINI_VERSION=$(gemini --version 2>/dev/null || echo "unknown")
      record "FIXD" "Gemini CLI" "已自动安装 ($GEMINI_VERSION)"
      fixed "Gemini CLI 已安装"
    else
      record "FAIL" "Gemini CLI" "自动安装失败"
      action "手动安装 Gemini: npm install -g @anthropic-ai/gemini-cli 或参考 Google 官方文档"
    fi
  else
    record "FAIL" "Gemini CLI" "未安装"
    action "安装 Gemini: npm install -g @anthropic-ai/gemini-cli 或参考 Google 官方文档"
  fi
fi

# ── Step 3: Codex 模型检测 ───────────────────────────
echo "[3/$TOTAL_STEPS] 检测 Codex 模型配置..."

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
echo "[4/$TOTAL_STEPS] 检测 Gemini 认证..."

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

# ── Step 5: GitHub MCP 检测 ──────────────────────────
echo "[5/$TOTAL_STEPS] 检测 GitHub MCP..."

CLAUDE_CONFIG="$HOME/.claude.json"
HAS_GITHUB_MCP="unknown"

if [ -f "$CLAUDE_CONFIG" ]; then
  if command -v node >/dev/null 2>&1; then
    HAS_GITHUB_MCP=$(node -e "
      try {
        const path=require('path');
        const configPath=path.join(require('os').homedir(),'.claude.json');
        const d=JSON.parse(require('fs').readFileSync(configPath,'utf8'));
        // 检查全局
        if(d.mcpServers&&d.mcpServers.github) { console.log('global'); process.exit(0); }
        // 检查所有项目
        if(d.projects) {
          for(const [k,v] of Object.entries(d.projects)) {
            if(v.mcpServers&&v.mcpServers.github) { console.log('project:'+k); process.exit(0); }
          }
        }
        console.log('none');
      } catch(e) { console.log('error'); }
    " 2>/dev/null || echo "error")
  else
    # 无 node，尝试 grep 简单检测
    if grep -q '"github"' "$CLAUDE_CONFIG" 2>/dev/null; then
      HAS_GITHUB_MCP="detected"
    else
      HAS_GITHUB_MCP="none"
    fi
  fi
else
  HAS_GITHUB_MCP="no_config"
fi

case "$HAS_GITHUB_MCP" in
  global)
    record "PASS" "GitHub MCP" "已配置（全局）"
    ;;
  project:*)
    record "PASS" "GitHub MCP" "已配置（项目级: ${HAS_GITHUB_MCP#project:}）"
    ;;
  detected)
    record "PASS" "GitHub MCP" "已配置（检测到）"
    ;;
  none|no_config)
    if [ "$FIX" = true ]; then
      echo "  → 安装 GitHub MCP..."
      if CLAUDECODE= claude mcp add --transport http github https://api.githubcopilot.com/mcp/ 2>&1; then
        record "FIXD" "GitHub MCP" "已自动配置"
        fixed "GitHub MCP 已添加（需重启 Claude Code 生效）"
      else
        record "FAIL" "GitHub MCP" "自动配置失败"
        action "手动添加: CLAUDECODE= claude mcp add --transport http github https://api.githubcopilot.com/mcp/"
      fi
    else
      record "WARN" "GitHub MCP" "未配置"
      action "添加 GitHub MCP: CLAUDECODE= claude mcp add --transport http github https://api.githubcopilot.com/mcp/"
    fi
    ;;
  *)
    record "WARN" "GitHub MCP" "检测失败 ($HAS_GITHUB_MCP)"
    ;;
esac

# ── Step 6: Context7 MCP 检测 ────────────────────────
echo "[6/$TOTAL_STEPS] 检测 Context7 MCP..."

# Context7 由插件 plugin.json 中的 mcpServers 配置，随插件自动加载
# 这里仅验证插件配置是否正确
PLUGIN_JSON=""
# 尝试查找 plugin.json（相对于脚本位置）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_JSON_PATH="$SCRIPT_DIR/../plugins/compound-engineering/.claude-plugin/plugin.json"

if [ -f "$PLUGIN_JSON_PATH" ]; then
  if grep -q '"context7"' "$PLUGIN_JSON_PATH" 2>/dev/null; then
    record "PASS" "Context7 MCP" "已在 plugin.json 中配置（随插件自动加载）"
  else
    record "WARN" "Context7 MCP" "plugin.json 中未找到 context7 配置"
    action "检查 plugin.json 中的 mcpServers.context7 配置"
  fi
else
  record "WARN" "Context7 MCP" "无法定位 plugin.json"
fi

# ── Step 7: agent-browser（可选）──────────────────────
echo "[7/$TOTAL_STEPS] 检测 agent-browser（可选）..."

AGENT_BROWSER_PATH=$(command -v agent-browser 2>/dev/null || true)
if [ -n "$AGENT_BROWSER_PATH" ]; then
  record "PASS" "agent-browser" "已安装 @ $AGENT_BROWSER_PATH"
else
  record "WARN" "agent-browser" "未安装（可选，用于浏览器自动化）"
  action "安装 agent-browser（可选）: npm install -g agent-browser"
fi

# ── Step 8: Codex 冒烟测试 ───────────────────────────
if [ "$SMOKE" = true ]; then
  echo "[8/$TOTAL_STEPS] Codex 冒烟测试..."
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
  echo "[8/$TOTAL_STEPS] Codex 冒烟测试... 跳过 (使用 --smoke 启用)"
  record "WARN" "Codex 冒烟测试" "跳过 (使用 --smoke 启用)"
fi

# ── Step 9: Gemini 冒烟测试 ──────────────────────────
if [ "$SMOKE" = true ]; then
  echo "[9/$TOTAL_STEPS] Gemini 冒烟测试..."
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
  echo "[9/$TOTAL_STEPS] Gemini 冒烟测试... 跳过 (使用 --smoke 启用)"
  record "WARN" "Gemini 冒烟测试" "跳过 (使用 --smoke 启用)"
fi

# ── Step 10: 汇总报告 ────────────────────────────────
echo "[10/$TOTAL_STEPS] 生成报告..."
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
echo "PASS: $PASS_COUNT  WARN: $WARN_COUNT  FAIL: $FAIL_COUNT  FIXD: $FIX_COUNT"

if [ ${#FIXED[@]} -gt 0 ]; then
  echo ""
  echo "── 已自动修复 ──"
  for i in "${!FIXED[@]}"; do
    echo "  $((i+1)). ${FIXED[$i]}"
  done
fi

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
  if [ "$FIX" != true ]; then
    echo "提示: 使用 --fix 参数可自动修复部分问题"
  fi
  exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
  echo "结果: 有 $WARN_COUNT 项警告，建议检查"
  exit 2
elif [ "$FIX_COUNT" -gt 0 ]; then
  echo "结果: 已自动修复 $FIX_COUNT 项，请重启 Claude Code 以加载新配置"
  exit 0
else
  echo "结果: 全部通过"
  exit 0
fi
