---
title: "feat: Workflow Handoff 合规修复"
type: feat
date: 2026-03-05
brainstorm: docs/brainstorms/2026-03-05-handoff-compliance-fix-brainstorm.md
---

# feat: Workflow Handoff 合规修复

## Overview

修复 7 个 workflow 命令的 Handoff 协议合规问题，建立协议分级制度（主链档 vs 工具档），增强 lint 脚本。

## Problem Statement

在 v2.42.4 建立 Handoff 协议（6 条规则）后，全面审查发现仅 2/9 命令完全合规（work.md、compound.md），7 个存在不同程度问题：
- 4 个缺少 `Based on selection:` 行为约束
- 4 个英文描述未改中文
- 3 个第一选项不是流程下一步命令

## Proposed Solution

协议分级 + 全面修复：

| 档位 | 适用命令 | 规则要求 |
|------|----------|----------|
| **主链档** | brainstorm, plan, work, review, compound | 6 条全满足 |
| **工具档** | load, sync-upstream, deepen-plan, plan_review | 至少满足规则 2/4/5 |

## Acceptance Criteria

- [x] brainstorm.md 补 `Based on selection:` + 中文化
- [x] plan.md 重排选项 + 补停止选项 + 中文化 + 改标题
- [x] review.md 补 `Based on selection:`
- [x] load.md 合并两个 Handoff 为统一出口
- [x] sync-upstream.md 补 `Based on selection:`
- [x] deepen-plan.md 重排选项 + 补停止选项 + 中文化
- [x] check-handoff.sh 增加检查 `Based on selection`
- [x] CLAUDE.md 更新协议加入分级制度
- [x] 版本号更新 + CHANGELOG

## Tasks

### Task 1: 修复 brainstorm.md Handoff（主链档）

**文件**: `plugins/compound-engineering/commands/workflows/brainstorm.md:284-293`
**操作**:
- [ ] 替换 Phase 4: Handoff 部分，补 `Based on selection:` + 中文化

**代码**:
```markdown
### Phase 4: Handoff

Use **AskUserQuestion tool** to present next steps:

**Question:** "头脑风暴已记录。下一步？"

**Options:**
1. **进入规划** - 运行 `/workflows:plan`（将自动检测此 brainstorm）（推荐）
2. **继续探索** - 继续细化设计
3. **停止** - 稍后再继续

Based on selection:
- **进入规划** → 调用 `/workflows:plan`
- **继续探索** → 回到 Phase 1 或 Phase 2 继续对话
- **停止** → 结束流程
```

**验证**:
- [ ] 确认包含 `Based on selection:`
- [ ] 确认选项描述为中文

---

### Task 2: 修复 plan.md Post-Generation Options（主链档）

**文件**: `plugins/compound-engineering/commands/workflows/plan.md:555-582`
**操作**:
- [ ] 将 "Post-Generation Options" 改为 "Handoff"
- [ ] 重排选项：`/workflows:work` 放第一位
- [ ] 补"停止"选项
- [ ] 中文化所有描述
- [ ] 更新 Based on selection 对应映射

**代码**:
```markdown
## Handoff

After writing the plan file, use the **AskUserQuestion tool** to present these options:

**Question:** "计划已生成至 `docs/plans/YYYY-MM-DD-<type>-<name>-plan.md`。下一步？"

**Options:**
1. **执行 `/workflows:work`** - 开始实现（1任务=标准模式，≥2任务=自动Subagent模式）（推荐）
2. **运行 `/plan_review`** - 多代理审查计划
3. **运行 `/deepen-plan`** - 用研究代理增强各节
4. **在编辑器中打开** - 打开计划文件查看
5. **远程执行 `/workflows:work`** - 在 Claude Code Web 后台执行（使用 `&`）
6. **创建 Issue** - 在项目追踪器中创建（GitHub/Linear）
7. **简化** - 降低细节层级
8. **停止** - 不执行，稍后处理

Based on selection:
- **执行 `/workflows:work`** → 调用 `/workflows:work docs/plans/<plan_filename>.md`（自动检测：1任务=标准模式，≥2任务=Subagent模式）
- **运行 `/plan_review`** → 调用 `/plan_review <plan_path>`
- **运行 `/deepen-plan`** → 调用 `/deepen-plan <plan_path>`
- **在编辑器中打开** → 运行 `open docs/plans/<plan_filename>.md`
- **远程执行** → 运行 `/workflows:work docs/plans/<plan_filename>.md &`
- **创建 Issue** → 见下方 "Issue Creation" 部分
- **简化** → 询问 "需要简化哪些部分？" 然后重新生成
- **停止** → 结束流程

**Note:** If running `/workflows:plan` with ultrathink enabled, automatically run `/deepen-plan` after plan creation for maximum depth and grounding.

Loop back to options after 简化 or Other changes until user selects `/workflows:work` or `/plan_review`.
```

