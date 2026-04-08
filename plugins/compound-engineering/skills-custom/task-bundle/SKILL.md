---
name: task-bundle
description: 管理 Task Bundle 工件结构（docs/tasks/），提供创建、查询、状态更新的规范
---

# Task Bundle 管理

## 什么是 Task Bundle

Task Bundle 是任务的统一工件结构。每个任务由三个文件组成：

| 文件 | 职责 | 写入时机 |
|------|------|----------|
| `plan.md` | 目标、约束、验收标准 | 任务创建时 |
| `state.md` | 当前步骤、阻塞点、状态机历史 | 执行过程中持续更新 |
| `review.md` | findings、证据、结论 | 审查阶段 |

## 创建新 Task Bundle

1. 生成 task-id：`YYYY-MM-DD-<seq>-<kebab-description>`
2. 创建目录 `docs/tasks/<task-id>/`
3. 从模板复制三个文件，替换占位符
4. 更新 frontmatter 中的 task_id、created_at、owner

## 状态转换规则

参见 Failure FSM 协议（`docs/specs/failure-fsm.md`）。

每次状态转换必须：
1. 更新 `state.md` 的 `status` frontmatter 字段
2. 在状态历史表追加一行（时间、从、到、原因、操作者）
3. 更新 `last_checkpoint` 时间戳

## 与现有工作流的关系

> Phase 0 说明：当前 Task Bundle 是独立的文档协议，不与 workflow 命令自动集成。
> Phase 2 将在上游合并后，将 Task Bundle 读写集成到 ce-work/ce-review 中。

手动使用方式：
- `/workflows:plan` 输出后，手动创建 Task Bundle 并链接 plan 文件
- `/workflows:work` 执行中，手动更新 state.md
- `/workflows:review` 完成后，手动填写 review.md

## 模板位置

```
skills-custom/task-bundle/templates/
├── plan.md.tpl
├── state.md.tpl
└── review.md.tpl
```
