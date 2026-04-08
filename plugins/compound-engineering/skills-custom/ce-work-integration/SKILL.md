---
name: ce-work-integration
description: "私有 Overlay：Task Bundle 持久化 + Failure FSM 集成。在 ce:work 基础上增加 state.md 读写和状态机转换。使用时机：执行 ce:work 时，如果任务有对应的 Task Bundle（docs/tasks/<id>/），加载此 skill 以启用持久化和状态追踪。"
---

# ce:work 集成 Overlay — Task Bundle + FSM

> **基础层**：上游 `ce:work` 负责任务执行、质量检查、提交工作流。
>
> **本 Overlay 增量**：Task Bundle 持久化（state.md 读写）+ Failure FSM 状态转换。

---

## 何时使用本 Overlay

当满足以下条件时，在运行 `ce:work` 前/后应用本 overlay：

1. 任务有对应的 Task Bundle：`docs/tasks/<task-id>/` 目录存在
2. 或者任务预期超过 1 小时（值得持久化上下文）
3. 或者任务涉及多个子代理

---

## Phase 0: 任务恢复（新增，在 ce:work Phase 1 之前）

**当重新进入一个任务时**，在执行 ce:work Phase 1 之前：

```markdown
1. 检查 docs/tasks/<task-id>/state.md 是否存在
2. 如果存在，读取：
   - current_step / total_steps
   - status (active/blocked/debugging/replanned/resumed)
   - blocked_by（阻塞原因）
   - last_checkpoint 时间戳
3. 从 current_step 继续，不重新执行已完成步骤
4. 更新 state.md: status → active, updated_at → 当前时间
```

**如果 state.md 不存在**（新任务），从 docs/tasks/task-bundle/templates/state.md.tpl 创建：

```bash
cp plugins/compound-engineering/skills-custom/task-bundle/templates/state.md.tpl \
   docs/tasks/<task-id>/state.md
# 填写 task_id、total_steps、started_at
```

---

## FSM 状态转换（替换 ce:work 的隐式 STOP 处理）

### 原 ce:work 行为（隐式）
ce:work 遇到阻塞时会停下来询问用户，没有状态记录。

### 本 Overlay 增强（显式状态机）

```
active → blocked: 遇到任何阻塞（依赖缺失、CI 失败、需求不清）
blocked → debugging: 开始排查阻塞原因
debugging → replanned: 需要修改原计划
debugging → active: 阻塞自行解除（如 CI 通过）
replanned → resumed: 新计划就绪，等待用户确认重启（⚠️ 必须等用户确认）
resumed → active: 用户确认后，按新计划重新开始（AI 执行）
active → reviewed: 实现完成，进入 ce:review
reviewed → compounded: 经验沉淀完成
任何状态 → cancelled: 任务被主动取消
```

**`replanned → resumed` 用户确认门（强制）**：

当状态进入 `resumed` 时，必须展示新计划摘要并等待用户确认，禁止自动进入 `active`：

```
📋 计划已更新，重启前需要你确认：

  原阻塞原因：[blocked_by 值]
  新计划摘要：[更新后的关键步骤]

  确认后将从步骤 [N] 重新开始。继续吗？(y/n)
```

用户确认后才将 state.md 的 status 更新为 `active`。

**每次状态转换写入 state.md**：

```markdown
## 状态历史

| 时间 | 从 | 到 | 原因 |
|------|-----|-----|------|
| 2026-04-08 10:00 | created | active | 开始执行 |
| 2026-04-08 14:30 | active | blocked | 等待 upstream merge 完成 |
```

### 阻塞触发条件（替换隐式 STOP）

以下情况触发 `active → blocked`，写入 state.md 并告知用户：

| 触发条件 | blocked_by 值 |
|---------|--------------|
| 依赖任务未完成 | `depends_on: <task-id>` |
| CI/测试持续失败（≥3 次） | `ci_failure: <test-name>` |
| 需求不清无法继续 | `unclear_requirement: <描述>` |
| Rate limit / 工具不可用 | `tool_unavailable: <tool-name>` |
| 需要人工决策 | `human_decision_required: <描述>` |

---

## Phase 1 增强: state.md 写入时机

在 ce:work 原有 Phase 1-3 的基础上，在以下时机写入/更新 state.md：

| 时机 | state.md 更新内容 |
|------|-----------------|
| 开始执行 | status: active, current_step: 1 |
| 每个任务完成 | current_step +1, last_checkpoint |
| 遇到阻塞 | status: blocked, blocked_by |
| 开始排查 | status: debugging |
| 提交代码 | 记录 commit hash（可选）|
| 完成实现 | status: reviewed（等待 ce:review）|

---

## Phase 4 增强: compounded 终态

ce:work Phase 4（完成阶段）后，如果运行了 `ce:compound`：

1. 将 state.md 的 status 更新为 `compounded`
2. 在 docs/tasks/<task-id>/review.md 记录经验沉淀结果
3. 可选：将任务目录归档到 `docs/tasks/archive/`

---

## Ralph-lite Repair Loop（有界微循环）

当任务有明确 verifier（测试/lint/build）且遇到小错误时，在触发 STOP FSM 之前：

```
Execute → Verify → Fail → Ralph-lite(≤2次) → Verify → 
  ├── 通过 → 继续
  └── 仍失败 → 触发 active → blocked
```

**Ralph-lite 规则**：
1. 最多修复 2 次循环
2. 每次修复**必须改变假设或策略**，不能机械重试
3. 在 state.md 中记录失败原因和修复依据

---

## Task Bundle 文件结构参考

```
docs/tasks/<YYYY-MM-DD-seq-description>/
├── plan.md      # 目标、约束、验收标准（链接到 docs/plans/）
├── state.md     # 当前步骤、阻塞点、状态历史（本 overlay 写入）
└── review.md    # findings、证据、结论（ce:review 写入）
```

模板位置：`plugins/compound-engineering/skills-custom/task-bundle/templates/`
