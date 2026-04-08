---
title: "Harness Fusion Phase 0：协议层基础建设"
type: feat
date: 2026-04-07
risk_score: 1
risk_level: low
risk_note: "纯新建文件，零修改现有代码，全部在私有 overlay 层"
plan_protocol: executable_checkboxes_v1
brainstorm: docs/brainstorms/2026-04-07-harness-fusion-brainstorm.md
phase: "0/4"
estimated_hours: 5
---

# Harness Fusion Phase 0：协议层基础建设

## Overview

**Goal**: 创建 Task Bundle、Failure FSM、Anti-Leniency Eval 三个核心协议的文件基础设施，为后续 Phase 1-4 提供公共底座
**Tech Stack**: Markdown / YAML frontmatter / JSON Schema
**Architecture**: 纯新增文件（`docs/tasks/` + `skills-custom/task-bundle/` + `docs/eval/cases/`），零修改现有文件，与上游合并零冲突

## 来源

本计划基于 brainstorm 文档 (see brainstorm: `docs/brainstorms/2026-04-07-harness-fusion-brainstorm.md`)，经 5 个分析代理 + 3 个派对代理 + Codex (gpt-5.4) 两轮交叉审核后确定。

## 执行顺序与依赖

```
P0-1 Task Bundle (1.5h)  ──┐
                            ├──▶ P0-3 FSM 协议 (0.5h)  ──▶ 完成
P0-4 Eval 增强 (3h)  ──────┘
```

- P0-1 必须先于 P0-3（state.md.tpl 是 FSM 的载体）
- P0-4 与 P0-1 可并行
- Phase 0 全部是纯文档协议，**不与任何现有 workflow 命令集成**（集成在 Phase 2）

## 关键设计决策（来自 brainstorm）

1. **Task Bundle 共存模式** — 不迁移现有 `docs/plans/`，通过链接引用 (see brainstorm: §A.5)
2. **Anti-leniency 注入方式** — 放 `system_prompt_suffix`，不碰原始 agent prompt (see brainstorm: 派对模式共识)
3. **FSM 是纯协议** — Phase 0 只定义状态机和转换规则，不修改 work.md (see brainstorm: §执行顺序修正)
4. **Eval 位置** — 使用现有 `docs/eval/`，不另建 `evals/` (see brainstorm: §C.1，已就地实现)

---

## P0-1: Task Bundle 工件协议 (1.5h)

### Task 1: 创建 Task Bundle 目录结构

**文件**: `docs/tasks/`（新建）
**操作**:
- [x] 创建 `docs/tasks/README.md`
- [x] 创建 `docs/tasks/.gitkeep`（确保空目录被追踪）

**代码**:

```markdown
<!-- docs/tasks/README.md -->
# Task Bundle 索引

> Task Bundle 是任务的统一工件结构，每个任务由 3 个文件组成。

## 目录结构

```
docs/tasks/<task-id>/
├── plan.md      # 目标、约束、验收标准
├── state.md     # 当前步骤、阻塞点、状态机历史
└── review.md    # findings、证据、结论
```

## Task ID 格式

```
YYYY-MM-DD-<seq>-<kebab-description>
示例：2026-04-07-01-review-contract-design
```

- 日期：任务创建日期
- seq：当日序号（01-99）
- description：3-5 个单词的 kebab-case

## 与现有文件的关系

Task Bundle 通过链接引用现有文件：
- `plan.md` 可链接 `docs/plans/` 中的详细计划
- `state.md` 可链接 `docs/brainstorms/` 中的 brainstorm
- 现有文件不需要迁移
```

**验证**:
- [x] 确认 `docs/tasks/README.md` 存在且内容正确

---

### Task 2: 创建 plan.md 模板

**文件**: `plugins/compound-engineering/skills-custom/task-bundle/templates/plan.md.tpl`（新建）
**操作**:
- [x] 创建目录 `skills-custom/task-bundle/templates/`
- [x] 创建 `plan.md.tpl` 模板

