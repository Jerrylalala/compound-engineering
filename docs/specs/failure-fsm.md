---
name: Failure FSM
version: "1.0"
status: draft
date: 2026-04-07
---

# Failure FSM 状态机协议

## 概述

Failure FSM 将 STOP 协议从"口头约定"升级为具有明确状态、转换条件和记录要求的状态机。

> **Phase 0 限制**：当前版本是纯文档协议，不与任何 workflow 命令自动集成。
> Phase 2 将在上游合并后，将 FSM 集成到 ce-work SKILL.md 中。

## 状态定义

| 状态 | 说明 | 终态？ |
|------|------|--------|
| `created` | 任务已创建，尚未开始 | 否 |
| `active` | 正在执行 | 否 |
| `blocked` | 遇到阻塞，需要干预 | 否 |
| `debugging` | 正在调试阻塞原因 | 否 |
| `replanned` | 已修改计划，准备重新执行 | 否 |
| `resumed` | 从阻塞/调试中恢复，重新执行 | 否 |
| `reviewed` | 执行完成，已审查 | 否 |
| `compounded` | 经验已沉淀 | 是 |
| `cancelled` | 任务取消 | 是 |

## 状态转换图

```
                    ┌──────────────┐
                    │   created    │
                    └──────┬───────┘
                           │ 开始执行
                           ▼
                    ┌──────────────┐
              ┌────▶│    active    │◀────────────┐
              │     └──────┬───────┘              │
              │            │ 遇到阻塞             │ 恢复
              │            ▼                      │
              │     ┌──────────────┐              │
              │     │   blocked    │──────────────┤
              │     └──────┬───────┘   自动解除    │
              │            │ 开始调试              │
              │            ▼                      │
              │     ┌──────────────┐              │
              │     │  debugging   │──────────────┘
              │     └──────┬───────┘
              │            │ 需要重新规划
              │            ▼
              │     ┌──────────────┐
              │     │  replanned   │
              │     └──────┬───────┘
              │            │ 重新执行
              │            ▼
              │     ┌──────────────┐
              └─────│   resumed    │
                    └──────┬───────┘
                           │ 提交审查
                           ▼
                    ┌──────────────┐
                    │   reviewed   │
                    └──────┬───────┘
                           │ 经验沉淀
                           ▼
                    ┌──────────────┐
                    │  compounded  │
                    └──────────────┘

    任意非终态 ───▶ cancelled（随时可取消）
```

## 转换条件（触发事件）

| 转换 | 触发事件 | 触发者 | 记录要求 |
|------|----------|--------|----------|
| created → active | 开始执行（/workflows:work 启动） | AI/用户 | 记录开始时间 |
| active → blocked | 遇到无法自行解决的问题 | AI 自动检测 | 记录阻塞原因 |
| blocked → active | 阻塞自动解除（依赖就绪等） | AI/用户 | 记录解除原因 |
| blocked → debugging | 开始主动调试 | AI/用户 | 记录调试策略 |
| debugging → active | 调试成功，问题解决 | AI | 记录解决方案 |
| debugging → replanned | 调试发现需要修改计划 | AI/用户 | 记录计划变更内容 |
| replanned → resumed | 新计划确认，重新执行 | 用户确认 | 记录新计划链接 |
| resumed → active | 恢复执行 | AI | — |
| active → reviewed | 所有步骤完成，提交审查 | AI | 记录完成时间 |
| reviewed → compounded | 审查通过，经验沉淀完成 | AI/用户 | 链接 solution 文档 |
| * → cancelled | 任务取消 | 用户 | 记录取消原因 |

## 与 STOP 协议的关系

现有 STOP 协议（work.md 中的"遇到阻塞时停下来询问"）对应 FSM 的 `active → blocked` 转换。
FSM 不替代 STOP，而是将 STOP 的"口头约定"结构化为可追踪的状态转换。

## 与 Ralph-lite 的关系（Phase 3）

Ralph-lite（有界修复循环 ≤2 次）将嵌入 `active` 状态内部：
- 如果任务有明确 verifier（测试/lint/build），先尝试 Ralph-lite 修复
- 超过 repair budget → 触发 `active → blocked`（进入外层 FSM）
- Phase 0 不实现 Ralph-lite

## state.md 中的记录格式

每次状态转换在 state.md 的「状态历史」表追加一行：

| 时间 | 从 | 到 | 原因 | 操作者 |
|------|-----|-----|------|--------|
| 2026-04-07 14:30 | active | blocked | 依赖 upstream merge 完成 | claude |
| 2026-04-07 15:00 | blocked | debugging | 手动触发调试 | user |

同时更新 frontmatter：
- `status` → 新状态
- `last_checkpoint` → 当前时间
- `blocked_by` → 阻塞原因（如适用）
