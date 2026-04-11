#!/bin/bash
# 功能完整性校验脚本
# 三项检查：参数声明一致性 + 引用文件存在性 + 行数骤降检测
# 用法：bash scripts/check-feature-integrity.sh
# CI / pre-commit hook 调用，非 0 退出码 = 有问题

set -euo pipefail

SKILLS_DIR="plugins/compound-engineering/skills"
ERRORS=0
WARNINGS=0

echo "========================================"
echo "  功能完整性校验"
echo "========================================"
echo ""

# ──────────────────────────────────────────
# 检查 1：参数声明 → 实现关键词一致性
# ──────────────────────────────────────────
echo "--- 检查 1：参数声明-实现一致性 ---"

# 参数标记 → 实现关键词映射（匹配任一即通过）
declare -A PARAM_KEYWORDS=(
  ["[C]"]="CODEX_ENABLED,codex exec,codex"
  ["[G]"]="GEMINI_ENABLED,gemini"
  ["[P]"]="party-mode,PARTY_MODE,Party Mode,派对模式"
  ["[P+]"]="party-mode,P_PLUS,全量,12-14"
  ["[R]"]="learnings-researcher,R_MODE"
  ["[V]"]="V_MODE_ENABLED,verification,验证"
  ["[V+]"]="V_PLUS_MODE_ENABLED,Playwright"
  ["[T]"]="team-mode,TeamCreate,TEAM_MODE"
  ["[T+]"]="risk-guard,T_PLUS"
)