**验证**:
- [ ] 确认标题为 "## Handoff"
- [ ] 确认第一选项为 `/workflows:work`
- [ ] 确认包含"停止"选项
- [ ] 确认所有描述为中文

---

### Task 3: 修复 review.md Handoff（主链档）

**文件**: `plugins/compound-engineering/commands/workflows/review.md:471-481`
**操作**:
- [ ] 在现有 3 个选项后补 `Based on selection:` 行为约束

**代码**（在选项 3 之后追加）:
```markdown
Based on selection:
- **记录解决方案** → 调用 `/workflows:compound`
- **保存上下文** → 调用 `/workflows:save`
- **完成** → 结束流程
```

**验证**:
- [ ] 确认 review.md 包含 `Based on selection:`

---

### Task 4: 修复 load.md Handoff（工具档）

**文件**: `plugins/compound-engineering/commands/workflows/load.md:100-133`
**操作**:
- [ ] 合并"未完成计划检测"和"原有选项流程"为统一出口
- [ ] 补 `Based on selection:` 行为约束
- [ ] 中文化选项描述

**代码**（替换现有的两段 Handoff）:
```markdown
### Handoff

恢复上下文后，自动扫描是否有未完成的计划：

```bash
ls -la docs/plans/*.md 2>/dev/null | head -10
```

对每个计划文件，检查是否有未完成任务（`- [ ]`）且在 30 天内修改。

使用 **AskUserQuestion tool** 呈现选项（根据扫描结果动态调整）：

**Question:** "上下文已恢复。下一步？"

**Options:**
1. **继续执行未完成计划** - 运行 `/workflows:work <plan_path>`（推荐，仅在发现未完成计划时显示）
2. **查看计划详情** - 先查看计划内容再决定（仅在发现未完成计划时显示）
3. **开始新任务** - 从头开始新工作
4. **查看详细进展** - 查看恢复的上下文详情
5. **停止** - 不执行任何操作

Based on selection:
- **继续执行** → 调用 `/workflows:work <plan_path>`
- **查看计划** → 读取并展示计划文件，然后重新呈现选项
- **开始新任务** → 询问用户想做什么
- **查看详细进展** → 展示恢复的上下文摘要
- **停止** → 结束流程
```

**验证**:
- [ ] 确认只有一个统一 Handoff 出口
- [ ] 确认包含 `Based on selection:`
- [ ] 确认包含"停止"选项

---

### Task 5: 修复 sync-upstream.md Handoff（工具档）

**文件**: `plugins/compound-engineering/commands/workflows/sync-upstream.md:298-315`
**操作**:
- [ ] 在现有 4 个选项后补 `Based on selection:` 行为约束

**代码**（在选项 4 之后追加）:
```markdown
Based on selection:
- **逐项讨论** → 依次展示高相关变更，逐个评估
- **创建整合计划** → 调用 `/workflows:plan`
- **执行上游合并** → 执行 `git merge upstream/main --squash`
- **稍后处理** → 结束流程
```

**验证**:
- [ ] 确认 sync-upstream.md 包含 `Based on selection:`

---

### Task 6: 修复 deepen-plan.md Handoff（工具档）

**文件**: `plugins/compound-engineering/commands/deepen-plan.md:475-493`
**操作**:
- [ ] 重排选项（`/plan_review` 第一）
- [ ] 补"停止"选项
- [ ] 中文化所有描述
- [ ] 更新 Based on selection 映射

**代码**:
```markdown
## Post-Enhancement Options

After writing the enhanced plan, use the **AskUserQuestion tool** to present these options:

**Question:** "计划已深化完成。下一步？"

**Options:**
1. **运行 `/plan_review`** - 多代理审查增强后的计划（推荐）
2. **执行 `/workflows:work`** - 开始实现此增强计划
3. **查看变更** - 显示增强前后差异
4. **继续深化** - 对特定章节再做一轮研究
5. **还原** - 恢复原始计划（如有备份）
6. **停止** - 不执行，稍后处理

Based on selection:
- **运行 `/plan_review`** → 调用 `/plan_review <plan_path>`
- **执行 `/workflows:work`** → 调用 `/workflows:work <plan_path>`
- **查看变更** → 运行 `git diff <plan_path>` 或显示前后对比
- **继续深化** → 询问需要深化哪些章节，重新运行研究代理
- **还原** → 从 git 或备份恢复
- **停止** → 结束流程
```

**验证**:
- [ ] 确认第一选项为 `/plan_review`
- [ ] 确认包含"停止"选项
- [ ] 确认所有描述为中文

---

### Task 7: 增强 check-handoff.sh

**文件**: `scripts/check-handoff.sh`
**操作**:
- [ ] 增加检查 `Based on selection` 关键词
- [ ] 分级输出（主链档 vs 工具档）

**代码**:
```bash
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

  # 跳过终端命令
  if echo "$SKIP_FILES" | grep -q "$filename"; then
    echo "SKIP: $filename (终端命令)"
    continue
  fi

  # 判断档位
  if echo "$MAIN_CHAIN" | grep -q "$filename"; then
    tier="主链档"
  else
    tier="工具档"
  fi

  # 检查 AskUserQuestion
  if ! grep -q "AskUserQuestion" "$f"; then
    echo "FAIL: $filename [$tier] - 缺少 AskUserQuestion (无 Handoff)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # 检查 Based on selection
  if ! grep -q "Based on selection" "$f"; then
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
```

**验证**:
- [ ] 运行 `bash scripts/check-handoff.sh` 修复前应报告多个 FAIL
- [ ] 修复后应全部 PASS

---

### Task 8: 更新 CLAUDE.md Handoff 协议（加入分级制度）

**文件**: `plugins/compound-engineering/CLAUDE.md:140-171`
**操作**:
- [ ] 在现有 Handoff 协议部分加入分级制度说明

**代码**（替换现有的 `### Workflow Handoff 协议（铁律）` 整个部分）:
```markdown
### Workflow Handoff 协议（铁律）

所有 `commands/workflows/*.md` 命令必须遵循（终端命令 save/doctor 除外）。

#### 协议分级

| 档位 | 适用命令 | 规则要求 |
|------|----------|----------|
| **主链档** | brainstorm, plan, work, review, compound | 6 条全满足 |
| **工具档** | load, sync-upstream, deepen-plan, plan_review | 至少满足规则 2/4/5 |

#### 6 条规则

1. 命令的最后一个 Phase 必须是 Handoff（主链档严格，工具档宽松）
2. Handoff 必须使用 **AskUserQuestion tool** 呈现选项 ✅ 必须
3. 第一个选项必须是流程中的下一步命令（含完整参数如文件路径）（主链档严格，工具档宽松）
4. 必须有"跳过/停止"选项 ✅ 必须
5. Handoff 后需 `Based on selection:` 内嵌行为约束（禁止 AI 在选项外自由发挥）✅ 必须
6. 选项描述使用中文，命令名保持英文（主链档严格，工具档宽松）

**流程链路**：
```
brainstorm → plan → [deepen-plan] → [plan_review] → work → review → [compound] → save
```

**快速验证**：
```bash
bash scripts/check-handoff.sh
```

**检查清单**（新增/修改 workflow 命令时验证）：
- [ ] 最后一个 Phase 是否为 Handoff？
- [ ] 是否使用 AskUserQuestion？
- [ ] 第一个选项是否为流程中的下一步命令 + 完整路径？
- [ ] 是否有"停止"选项？
- [ ] 是否有 `Based on selection:` 行为约束？
- [ ] 描述语言是否为中文？
```

**验证**:
- [ ] 确认包含"协议分级"表格
- [ ] 确认包含主链档/工具档区分

---

### Task 9: 更新版本号和 CHANGELOG

**文件**: `.claude-plugin/marketplace.json`, `plugins/compound-engineering/.claude-plugin/plugin.json`, `plugins/compound-engineering/CHANGELOG.md`
**操作**:
- [ ] 使用 `powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch` 更新版本号
- [ ] 在 CHANGELOG.md 添加版本记录

**验证**:
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致
- [ ] CHANGELOG.md 包含新版本条目

---

### Task 10: 运行 Handoff lint 最终验证

**操作**:
- [ ] 运行 `bash scripts/check-handoff.sh` 确认所有命令通过
- [ ] 逐一检查每个修改的文件

**验证**:
- [ ] lint 脚本输出"全部通过"
- [ ] 无 FAIL

## References

- Brainstorm: `docs/brainstorms/2026-03-05-handoff-compliance-fix-brainstorm.md`
- 前一轮改动: v2.42.4（branch `feat/workflow-handoff-improvement`）
- Handoff 协议: `plugins/compound-engineering/CLAUDE.md:140`
- lint 脚本: `scripts/check-handoff.sh`
