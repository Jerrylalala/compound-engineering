---
title: "feat: 改进工作流命令衔接机制"
type: feat
date: 2026-03-05
brainstorm: docs/brainstorms/2026-03-05-workflow-handoff-improvement-brainstorm.md
---

# feat: 改进工作流命令衔接机制

## Overview

修补工作流命令链（brainstorm → plan → work → review → compound → save）中的 6 个衔接断裂点，建立统一的 Handoff 协议，防止 AI 跳过关键步骤（特别是 `/workflows:work` 的 Subagent 并行模式）。

## Problem Statement

用户在 `/workflows:plan` → `/plan_review` → 确认"开始实现"后，AI 直接在主对话中串行写代码，跳过了 `/workflows:work`，导致丢失了 Subagent 并行模式、两阶段审查、分支安全检查等保障。

根因：`plan_review` 命令仅 8 行，无 Post-Completion 选项，审查完后 AI 进入"自由状态"。

## Proposed Solution

三层防御 + 命令级约束（详见 brainstorm 文档）：

| 层级 | 机制 |
|------|------|
| Layer 1 | 修补所有断裂点 + 命令级约束 |
| Layer 2 | 统一 Handoff 协议（plugin CLAUDE.md） |
| Layer 3 | work 空参数回退（扫描 docs/plans/） |

## Acceptance Criteria

- [ ] plan_review 审查完成后展示 AskUserQuestion 选项，引导到 /workflows:work
- [ ] plan 选项 4 显式传递 plan 文件路径给 /workflows:work
- [ ] work 在 $ARGUMENTS 为空时自动扫描 docs/plans/ 查找未完成计划
- [ ] work 完成后展示 Handoff 选项引导到 /workflows:review
- [ ] review Next Steps 包含 /workflows:compound 和 /workflows:save
- [ ] compound "Continue workflow" 改为显式的 /workflows:save
- [ ] plugin CLAUDE.md 包含 Handoff 协议规范
- [ ] lint 脚本可检测缺失 AskUserQuestion 的 workflow 命令
- [ ] load 恢复后检测未完成计划并建议继续
- [ ] 所有 Handoff 选项使用中文描述，命令名保持英文

## Tasks

### Task 1: 扩展 plan_review.md — 增加 Post-Review Options（P0）

**文件**: `plugins/compound-engineering/commands/plan_review.md`
**操作**:
- [x] 在第 7 行（Have @agent... review...）之后添加完整的 Post-Review Actions 部分

