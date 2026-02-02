#!/usr/bin/env bash
# Session start hook - 注入技能检查协议
# 在每次会话开始时提醒 AI 检查是否有适用的技能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

cat "$SCRIPT_DIR/skill-checking-protocol.md"