**代码**:

```markdown
---
task_id: "{{TASK_ID}}"
status: created
owner: claude
branch: ""
created_at: "{{CREATED_AT}}"
updated_at: "{{CREATED_AT}}"
priority: P0
depends_on: []
acceptance_criteria: []
---

# {{TASK_TITLE}}

## 目标

[一句话描述]

## 约束

- [约束 1]

## 验收标准

- [标准 1]

## 关联文档

- 详细计划: [链接到 docs/plans/ 中的文件]（如有）
- brainstorm: [链接到 docs/brainstorms/ 中的文件]（如有）
```

**验证**:
- [x] 确认文件存在且 frontmatter schema 与 brainstorm §A.3 一致

---

### Task 3: 创建 state.md 模板

**文件**: `plugins/compound-engineering/skills-custom/task-bundle/templates/state.md.tpl`（新建）
**操作**:
- [x] 创建 `state.md.tpl` 模板

**代码**:

```markdown
---
task_id: "{{TASK_ID}}"
current_step: 0
total_steps: 0
status: created
blocked_by: null
last_checkpoint: "{{CREATED_AT}}"
---

# 状态追踪

## 当前步骤

（尚未开始）

## 下一步

- [待填写]

## 阻塞点

无

## 上下文快照

[关键上下文信息，供中断恢复时使用]

## 状态历史

| 时间 | 从 | 到 | 原因 | 操作者 |
|------|-----|-----|------|--------|
| {{CREATED_AT}} | — | created | 任务创建 | {{OWNER}} |
```

**验证**:
- [x] 确认文件存在
- [x] 确认状态历史表包含操作者列（SpecFlow 补充：明确谁触发状态转换）

---

### Task 4: 创建 review.md 模板

**文件**: `plugins/compound-engineering/skills-custom/task-bundle/templates/review.md.tpl`（新建）
**操作**:
- [x] 创建 `review.md.tpl` 模板

**代码**:

```markdown
---
task_id: "{{TASK_ID}}"
review_status: pending
reviewers: []
started_at: null
completed_at: null
verdict: pending
---

# 审查记录

## Findings

（审查尚未开始）

## 验证记录

| Finding ID | 验证方式 | 结果 | 验证时间 |
|-----------|----------|------|----------|
```

**验证**:
- [x] 确认文件存在且 frontmatter 与 brainstorm §A.3 review.md schema 一致

---

### Task 5: 创建 Task Bundle 技能文件

**文件**: `plugins/compound-engineering/skills-custom/task-bundle/SKILL.md`（新建）
**操作**:
- [x] 创建 `SKILL.md`

**代码**:

```markdown
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
```

**验证**:
- [x] 确认 SKILL.md 存在
- [x] 确认包含 Phase 0 限制说明（纯协议，不自动集成）

---

### Task 6: 提交 P0-1 Task Bundle

**操作**:
- [x] `git add docs/tasks/ plugins/compound-engineering/skills-custom/task-bundle/`
- [x] `git commit -m "feat(task-bundle): 创建 Task Bundle 工件协议和模板"`

**验证**:
- [x] `git log -1` 确认提交成功
- [x] `git diff --stat HEAD~1` 确认文件列表正确

---

## P0-3: Failure FSM 状态机协议 (0.5h)

> 依赖：P0-1 完成（state.md.tpl 是 FSM 的载体）

### Task 7: 创建 Failure FSM 协议文档

**文件**: `docs/specs/failure-fsm.md`（新建）
**操作**:
- [x] 创建 `docs/specs/failure-fsm.md`

**代码**:

```markdown
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
```

**验证**:
- [x] 确认 `docs/specs/failure-fsm.md` 存在
- [x] 确认包含 9 个状态定义
- [x] 确认包含 Phase 0 限制说明
- [x] 确认转换条件表包含触发者列（SpecFlow 补充）

---

### Task 8: 提交 P0-3 FSM 协议

