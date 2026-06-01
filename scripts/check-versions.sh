#!/bin/bash
# 版本一致性检查脚本 (Bash 版本)
# 用法: bash scripts/check-versions.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }

echo -e "\n${CYAN}========================================"
echo "  版本一致性检查"
echo -e "========================================${NC}\n"

HAS_ERROR=false

# 定义文件路径
MARKETPLACE_FILE=".claude-plugin/marketplace.json"
PLUGIN_FILE="plugins/compound-engineering/.claude-plugin/plugin.json"

# 1. 检查文件存在性
info "检查文件存在性..."
for file in "$MARKETPLACE_FILE" "$PLUGIN_FILE"; do
    if [ ! -f "$file" ]; then
        error "文件不存在: $file"
        HAS_ERROR=true
    fi
done

if [ "$HAS_ERROR" = true ]; then
    echo -e "\n${RED}检查失败: 缺少必要文件${NC}"
    exit 1
fi

# 2. 读取版本号 (需要 jq)
info "读取版本号..."
if ! command -v jq &> /dev/null; then
    warn "jq 未安装，跳过 JSON 解析检查"
    echo "  安装 jq: brew install jq (macOS) / apt install jq (Linux)"
    exit 0
fi

PLUGIN_VERSION=$(jq -r '.version // "null"' "$PLUGIN_FILE")

if [ "$PLUGIN_VERSION" = "null" ]; then
    error "版本字段缺失: plugin=$PLUGIN_VERSION"
    exit 1
fi

echo "  plugin.json: $PLUGIN_VERSION"
success "版本来源 (plugin.json): $PLUGIN_VERSION"

# 3. 校验版本号格式
info "校验版本号格式..."
if [[ "$PLUGIN_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    success "版本号格式正确: $PLUGIN_VERSION"
else
    error "版本号格式错误: $PLUGIN_VERSION (期望 x.y.z)"
    HAS_ERROR=true
fi

# 4. 检查身份信息
echo ""
info "检查身份信息..."

EXPECTED_OWNER="Jerrylalala"

MARKETPLACE_OWNER_URL=$(jq -r '.owner.url' "$MARKETPLACE_FILE")
PLUGIN_HOMEPAGE=$(jq -r '.homepage' "$PLUGIN_FILE")
PLUGIN_REPOSITORY=$(jq -r '.repository' "$PLUGIN_FILE")

if [[ "$MARKETPLACE_OWNER_URL" != *"$EXPECTED_OWNER"* ]]; then
    error "marketplace.json owner.url 未包含 $EXPECTED_OWNER"
    echo -e "  ${YELLOW}当前值: $MARKETPLACE_OWNER_URL${NC}"
    HAS_ERROR=true
else
    success "marketplace.json owner.url 正确"
fi

if [[ "$PLUGIN_HOMEPAGE" != *"$EXPECTED_OWNER"* ]]; then
    error "plugin.json homepage 未包含 $EXPECTED_OWNER"
    echo -e "  ${YELLOW}当前值: $PLUGIN_HOMEPAGE${NC}"
    HAS_ERROR=true
else
    success "plugin.json homepage 正确"
fi

if [[ "$PLUGIN_REPOSITORY" != *"$EXPECTED_OWNER"* ]]; then
    error "plugin.json repository 未包含 $EXPECTED_OWNER"
    echo -e "  ${YELLOW}当前值: $PLUGIN_REPOSITORY${NC}"
    HAS_ERROR=true
else
    success "plugin.json repository 正确"
fi

# 5. 检查组件数量
echo ""
info "检查组件数量..."

AGENT_COUNT=$(find plugins/compound-engineering/agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
COMMAND_COUNT=$(find plugins/compound-engineering/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$(find plugins/compound-engineering/skills -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$((SKILL_COUNT - 1)) # 减去 skills 目录本身

echo "  实际统计: Agents=$AGENT_COUNT, Commands=$COMMAND_COUNT, Skills=$SKILL_COUNT"

# 6. 输出结果
echo -e "\n${CYAN}========================================"
if [ "$HAS_ERROR" = true ]; then
    echo -e "  ${RED}检查失败 - 请修复上述问题${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    exit 1
else
    echo -e "  ${GREEN}所有检查通过${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    exit 0
fi
