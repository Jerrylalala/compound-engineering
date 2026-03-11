---
title: "/workflows:plan Handoff 命令调用明确性修复"
date: 2026-03-11
type: fix
severity: medium
status: resolved
version: 2.44.3
tags:
  - workflows
  - plan
  - handoff
  - command-invocation
  - ai-behavior
related_issues:
  - AI "忘记"可用命令
  - plan_review 未被调用
  - Write 工具连续失败后的决策退化
---

# /workflows:plan Handoff 命令调用明确性修复

## 问题描述

### 用户报告的现象

用户在使用 `/workflows:plan` 生成计划后，AI 未正确调用 `/plan_review` 命令，尽管：
1. 该命令在系统提示的可用技能列表中
2. 该命令在自动补全中可见
3. Handoff 部分明确提到了这个选项

### 触发场景

- 简单任务（2 个数据库字段 + UI 调整）
- 生成了过长的计划（500+ 行）
- Write 工具连续失败 10+ 次
- AI 进入"压力状态"，决策能力下降

### 根本原因

**不是技能丢失，而是指令模糊导致的 AI 决策失误。**

原 Handoff 部分的问题：
```markdown
Based on selection:
- **运行 `/plan_review`** → 调用 `/plan_review <plan_path>`
```

这种描述存在以下问题：
1. **隐式指令** - "调用"是什么意思？用什么工具？
2. **无格式规范** - 没有明确 Skill() 工具的调用语法
3. **无验证机制** - 不检查命令是否存在
4. **无降级方案** - AI 不确定时会选择跳过

## 解决方案

### 修改内容

在 `plugins/compound-engineering/commands/workflows/plan.md` 的 Handoff 部分：

#### 1. 添加 Pre-flight Check

```markdown
**Pre-flight check (verify before presenting options):**
```
Required commands for handoff:
✓ /workflows:work - Execute plan (Skill tool with "workflows:work")
✓ /plan_review - Multi-agent review (Skill tool with "plan_review")
✓ /deepen-plan - Enhance with research (Skill tool with "deepen-plan")

If any command is missing from system prompt, DO NOT present that option.
```
```

#### 2. 明确命令调用格式

```markdown
**Command invocation format (MUST follow exactly):**
- `/workflows:work` → `Skill("workflows:work", args="<plan_path>")`
- `/plan_review` → `Skill("plan_review", args="<plan_path>")`
- `/deepen-plan` → `Skill("deepen-plan", args="<plan_path>")`
```

#### 3. 将描述改为可执行指令

**修改前：**
```markdown
- **运行 `/plan_review`** → 调用 `/plan_review <plan_path>`
```

**修改后：**
```markdown
2. **运行 `/plan_review`** →
   ```
   Execute: Skill("plan_review", args="<plan_path>")
   After completion: Use AskUserQuestion to ask "审查完成。是否继续执行 /workflows:work?"
   If yes: Skill("workflows:work", args="<plan_path>")
   ```
```

### 关键改进

| 改进点 | 修改前 | 修改后 |
|--------|--------|--------|
| **指令明确性** | "调用 /plan_review" | `Skill("plan_review", args="<plan_path>")` |
| **格式规范** | 无 | 代码块 + 伪代码 |
| **验证机制** | 无 | Pre-flight check |
| **后续步骤** | 模糊 | 明确的 if-then 逻辑 |

## 验证方法

### 测试用例

```markdown
# 测试 1：低风险计划
输入：简单任务（≤3 文件）
预期：AI 呈现选项，包含 /plan_review
验证：AI 使用 Skill("plan_review", args="...") 调用

# 测试 2：中风险计划
输入：中等任务（4-10 文件）
预期：AI 推荐 /plan_review
验证：AI 正确调用并在完成后询问是否继续

# 测试 3：高风险计划
输入：复杂任务（>10 文件）
预期：AI 强烈推荐 /plan_review
验证：AI 显示警告信息并正确调用
```

### 验证命令

```bash
# 检查版本号一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# 搜索 Handoff 部分
grep -A 30 "## Handoff" plugins/compound-engineering/commands/workflows/plan.md
```

## 影响范围

### 修改的文件

- `plugins/compound-engineering/commands/workflows/plan.md` - Handoff 部分
- `plugins/compound-engineering/.claude-plugin/plugin.json` - 版本号 2.44.2 → 2.44.3
- `.claude-plugin/marketplace.json` - 版本号 2.44.2 → 2.44.3
- `plugins/compound-engineering/CHANGELOG.md` - 添加 2.44.3 条目

### 影响的工作流

- `/workflows:plan` - 直接影响
- `/workflows:work` - 间接影响（通过 plan handoff）
- `/plan_review` - 调用频率预期提升
- `/deepen-plan` - 调用频率预期提升

## 相关问题

### 问题 1：计划过长

**状态**：待修复（需要添加复杂度评估）
**优先级**：P1
**解决方案**：见 `docs/solutions/integration-issues/workflows-plan-complexity-assessment-2026-03-11.md`（待创建）

### 问题 2：Write 工具失败

**状态**：待修复（需要添加降级策略）
**优先级**：P0
**解决方案**：见 `docs/solutions/integration-issues/tool-invocation-degradation-strategy-2026-03-11.md`（待创建）

## 经验教训

### 设计原则

1. **显式优于隐式** - AI 需要明确的可执行指令，不是描述性文本
2. **验证优于假设** - 在呈现选项前验证命令存在
3. **格式化优于自然语言** - 代码块比句子更清晰
4. **防御性设计** - 假设 AI 会在压力下退化，提供降级路径

### AI 行为模式

**压力状态下的 AI 特征：**
- 倾向于跳过不确定的操作
- 重复失败的操作而不尝试替代方案
- "忘记"可用工具（实际是决策优先级下降）
- 生成不完整的工具调用（如空 XML 标签）

**应对策略：**
- 在关键决策点强制提示
- 提供明确的可执行指令
- 添加验证和降级机制
- 限制上下文窗口压力（如限制计划长度）

## 后续行动

### 立即行动（已完成）

- [x] 修改 Handoff 部分
- [x] 更新版本号
- [x] 更新 CHANGELOG
- [x] 验证版本一致性
- [x] 创建解决方案文档

### 短期行动（本周）

- [ ] 添加复杂度评估机制（问题 1）
- [ ] 添加工具降级策略（问题 2）
- [ ] 在其他 workflow 命令中应用相同模式
- [ ] 创建测试用例验证修复

### 长期行动（本月）

- [ ] 审查所有 Handoff 部分的指令明确性
- [ ] 建立 Handoff 设计规范
- [ ] 添加自动化测试（检测模糊指令）

## 参考资料

### 相关文档

- [Workflow 可视化指南](../../zh-CN/WORKFLOW-VISUAL.md)
- [版本管理策略](../../zh-CN/VERSION-STRATEGY.md)
- [插件开发指南](../../compound-engineering/CLAUDE.md)

### 相关提交

```bash
# 查看修改历史
git log --oneline --grep="plan_review" | head -10
git log --oneline -- "plugins/compound-engineering/commands/workflows/plan.md" | head -5
```

### 上游参考

- EveryInc/compound-engineering-plugin - 原始实现
- 无对应 issue（本地发现的问题）

---

**创建时间**：2026-03-11
**最后更新**：2026-03-11
**作者**：Jerry Jian
**审核状态**：待审核