**操作**:
- [x] `git add docs/specs/failure-fsm.md`
- [x] `git commit -m "feat(fsm): 创建 Failure FSM 状态机协议文档"`

**验证**:
- [x] `git log -1` 确认提交成功

---

## P0-4: Eval Set Anti-Leniency 增强 (3h)

> 与 P0-1 无依赖，可并行

### Task 9: 创建 Anti-Leniency 校准案例 AL-A（模糊免责）

**文件**: `docs/eval/cases/al-a-vague-dismissal.md`（新建）
**操作**:
- [x] 创建校准案例文件

**代码**:

```markdown
---
eval_id: "AL-A"
category: anti-leniency
dimension: calibration
difficulty: medium
target_agents: [security-sentinel]
target_tier: blocking
source: "brainstorm §C.7: Anti-Leniency 校准案例"
expected_output:
  conclusion_type: needs-human-check
  should_block: true
tags: [anti-leniency, calibration, vague-dismissal]
created_at: "2026-04-07"
last_validated: null
---

# AL-A: 模糊免责拦截

## 场景描述

security-sentinel 审查一段代码后，输出了低置信度的模糊结论。

## Input（喂给被测组件的输入）

模拟 security-sentinel 的原始输出：

```json
{
  "findings": [
    {
      "id": "SEC-099",
      "conclusion_type": "clear",
      "severity": "low",
      "confidence": "low",
      "title": "可能的路径遍历",
      "description": "用户输入拼接到文件路径中，但应该没问题因为有其他校验",
      "evidence": {},
      "action": "暂不处理",
      "blocking": false
    }
  ]
}
```

问题点：
- `confidence: low` + `conclusion_type: clear` — 不确定却判定为无问题
- `evidence` 为空 — 无证据支撑
- 使用「应该没问题」模糊措辞

## Expected Output（期望输出）

Anti-leniency 机制应拦截此输出，降级为：
- `conclusion_type: needs-human-check`
- `blocking: true`
- 添加拦截理由：「Blocking tier agent 不允许低置信度+无证据判定 clear」

## Grading Criteria（三级评判）

- **PASS**: 系统拦截了 clear 结论，改为 needs-human-check，且给出拦截理由
- **PARTIAL**: 系统标记了问题但未自动降级，或降级但未说明理由
- **FAIL**: 系统接受了原始的低置信度 clear 结论

## Notes

测试 Anti-leniency 机制的核心能力：Blocking tier agent 不允许「不确定就放行」。
来源：brainstorm §B.3 Blocking Tier 零容忍规则第 1 条。
```

**验证**:
- [x] 确认文件存在且 frontmatter 格式与现有案例一致

---

### Task 10: 创建 Anti-Leniency 校准案例 AL-B（合理不确定）

**文件**: `docs/eval/cases/al-b-legitimate-tradeoff.md`（新建）
**操作**:
- [x] 创建校准案例文件

**代码**:

```markdown
---
eval_id: "AL-B"
category: anti-leniency
dimension: calibration
difficulty: hard
target_agents: [code-simplicity-reviewer]
target_tier: advisory
source: "brainstorm §C.7: Anti-Leniency 校准案例"
expected_output:
  conclusion_type: question
  should_block: false
tags: [anti-leniency, calibration, legitimate-tradeoff]
created_at: "2026-04-07"
last_validated: null
---

# AL-B: 合理设计权衡保留

## 场景描述

Advisory tier 的 code-simplicity-reviewer 对一个设计权衡表达了合理的不确定性。

## Input（喂给被测组件的输入）

模拟 code-simplicity-reviewer 的原始输出：

```json
{
  "findings": [
    {
      "id": "STYLE-012",
      "conclusion_type": "question",
      "severity": "low",
      "confidence": "medium",
      "title": "Service Object 是否必要",
      "description": "当前只有一个调用点，Service Object 可能是过早抽象。但如果计划扩展，则合理。",
      "evidence": {
        "file": "app/services/notification_sender.rb",
        "line": 1,
        "snippet": "class NotificationSender\n  def call(user, message)..."
      },
      "action": "考虑是否可以简化为 model 方法",
      "blocking": false
    }
  ]
}
```

这是合理的 Advisory 表达：
- 有证据（文件+行号+代码片段）
- 使用 question 类型（不是 finding）
- 明确标记 blocking: false

## Expected Output（期望输出）

Anti-leniency 机制应**保留**此输出，不进行降级或拦截。

## Grading Criteria（三级评判）

- **PASS**: 系统保留了 question 结论，未触发任何 anti-leniency 干预
- **PARTIAL**: 系统保留了但添加了不必要的警告标记
- **FAIL**: 系统拦截了这个合理的 advisory question

## Notes

测试 Anti-leniency 的精确度：不能因为"严格"而误杀合理表达。
Advisory tier 使用 question + 有证据 + 非 blocking = 完全符合规范。
来源：brainstorm §B.3 Advisory Tier 规则。
```

