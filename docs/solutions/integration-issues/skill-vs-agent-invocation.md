---
title: Skill 与 Agent 调用方式的区别
category: integration-issues
tags:
  - claude-code-plugin
  - skill
  - agent
  - task-tool
module: compound-engineering-plugin
symptoms:
  - Task() 调用 skill 无效
  - 子代理找不到指定的 agent
date_created: 2026-02-02
date_resolved: 2026-02-02
severity: bug
---

# Skill 与 Agent 调用方式的区别

## 问题描述

在 `/workflows:work` 的 Subagent-Driven 模式中，尝试使用 `Task(spec-compliance-review)` 调用 skill，但 `spec-compliance-review` 实际上是一个 **skill**（位于 `skills/` 目录），而不是 **agent**（位于 `agents/` 目录）。

### 错误代码

```
Task(spec-compliance-review): "审查刚完成的任务是否符合计划规范"
```

### 问题原因

Claude Code 的 `Task` 工具只能调用 agents，不能直接调用 skills。

**调用方式对比**：

| 组件类型 | 位置 | 调用方式 |
|----------|------|----------|
| Agent | `agents/` 目录 | `Task(agent-name)` |
| Skill | `skills/` 目录 | `skill: skill-name` 或在 Task 中描述使用 |

## 解决方案

使用 `Task(general-purpose)` 并在 prompt 中指示其使用 skill：

```
Task(general-purpose): """
  使用 spec-compliance-review skill 审查刚完成的任务。

  原始任务描述: [task.description]
  实现者报告: [subagent 的执行结果]

  验证：
  1. 遗漏的需求 - 是否实现了所有请求的功能？
  2. 多余的工作 - 是否构建了不需要的东西？
  3. 理解偏差 - 是否以不同于预期的方式解释需求？

  报告：✅ 规格符合 或 ❌ 发现问题（附具体内容）
"""
```

## 预防策略

### 1. 检查组件位置

在调用前确认组件类型：

```bash
# 检查是否是 agent
ls agents/**/*name*.md

# 检查是否是 skill
ls skills/*name*/SKILL.md
```

### 2. 命名规范

建议在命名时区分：
- Agents：`xxx-reviewer`, `xxx-analyzer`, `xxx-specialist`
- Skills：`xxx-development`, `xxx-debugging`, `xxx-review`（名词形式）

### 3. 文档引用

在命令文件中引用组件时，注明类型：

```markdown
# 使用 spec-compliance-review skill（注意：是 skill 不是 agent）
Task(general-purpose): "使用 spec-compliance-review skill..."
```

## 关键教训

1. **Skills 和 Agents 是不同的概念**：Skills 是知识/流程文档，Agents 是可调度的子代理
2. **Task 工具只调度 Agents**：要使用 Skill，需要通过 general-purpose agent 间接调用
3. **先检查组件位置**：调用前确认是在 `agents/` 还是 `skills/` 目录

## 相关资源

- spec-compliance-review skill: `skills/spec-compliance-review/SKILL.md`
- Task 工具支持的 agent types: 见系统提示中的 subagent_type 列表