**代码**:
```markdown
Have @agent-dhh-rails-reviewer @agent-kieran-rails-reviewer @agent-code-simplicity-reviewer review this plan in parallel.

## Post-Review Actions

审查代理完成后，整合并展示所有审查意见摘要。

然后使用 **AskUserQuestion tool** 呈现选项：

**Question:** "计划审查完成。下一步？"

**Options:**
1. **更新计划后执行** - 根据审查意见修改计划，然后运行 `/workflows:work`（推荐）
2. **直接执行 `/workflows:work`** - 按原计划开始实现
3. **仅更新计划** - 修改计划但暂不执行
4. **重新审查** - 重新运行 `/plan_review`
5. **停止** - 不执行，稍后处理

Based on selection:
- **更新计划后执行** → 根据审查意见修改 plan 文件，修改完成后自动调用 `/workflows:work <plan_path>`
- **直接执行** → 直接调用 `/workflows:work <plan_path>`
- **仅更新计划** → 修改 plan 文件后回到选项菜单
- **重新审查** → 重新调用 `/plan_review <plan_path>`
- **停止** → 结束流程

⚠️ **约束**：选择"更新计划后执行"或"直接执行"时，必须通过 `/workflows:work <plan_path>` 执行计划，不得在主对话中直接编写代码实现计划中的任务。这确保 ≥2 任务时自动启用 Subagent 并行模式。

**注意**：`<plan_path>` 应从调用 `/plan_review` 时传入的参数中获取。如果参数为空，扫描 `docs/plans/*.md` 获取最近修改的计划文件。
```

**验证**:
- [ ] 确认文件包含 `AskUserQuestion` 关键词
- [ ] 确认包含 `⚠️ **约束**` 部分
- [ ] 确认包含 5 个选项

---

### Task 2: 修复 plan.md 选项 4 — 显式传递文件路径（P1）

**文件**: `plugins/compound-engineering/commands/workflows/plan.md:574`
**操作**:
- [x] 将选项 4 的执行映射改为显式传递 plan 文件路径

**代码**:
```markdown
# 旧（第 574 行）:
- **`/workflows:work`** → Call the /workflows:work command (自动检测：1任务=标准模式，≥2任务=Subagent模式)

# 新:
- **`/workflows:work`** → Call `/workflows:work docs/plans/<plan_filename>.md`（自动检测：1任务=标准模式，≥2任务=Subagent模式）
```

**验证**:
- [ ] 确认第 574 行包含 `docs/plans/<plan_filename>.md`

---

### Task 3: work.md 增加空参数回退逻辑（P1）

**文件**: `plugins/compound-engineering/commands/workflows/work.md:19`
**操作**:
- [x] 在第 19 行 `<input_document>` 之后、第 21 行 `## Execution Mode Detection` 之前，插入空参数处理逻辑

**代码**:
```markdown
<input_document> #$ARGUMENTS </input_document>

**如果输入文档为空或不是有效文件路径，自动扫描最近的计划文件：**

```
判断逻辑:

1. 如果 $ARGUMENTS 非空且是一个存在的文件路径:
   → 使用该文件作为输入文档

2. 如果 $ARGUMENTS 非空但不是有效文件路径:
   → 当作功能描述，提示用户："这似乎不是文件路径。要运行 /workflows:plan 创建计划，还是指定计划文件？"

3. 如果 $ARGUMENTS 为空:
   → 自动扫描 docs/plans/*.md，按修改时间排序
   → 筛选包含未完成任务（含 - [ ]）且在 30 天内修改的文件
   → 如果唯一匹配 → 提示确认："发现未完成计划 <filename>，N 个任务中完成了 M 个。是否继续？"
   → 如果多个匹配 → 使用 AskUserQuestion 让用户选择
   → 如果无匹配 → 使用 AskUserQuestion 提示：
     选项:
     1. 运行 /workflows:plan 创建新计划（推荐）
     2. 指定计划文件路径
     3. 直接描述要做的工作
```

Do not proceed until you have a valid input document.
```

**验证**:
- [ ] 确认第 19 行之后包含 `docs/plans/*.md` 扫描逻辑
- [ ] 确认包含 30 天窗口限制
- [ ] 确认包含"非文件路径"的判断分支

---

### Task 4: work.md 增加 Phase 5 Handoff（P1）

**文件**: `plugins/compound-engineering/commands/workflows/work.md:473`
**操作**:
- [x] 在第 473 行（Documentation Reminder 末尾）和第 475 行（`---` 分隔线）之间插入 Phase 5 Handoff

**代码**:
```markdown
### Phase 5: Handoff

Use **AskUserQuestion tool** to present next steps:

**Question:** "功能已完成并创建了 PR。下一步？"

**Options:**
1. **运行 `/workflows:review`** - 多代理代码审查（推荐）
2. **运行 `/workflows:review [C]`** - Claude + Codex 双重审查
3. **运行 `/workflows:review [G]`** - Claude + Gemini 双重审查
4. **跳过审查** - PR 已准备好，不需要额外审查

Based on selection:
- **`/workflows:review`** → 调用 `/workflows:review` 审查当前分支或 PR
- **`/workflows:review [C]`** → 调用 `/workflows:review [C]`
- **`/workflows:review [G]`** → 调用 `/workflows:review [G]`
- **跳过审查** → 提醒用户后续可手动运行 `/workflows:review`
```

**验证**:
- [ ] 确认 Phase 5 位于 Documentation Reminder 之后、`---` 分隔线之前
- [ ] 确认包含 4 个选项
- [ ] 确认包含 `AskUserQuestion`

---

### Task 5: review.md 增加 Handoff 选项（P2）

**文件**: `plugins/compound-engineering/commands/workflows/review.md:469`
**操作**:
- [x] 在第 469 行（Track Progress 末尾）之后、第 471 行（Severity Breakdown）之前，插入 Handoff 部分

**代码**:
```markdown
### Workflow Handoff

After all findings are addressed (or triaged), use **AskUserQuestion tool**:

**Question:** "代码审查流程完成。下一步？"

**Options:**
1. **记录解决方案** - 运行 `/workflows:compound` 记录本次解决的问题（推荐，如有非 trivial 修复）
2. **保存上下文** - 运行 `/workflows:save` 保存项目状态
3. **完成** - 审查流程结束，无需额外操作
```

**验证**:
- [ ] 确认 review.md 包含 `### Workflow Handoff` 部分
- [ ] 确认包含 `/workflows:compound` 和 `/workflows:save`

---

### Task 6: compound.md 修改选项 1 为显式命令（P2）

**文件**: `plugins/compound-engineering/commands/workflows/compound.md:280`
**操作**:
- [x] 将选项 1 "Continue workflow (recommended)" 改为显式的 `/workflows:save`

**代码**:
```markdown
# 旧（第 280 行）:
1. Continue workflow (recommended)

# 新:
1. 运行 `/workflows:save` - 保存项目上下文（推荐）
```

**验证**:
- [ ] 确认第 280 行包含 `/workflows:save`

---

### Task 7: plugin CLAUDE.md 增加 Handoff 协议（P2）

**文件**: `plugins/compound-engineering/CLAUDE.md:138`
**操作**:
- [x] 在第 138 行（"新增 workflow 命令时，按顺序分配 Step 编号。"）和第 140 行（"## Command Frontmatter 参考"）之间插入 Handoff 协议

**代码**:
```markdown
新增 workflow 命令时，按顺序分配 Step 编号。

### Workflow Handoff 协议（铁律）

所有 `commands/workflows/*.md` 命令必须遵循（终端命令 save/doctor 除外）：

1. 命令的最后一个 Phase 必须是 Handoff
2. Handoff 必须使用 **AskUserQuestion tool** 呈现选项
3. 第一个选项必须是流程中的下一步命令（含完整参数如文件路径）
4. 必须有"跳过/停止"选项
5. Handoff 后需内嵌行为约束（禁止 AI 在选项外自由发挥）
6. 选项描述使用中文，命令名保持英文

**流程链路**：
```
brainstorm → plan → [deepen-plan] → [plan_review] → work → review → [compound] → save
```

**快速验证**：
```bash
# 检查所有 workflow 命令是否包含 AskUserQuestion
for f in plugins/compound-engineering/commands/workflows/*.md; do
  if ! grep -q "AskUserQuestion" "$f"; then
    echo "WARNING: $f 缺少 Handoff"
  fi
done
```

**检查清单**（新增/修改 workflow 命令时验证）：
- [ ] 最后一个 Phase 是否为 Handoff？
- [ ] 是否使用 AskUserQuestion？
- [ ] 第一个选项是否为流程中的下一步命令 + 完整路径？
- [ ] 是否有内嵌行为约束？
- [ ] 描述语言是否为中文？

## Command Frontmatter 参考
```

**验证**:
- [ ] 确认 CLAUDE.md 第 138-140 行之间包含 "### Workflow Handoff 协议"
- [ ] 确认包含快速验证 bash 脚本
- [ ] 确认包含检查清单

---

### Task 8: 创建 Handoff lint 脚本（P2）

**文件**: `scripts/check-handoff.sh`（新建）
**操作**:
- [x] 创建一个检查 workflow 命令 Handoff 完整性的脚本

**代码**:
```bash
#!/bin/bash
# 检查 workflow 命令的 Handoff 完整性
# 用法: bash scripts/check-handoff.sh

COMMANDS_DIR="plugins/compound-engineering/commands/workflows"
SKIP_FILES="save.md doctor.md"  # 终端命令，无需 Handoff
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

  # 检查 AskUserQuestion
  if ! grep -q "AskUserQuestion" "$f"; then
    echo "FAIL: $filename - 缺少 AskUserQuestion (无 Handoff)"
    ERRORS=$((ERRORS + 1))
  else
    echo "PASS: $filename"
  fi
done

# 也检查非 workflow 的关键命令
EXTRA_COMMANDS="plugins/compound-engineering/commands/plan_review.md"
for f in $EXTRA_COMMANDS; do
  if [ -f "$f" ]; then
    filename=$(basename "$f")
    if ! grep -q "AskUserQuestion" "$f"; then
      echo "FAIL: $filename - 缺少 AskUserQuestion (无 Handoff)"
      ERRORS=$((ERRORS + 1))
    else
      echo "PASS: $filename"
    fi
  fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "全部通过！所有 workflow 命令都有 Handoff。"
else
  echo "发现 $ERRORS 个命令缺少 Handoff，请修复。"
  exit 1
fi
```

**验证**:
- [ ] 运行 `bash scripts/check-handoff.sh` 确认输出正确
- [ ] 修复前应报告 plan_review 缺少 Handoff（如果 Task 1 未完成）
- [ ] 修复后应全部 PASS

---

### Task 9: load.md 增加未完成计划检测（P3）

**文件**: `plugins/compound-engineering/commands/workflows/load.md:96`
**操作**:
- [x] 在当前的选项列表之前，增加未完成计划检测逻辑

**代码**:
```markdown
### 未完成计划检测

恢复上下文后，自动扫描是否有未完成的计划：

```bash
ls -la docs/plans/*.md 2>/dev/null | head -10
```

对每个计划文件，检查是否有未完成任务（`- [ ]`）且在 30 天内修改。

**如果发现未完成计划：**
使用 **AskUserQuestion tool**：

**Question:** "发现未完成计划。要继续吗？"

**Options:**
1. **继续执行** - 运行 `/workflows:work <plan_path>`（推荐）
2. **查看计划** - 先查看计划内容再决定
3. **忽略** - 不继续，开始新任务

**如果未发现计划**，继续原有的选项流程。
```

**验证**:
- [ ] 确认 load.md 包含 `未完成计划检测` 部分
- [ ] 确认包含 30 天窗口

---

### Task 10: 检查 deepen-plan.md 路径传递（P3）

**文件**: `plugins/compound-engineering/commands/deepen-plan.md`
**操作**:
- [x] 确认 Post-Enhancement Options 中 `/workflows:work` 选项是否显式传递 plan 文件路径
- [x] 如果缺失，添加路径传递

**验证**:
- [ ] 确认 deepen-plan.md 中的 `/workflows:work` 选项包含 `<plan_path>`

---

### Task 11: 更新版本号和 CHANGELOG（收尾）

**文件**: `.claude-plugin/marketplace.json`, `plugins/compound-engineering/.claude-plugin/plugin.json`, `plugins/compound-engineering/CHANGELOG.md`
**操作**:
- [x] 使用 `powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch` 更新版本号
- [x] 在 CHANGELOG.md 添加版本记录

**验证**:
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致
- [ ] CHANGELOG.md 包含新版本条目

---

### Task 12: 运行 Handoff lint 验证（最终验证）

**操作**:
- [x] 运行 `bash scripts/check-handoff.sh` 确认所有命令通过
- [x] 逐一检查每个修改的文件，确认 AskUserQuestion 和选项格式正确

**验证**:
- [ ] lint 脚本输出 "全部通过"
- [ ] 无 WARNING 或 FAIL

## References

- Brainstorm: `docs/brainstorms/2026-03-05-workflow-handoff-improvement-brainstorm.md`
- 最佳 Handoff 模板: `plugins/compound-engineering/commands/workflows/brainstorm.md:284`
- Subagent 经验: `docs/solutions/integration-issues/subagent-driven-workflow-integration.md`
- 幻影引用经验: `docs/solutions/integration-issues/phantom-agent-references-in-workflows.md`