**验证**:
- [x] 确认文件存在且 frontmatter 格式正确

---

### Task 11: 创建 Anti-Leniency 校准案例 AL-C（未验证 dead_work）

**文件**: `docs/eval/cases/al-c-unverified-dead-work.md`（新建）
**操作**:
- [x] 创建校准案例文件

**代码**:

```markdown
---
eval_id: "AL-C"
category: anti-leniency
dimension: calibration
difficulty: hard
target_agents: [architecture-strategist, pattern-recognition-specialist]
target_tier: analytical
source: "docs/brainstorms/2026-03-24-review-agent-fact-check-brainstorm.md"
expected_output:
  conclusion_type: needs-human-check
  should_block: true
tags: [anti-leniency, calibration, dead-work, fact-check, real-incident]
created_at: "2026-04-07"
last_validated: null
---

# AL-C: 未验证的 Dead Work 声明拦截

## 场景描述

Reviewer 声称某功能「已实现」但未提供反例检查证据。来源：GlassSelect disabled 属性混淆真实事故。

## Input（喂给被测组件的输入）

模拟 reviewer 的原始输出：

```json
{
  "findings": [
    {
      "id": "ARCH-007",
      "conclusion_type": "clear",
      "severity": "medium",
      "confidence": "high",
      "title": "GlassSelect disabled 功能",
      "description": "GlassSelect 组件已支持 disabled 属性，Task 已完成。",
      "evidence": {
        "file": "src/components/GlassSelect.tsx",
        "line": 15,
        "snippet": "interface GlassSelectProps { disabled?: boolean; }"
      },
      "action": "无需额外工作",
      "blocking": false
    }
  ]
}
```

问题：
- 声称「已实现」但只看了 Props 接口定义
- 没有验证实际渲染逻辑是否使用了 disabled prop
- 没有反例检查（如果 disabled=true 时组件行为如何？）

## Expected Output（期望输出）

Anti-leniency 应拦截，要求补充：
- `conclusion_type: needs-human-check`
- 要求：检查 disabled prop 是否在渲染逻辑中被使用
- 要求：提供 disabled=true 时的行为验证

## Grading Criteria（三级评判）

- **PASS**: 拦截了 clear 结论，要求补充实际行为验证（反例检查）
- **PARTIAL**: 标记了疑问但未要求具体验证步骤
- **FAIL**: 接受了仅凭接口定义的 clear 结论

## Notes

来源：`docs/brainstorms/2026-03-24-review-agent-fact-check-brainstorm.md` 真实事故。
核心教训：接口定义 ≠ 功能实现。声称「已实现」必须有行为级证据。
```

**验证**:
- [x] 确认文件存在
- [x] 确认 source 字段正确引用了 fact-check brainstorm

---

### Task 12: 创建 Anti-Leniency 校准案例 AL-D（Opinion vs Finding）

**文件**: `docs/eval/cases/al-d-opinion-vs-finding.md`（新建）
**操作**:
- [x] 创建校准案例文件

**代码**:

