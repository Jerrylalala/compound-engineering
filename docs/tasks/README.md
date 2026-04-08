# Task Bundle 索引

> Task Bundle 是任务的统一工件结构，每个任务由 3 个文件组成。

## 目录结构

每个任务存放在 `docs/tasks/<task-id>/` 下：

| 文件 | 职责 | 写入时机 |
|------|------|----------|
| `plan.md` | 目标、约束、验收标准 | 任务创建时 |
| `state.md` | 当前步骤、阻塞点、状态机历史 | 执行过程中持续更新 |
| `review.md` | findings、证据、结论 | 审查阶段 |

## Task ID 格式

```
YYYY-MM-DD-<seq>-<kebab-description>
```

- 日期：任务创建日期
- seq：当日序号（01-99）
- description：3-5 个单词的 kebab-case
- 示例：`2026-04-07-01-review-contract-design`

## 与现有文件的关系

Task Bundle 通过链接引用现有文件：
- `plan.md` 可链接 `docs/plans/` 中的详细计划
- `state.md` 可链接 `docs/brainstorms/` 中的 brainstorm
- 现有文件不需要迁移
