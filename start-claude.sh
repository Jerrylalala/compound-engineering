#!/bin/bash
# 跨平台启动脚本 - 支持 Windows (Git Bash/WSL) 和 macOS/Linux

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_PATH="$SCRIPT_DIR/plugins/compound-engineering"

# 检测操作系统
case "$(uname -s)" in
    Darwin)
        echo "检测到 macOS"
        ;;
    Linux)
        echo "检测到 Linux"
        # 检查是否在 WSL 中
        if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
            echo "(WSL 环境)"
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "检测到 Windows (Git Bash/MSYS)"
        # 转换路径格式为 Windows 格式
        PLUGIN_PATH=$(cygpath -w "$PLUGIN_PATH" 2>/dev/null || echo "$PLUGIN_PATH")
        ;;
    *)
        echo "未知系统: $(uname -s)"
        ;;
esac

echo "插件路径: $PLUGIN_PATH"
echo "启动 Claude Code..."
echo ""

claude --plugin-dir "$PLUGIN_PATH"