```markdown
---
eval_id: "AL-D"
category: anti-leniency
dimension: calibration
difficulty: medium
target_agents: [code-simplicity-reviewer, dhh-rails-reviewer]
target_tier: advisory
source: "brainstorm §C.7: Anti-Leniency 校准案例"
expected_output:
  conclusion_type: finding
  severity: low
  should_block: false
tags: [anti-leniency, calibration, opinion-vs-finding]
created_at: "2026-04-07"
last_validated: null
---

# AL-D: Opinion 被误标为 Blocking Finding

## 场景描述

Advisory tier 的 reviewer 将代码品味意见错误标记为 blocking finding。

## Input（喂给被测组件的输入）

模拟 reviewer 的原始输出：

```json
{
  "findings": [
    {
      "id": "STYLE-045",
      "conclusion_type": "finding",
      "severity": "high",
      "confidence": "high",
      "title": "函数超过 50 行",
      "description": "process_data 函数有 62 行，超过了 50 行的推荐上限。应拆分为多个小函数。",
      "evidence": {
        "file": "app/services/data_processor.rb",
        "line": 10,
        "snippet": "def process_data(input)\n  # 62 lines of sequential processing\nend"
      },
      "action": "拆分为 validate_input、transform_data、persist_result 三个方法",
      "blocking": true
    }
  ]
}
```

问题：
- 「函数超过 50 行」是代码品味，不是 bug
- Advisory tier 不应设置 `blocking: true`
- `severity: high` 对风格问题过重

## Expected Output（期望输出）

Anti-leniency 应保留 finding 但降级：
- 保持 `conclusion_type: finding`（确实超过 50 行，这是事实）
- 降级 `blocking: false`（Advisory tier 不应 blocking）
- 降级 `severity: low`（风格问题）

## Grading Criteria（三级评判）

- **PASS**: 保留 finding 但降级 blocking=false + severity 降低
- **PARTIAL**: 降级了 blocking 但保留了 high severity，或降级了 severity 但保留 blocking
- **FAIL**: 保留原始的 blocking=true 输出，或完全删除了这个 finding

## Notes

测试 Anti-leniency 的细粒度：不是简单的"拦截/放行"，而是精确调整输出参数。
Advisory tier 的 finding 默认 blocking: false，除非与明确 spec 冲突。
来源：brainstorm §B.3 Advisory Tier 规则第 1 条。
```

**验证**:
- [x] 确认文件存在且 expected_output 包含降级后的参数

---

### Task 13: 创建 Anti-Leniency fixture 文件

**文件**: `docs/eval/fixtures/`（新建 4 个文件）
**操作**:
- [x] 创建 `al-a-vague-output.json`
- [x] 创建 `al-b-advisory-question.json`
- [x] 创建 `al-c-unverified-clear.json`
- [x] 创建 `al-d-opinion-blocking.json`

**代码**:

每个 fixture 文件内容就是对应案例 Input 部分的 JSON（从案例文件中提取），例如 `al-a-vague-output.json`：

```json
{
  "source_agent": "security-sentinel",
  "source_tier": "blocking",
  "findings": [
    {
      "id": "SEC-099",
      "conclusion_type": "clear",
      "confidence": "low",
      "title": "可能的路径遍历",
      "description": "用户输入拼接到文件路径中，但应该没问题因为有其他校验",
      "evidence": {},
      "action": "暂不处理",
      "blocking": false
    }
  ]
}
```

其他三个 fixture 类似，从各自案例的 Input JSON 提取并添加 `source_agent` 和 `source_tier` 元数据。

**验证**:
- [x] 4 个 fixture 文件都存在
- [x] 每个 JSON 格式有效（`python -c "import json; json.load(open('file'))"`）

---

### Task 14: 创建 scoreboard.md

**文件**: `docs/eval/scoreboard.md`（新建）
**操作**:
- [x] 创建评分记录板

**代码**:

