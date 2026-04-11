#!/bin/bash
# 功能完整性校验脚本
# 检测 SKILL.md 中声明的参数是否有对应实现
# 用法：bash scripts/check-feature-integrity.sh

set -euo pipefail

SKILLS_DIR="plugins/compound-engineering/skills"
ERRORS=0
WARNINGS=0

echo "========================================"
echo "  功能完整性校验"
echo "========================================"
echo ""

# 参数声明 → 实现关键词映射
# 格式：参数标记|实现关键词（用逗号分隔多个，匹配任一即通过）
declare -A PARAM_KEYWORDS=(
  ["[C]"]="CODEX_ENABLED,codex exec,codex"
  ["[G]"]="GEMINI_ENABLED,gemini"
  ["[P]"]="party-mode,PARTY_MODE,Party Mode"
  ["[R]"]="learnings-researcher,R_MODE"
  ["[V]"]="V_MODE_ENABLED,verification"
  ["[V+]"]="V_PLUS_MODE_ENABLED,Playwright"
  ["[T]"]="team-mode,TeamCreate,TEAM_MODE"
  ["[T+]"]="risk-guard,T_PLUS"
)

# 扫描所有 SKILL.md
for skill_file in $(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null); do
  skill_name=$(basename "$(dirname "$skill_file")")

  # 从 argument-hint 提取声明的参数
  arg_hint=$(grep -m1 "argument-hint:" "$skill_file" 2>/dev/null || true)
  if [ -z "$arg_hint" ]; then
    continue
  fi

  for param in "${!PARAM_KEYWORDS[@]}"; do
    # 检查 argument-hint 是否声明了该参数
    if echo "$arg_hint" | grep -qF "$param"; then
      # 检查文件正文是否包含实现关键词
      keywords="${PARAM_KEYWORDS[$param]}"
      found=false
      IFS=',' read -ra kw_array <<< "$keywords"
      for kw in "${kw_array[@]}"; do
        kw=$(echo "$kw" | xargs)  # trim whitespace
        if grep -q "$kw" "$skill_file" 2>/dev/null; then
          found=true
          break
        fi
      done

      if [ "$found" = false ]; then
        echo "[ERROR] $skill_name: 声明了 $param 但未找到实现关键词 ($keywords)"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done
done

echo ""

# SKILL.md 行数骤降检测（对比 HEAD~ 和 HEAD）
echo "--- 行数变化检测 ---"
for skill_file in $(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep "SKILL.md" || true); do
  if [ -f "$skill_file" ]; then
    old_lines=$(git show HEAD~1:"$skill_file" 2>/dev/null | wc -l || echo 0)
    new_lines=$(wc -l < "$skill_file")
    if [ "$old_lines" -gt 0 ]; then
      drop=$(( (old_lines - new_lines) * 100 / old_lines ))
      if [ "$drop" -gt 30 ]; then
        echo "[WARN] $skill_file: 行数从 $old_lines 降至 $new_lines（降幅 ${drop}%，超过 30% 阈值）"
        WARNINGS=$((WARNINGS + 1))
      fi
    fi
  fi
done

echo ""
echo "========================================"
if [ "$ERRORS" -gt 0 ]; then
  echo "  ❌ 发现 $ERRORS 个功能缺失，$WARNINGS 个警告"
  echo "========================================"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  echo "  ⚠️ 无功能缺失，$WARNINGS 个警告"
  echo "========================================"
  exit 0
else
  echo "  ✅ 所有功能完整"
  echo "========================================"
  exit 0
fi
