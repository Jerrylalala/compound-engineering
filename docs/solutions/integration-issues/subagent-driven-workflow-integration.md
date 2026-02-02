---
title: Subagent-Driven Workflow 整合到 Claude Code 插件
category: integration-issues
tags:
  - claude-code-plugin
  - workflow-automation
  - subagent
  - framework-integration
module: compound-engineering-plugin
symptoms:
  - 单代理执行多任务时上下文污染
  - 后期任务首次成功率下降
  - 计划格式过于粗粒度
date_created: 2026-02-02
date_resolved: 2026-02-02
severity: enhancement
global_reference: ~/.claude/solutions/subagent-driven-workflow-integration.md
---

# Subagent-Driven Workflow 整合到 Claude Code 插件

## 问题描述

在分析 Superpowers 框架后，发现现有的 `/workflows:plan` 和 `/workflows:work` 命令缺少两个关键特性：

1. **Bite-Sized Task 格式**：任务粒度过大，缺少 2-5 分钟原子化任务的强制格式
2. **Subagent-Driven 执行模式**：单代理执行所有任务会导致上下文污染，后期任务质量下降

### 症状表现

| 问题 | 单代理执行 | 预期效果 |
|------|------------|----------|
| 上下文污染 | 任务越多，质量越差 | 每任务新鲜上下文 |
| Token 成本 | 上下文累积增长 | 每任务精确上下文 |
| 首次成功率 | ~40%（后期任务） | ~95%（恒定） |

## 根因分析

### 1. 计划格式问题

原有 `/workflows:plan` 生成的任务格式：
```markdown
- [ ] 实现用户认证功能  ← 太大，不具体
```

缺少：
- 确切文件路径
- 完整代码（非伪代码）
- 验证步骤

### 2. 执行模式问题

原有 `/workflows:work` 使用单代理执行所有任务，没有考虑：
- 任务间上下文隔离
- 两阶段审查（规范合规 → 代码质量）
- 人工检查点

## 解决方案

### 1. 增强 plan.md - Bite-Sized Task 格式

在 `commands/workflows/plan.md` 添加强制格式要求：

```markdown
### Task N: [动作描述]

**文件**: `确切/文件/路径.ext:行号`（如已知）
**操作**:
- [ ] 具体步骤 1
- [ ] 具体步骤 2

**代码**:
\`\`\`language
// 完整代码，不是伪代码
\`\`\`

**验证**:
- [ ] 运行 `具体命令` 确认 [预期结果]
```

**格式检查清单**：
- 每个任务是否 ≤ 5 分钟可完成？
- 文件路径是否确切？
- 代码是否完整？
- 验证步骤是否具体可执行？

### 2. 增强 work.md - 自动执行模式选择

在 `commands/workflows/work.md` 添加自动检测逻辑：

```
统计时机: Phase 1 结束后，Phase 2 开始前
统计来源: TodoWrite 任务列表

任务数量 = 1  → 标准模式（单代理执行）
任务数量 ≥ 2 → Subagent-Driven 模式（自动启用）
```

### 3. Subagent-Driven 执行逻辑

```python
batch_size = 3

while (tasks remain):
  current_batch = tasks[0:batch_size]

  for task in current_batch:
    # 1. 派遣新子代理执行单个任务
    Task(general-purpose): "执行任务..."

    # 2. 两阶段审查
    Task(general-purpose): "使用 spec-compliance-review skill 进行规范合规审查"

    # 3. 更新任务状态
    Mark task completed

  # 4. 人工检查点
  AskUserQuestion: "已完成 3 个任务。继续下一批？"
```

## 修改的文件

| 文件 | 修改内容 |
|------|----------|
| `commands/workflows/plan.md` | + Bite-Sized Task 格式（第 123-184 行） |
| `commands/workflows/work.md` | + 执行模式检测（第 19-47 行） |
| `commands/workflows/work.md` | + Subagent 批量执行（第 155-206 行） |
| `marketplace.json` | 版本 2.31.0 → 2.32.0 |
| `plugin.json` | 版本 2.31.0 → 2.32.0 |

## 预防策略

### 1. 计划格式检查

在 `/workflows:plan` 完成后自动验证：
- [ ] 每个任务 ≤ 5 分钟
- [ ] 文件路径确切
- [ ] 代码完整
- [ ] 验证步骤具体

### 2. 执行模式自动化

不需要用户手动选择，根据任务数量自动决定：
- 1 任务 → 标准模式（减少开销）
- ≥2 任务 → Subagent 模式（保证质量）

### 3. 两阶段审查

复杂任务启用 `spec-compliance-review` 技能，确保：
- 先验证「做对了吗」（规范合规）
- 再验证「做好了吗」（代码质量）

## 关键教训

1. **单代理执行多任务会退化**：上下文累积导致后期任务质量下降
2. **任务粒度影响执行质量**：2-5 分钟的原子任务更容易正确执行
3. **自动化优于手动选择**：根据任务数量自动选择执行模式减少用户负担
4. **两阶段审查价值高**：「做对」比「做好」更重要

## 相关资源

- Superpowers 框架：`F:\StudyFolder\StudyDest\project\Dev_tools\superpowers`
- spec-compliance-review 技能：`skills/spec-compliance-review/SKILL.md`
- systematic-debugging 技能：`skills/systematic-debugging/SKILL.md`
- test-driven-development 技能：`skills/test-driven-development/SKILL.md`