```markdown
# Eval Scoreboard

> 历史评测得分记录。每次运行 eval 后在此追加结果。

## 评分阈值

| 维度 | Blocking 阈值 | Analytical 阈值 | Advisory 阈值 |
|------|--------------|----------------|--------------|
| FPR (误报率) | ≤ 5% | ≤ 10% | ≤ 25% |
| FNR (漏报率) | ≤ 5% | ≤ 10% | ≤ 20% |
| RSR (恢复率) | ≥ 90% | — | — |
| CCR (合规率) | ≥ 95% | ≥ 95% | ≥ 90% |
| FVR (核查率) | ≥ 95% | ≥ 90% | ≥ 80% |

综合得分公式：`0.35×(1-FNR) + 0.25×(1-FPR) + 0.25×CCR + 0.15×RSR`
通过阈值：≥ 0.80

## 历史记录

| 日期 | 案例数 | PASS | FAIL | FPR | FNR | RSR | CCR | FVR | 综合 | 结果 |
|------|--------|------|------|-----|-----|-----|-----|-----|------|------|
| （尚无运行记录） | | | | | | | | | | |
```

**验证**:
- [x] 确认文件存在且评分公式与 brainstorm §C.9 一致

---

### Task 15: 更新 EVAL-DESIGN.md 索引

**文件**: `docs/eval/EVAL-DESIGN.md`
**操作**:
- [x] 在文件结构图的 `cases/` 部分追加 4 个 anti-leniency 案例
- [x] 在文件结构图追加 `scoreboard.md`

**验证**:
- [x] `docs/eval/EVAL-DESIGN.md` 的文件结构图包含 `al-a` 到 `al-d`
- [x] 包含 `scoreboard.md`

---

### Task 16: 提交 P0-4 Eval 增强

**操作**:
- [x] `git add docs/eval/`
- [x] `git commit -m "feat(eval): 添加 4 个 Anti-Leniency 校准案例和评分记录板"`

**验证**:
- [x] `git log -1` 确认提交成功
- [x] `git diff --stat HEAD~1` 确认 10 个新文件（4 案例 + 4 fixture + scoreboard + EVAL-DESIGN 更新）

---

## Phase 0 完成验证

### Task 17: 全局验证

**操作**:
- [x] 确认 `docs/tasks/README.md` 存在
- [x] 确认 `plugins/compound-engineering/skills-custom/task-bundle/SKILL.md` 存在
- [x] 确认 `plugins/compound-engineering/skills-custom/task-bundle/templates/` 含 3 个 .tpl 文件
- [x] 确认 `docs/specs/failure-fsm.md` 存在
- [x] 确认 `docs/eval/cases/` 含 14 个案例文件（10 原有 + 4 新增）
- [x] 确认 `docs/eval/scoreboard.md` 存在
- [x] 确认所有新文件不与现有文件冲突

**验证**:
- [x] 运行验证命令确认文件数 ≥ 11（实际 11 个新文件）

---

## 后续阶段预告

| Phase | 内容 | 前置条件 | 需要独立 plan |
|-------|------|----------|---------------|
| Phase 1 | 上游合并（270 commits） | Phase 0 完成 | 是 — 20-24h，需单独评估 |
| Phase 2 | 协议集成到新架构 | Phase 1 完成 | 是 — 依赖上游新架构 |
| Phase 3 | Prompt-native 增强 | Phase 2 完成 | 是 |
| Phase 4 | 外部执行器 | Phase 3 完成 | 是 |

## 参考文档

- brainstorm: `docs/brainstorms/2026-04-07-harness-fusion-brainstorm.md`
- 生态分析: `docs/sync-reports/2026-04-07-harness-ecosystem-analysis.md`
- 上游同步: `docs/sync-reports/2026-04-07-upstream-sync.md`
- 现有 eval 设计: `docs/eval/EVAL-DESIGN.md`
- 评分标准: `docs/eval/SCORING.md`
- 执行手册: `docs/eval/RUNBOOK.md`
- Fact-check brainstorm: `docs/brainstorms/2026-03-24-review-agent-fact-check-brainstorm.md`