# 只检查 ce-* 开头的 skill（本地维护的），排除上游 skill
for skill_file in $(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL.md" -path "*/ce-*/*" 2>/dev/null); do
  skill_name=$(basename "$(dirname "$skill_file")")
  arg_hint=$(grep -m1 "argument-hint:" "$skill_file" 2>/dev/null || true)
  if [ -z "$arg_hint" ]; then
    continue
  fi

  for param in "${!PARAM_KEYWORDS[@]}"; do
    if echo "$arg_hint" | grep -qF "$param"; then
      keywords="${PARAM_KEYWORDS[$param]}"
      found=false
      IFS=',' read -ra kw_array <<< "$keywords"
      for kw in "${kw_array[@]}"; do
        kw=$(echo "$kw" | xargs)
        if grep -q "$kw" "$skill_file" 2>/dev/null; then
          found=true
          break
        fi
      done

      if [ "$found" = false ]; then
        echo "  [ERROR] $skill_name: 声明了 $param 但未找到实现 ($keywords)"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done
done

if [ "$ERRORS" -eq 0 ]; then
  echo "  ✅ 参数声明-实现一致性通过"
fi
echo ""

# ──────────────────────────────────────────
# 检查 2：引用文件存在性
# ──────────────────────────────────────────
echo "--- 检查 2：引用文件存在性 ---"

# 只检查 ce-* 开头的 skill（本地维护的）
for skill_dir in $(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL.md" -path "*/ce-*/*" -exec dirname {} \; 2>/dev/null); do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"

  # 提取 references/ 引用（匹配 references/*.md 或 references/*-*.md 格式）
  refs=$(grep -oE 'references/[a-zA-Z0-9_-]+\.md' "$skill_file" 2>/dev/null | sort -u || true)
  for ref in $refs; do
    ref_path="$skill_dir/$ref"
    if [ ! -f "$ref_path" ]; then
      echo "  [ERROR] $skill_name: 引用了 $ref 但文件不存在"
      ERRORS=$((ERRORS + 1))
    fi
  done
done

if [ "$ERRORS" -eq 0 ]; then
  echo "  ✅ 引用文件存在性通过"
fi
echo ""

# ──────────────────────────────────────────
# 检查 3：SKILL.md 行数骤降检测（对比上次提交）
# ──────────────────────────────────────────
echo "--- 检查 3：行数变化检测 ---"

changed_skills=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep "SKILL.md" || true)
if [ -z "$changed_skills" ]; then
  echo "  ⏭ 本次无 SKILL.md 变更，跳过"
else
  for skill_file in $changed_skills; do
    if [ -f "$skill_file" ]; then
      old_lines=$(git show HEAD~1:"$skill_file" 2>/dev/null | wc -l || echo 0)
      new_lines=$(wc -l < "$skill_file")
      if [ "$old_lines" -gt 0 ]; then
        drop=$(( (old_lines - new_lines) * 100 / old_lines ))
        if [ "$drop" -gt 30 ]; then
          echo "  [WARN] $skill_file: 行数从 $old_lines 降至 $new_lines（降幅 ${drop}%）"
          WARNINGS=$((WARNINGS + 1))
        fi
      fi
    fi
  done
  if [ "$WARNINGS" -eq 0 ]; then
    echo "  ✅ 行数变化正常"
  fi
fi
echo ""

# ──────────────────────────────────────────
# 检查 4：组件数量校验
# ──────────────────────────────────────────
echo "--- 检查 4：组件数量一致性 ---"

PLUGIN_JSON="plugins/compound-engineering/.claude-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ]; then
  PLUGIN_DESC=$(grep '"description"' "$PLUGIN_JSON" 2>/dev/null || true)

  # 统计实际文件数
  ACTUAL_AGENTS=$(find plugins/compound-engineering/agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  ACTUAL_COMMANDS=$(find plugins/compound-engineering/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  ACTUAL_SKILLS=$(find plugins/compound-engineering/skills -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  ACTUAL_CUSTOM=$(find plugins/compound-engineering/skills-custom -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')

  # 从 description 提取声明数
  DECLARED_AGENTS=$(echo "$PLUGIN_DESC" | grep -oP '\d+(?= agents)' || echo "?")
  DECLARED_COMMANDS=$(echo "$PLUGIN_DESC" | grep -oP '\d+(?= commands)' || echo "?")
  DECLARED_SKILLS=$(echo "$PLUGIN_DESC" | grep -oP '\d+(?= skills)' || echo "?")
  DECLARED_CUSTOM=$(echo "$PLUGIN_DESC" | grep -oP '\d+(?= custom)' || echo "?")

  COUNT_OK=true
  if [ "$DECLARED_AGENTS" != "?" ] && [ "$DECLARED_AGENTS" != "$ACTUAL_AGENTS" ]; then
    echo "  [ERROR] agents: 声明 $DECLARED_AGENTS, 实际 $ACTUAL_AGENTS"
    ERRORS=$((ERRORS + 1)); COUNT_OK=false
  fi
  if [ "$DECLARED_COMMANDS" != "?" ] && [ "$DECLARED_COMMANDS" != "$ACTUAL_COMMANDS" ]; then
    echo "  [ERROR] commands: 声明 $DECLARED_COMMANDS, 实际 $ACTUAL_COMMANDS"
    ERRORS=$((ERRORS + 1)); COUNT_OK=false
  fi
  if [ "$DECLARED_SKILLS" != "?" ] && [ "$DECLARED_SKILLS" != "$ACTUAL_SKILLS" ]; then
    echo "  [ERROR] skills: 声明 $DECLARED_SKILLS, 实际 $ACTUAL_SKILLS"
    ERRORS=$((ERRORS + 1)); COUNT_OK=false
  fi
  if [ "$DECLARED_CUSTOM" != "?" ] && [ "$DECLARED_CUSTOM" != "$ACTUAL_CUSTOM" ]; then
    echo "  [ERROR] custom overlays: 声明 $DECLARED_CUSTOM, 实际 $ACTUAL_CUSTOM"
    ERRORS=$((ERRORS + 1)); COUNT_OK=false
  fi

  if [ "$COUNT_OK" = true ]; then
    echo "  ✅ 组件数量一致 (agents=$ACTUAL_AGENTS, commands=$ACTUAL_COMMANDS, skills=$ACTUAL_SKILLS, custom=$ACTUAL_CUSTOM)"
  fi
else
  echo "  ⏭ 未找到 $PLUGIN_JSON，跳过"
fi
echo ""

# ──────────────────────────────────────────
# 检查 5：规范 URL 校验
# ──────────────────────────────────────────
echo "--- 检查 5：规范 URL 校验 ---"

URL_OK=true
for url_file in "$PLUGIN_JSON" ".claude-plugin/marketplace.json" "package.json"; do
  if [ -f "$url_file" ]; then
    if grep -q "compound-engineering-plugin-private" "$url_file" 2>/dev/null; then
      echo "  [ERROR] $url_file: 仍引用旧仓库名 compound-engineering-plugin-private"
      ERRORS=$((ERRORS + 1)); URL_OK=false
    fi
  fi
done

if [ "$URL_OK" = true ]; then
  echo "  ✅ 规范 URL 校验通过"
fi
echo ""

# ──────────────────────────────────────────
# 检查 6：旧命令名校验
# ──────────────────────────────────────────
echo "--- 检查 6：旧命令名校验 ---"

OLD_CMD_OK=true
OLD_CMDS=$(grep -rl "/workflows:brainstorm\|/workflows:plan\|/workflows:work\|/workflows:review\|/workflows:compound\|/workflows:sync-upstream\|/workflows:load\|/workflows:save" docs/zh-CN/ README.zh-CN.md README*.md 2>/dev/null --include="*.md" | grep -v "plans/\|solutions/\|sync-reports/" || true)

if [ -n "$OLD_CMDS" ]; then
  for f in $OLD_CMDS; do
    echo "  [ERROR] $f: 仍包含旧命令名 /workflows:*"
    ERRORS=$((ERRORS + 1)); OLD_CMD_OK=false
  done
fi

if [ "$OLD_CMD_OK" = true ]; then
  echo "  ✅ 旧命令名校验通过"
fi
echo ""

# ──────────────────────────────────────────
# 汇总
# ──────────────────────────────────────────
echo "========================================"
if [ "$ERRORS" -gt 0 ]; then
  echo "  ❌ 发现 $ERRORS 个错误，$WARNINGS 个警告"
  echo "========================================"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  echo "  ⚠️ 无错误，$WARNINGS 个警告"
  echo "========================================"
  exit 0
else
  echo "  ✅ 所有检查通过"
  echo "========================================"
  exit 0
fi
