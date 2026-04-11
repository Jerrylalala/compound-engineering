---
title: "feat: 新增 /ce:ideas 和 /ce:resume 工作流命令"
type: feat
status: completed
date: 2026-04-10
origin: docs/brainstorms/2026-04-10-workflow-chain-ideas-resume-requirements.md
---

# feat: 新增 /ce:ideas 和 /ce:resume 工作流命令

## Overview

为 compound-engineering 插件新增两个工作流命令，填补「创意管理」和「回归入口」缺口：

- **`/ce:ideas`**：合并 ideate + next，统一管理 `IDEAS.md` 停车场。无参数时从停车场选方向，有参数时生成新方向建议
- **`/ce:resume`**：回归项目的唯一入口，读取 git log + IDEAS.md + 最新 active plan，输出三段摘要并引导进入下一步

同时扩展 `ce:brainstorm` 的 handoff，增加「存入 IDEAS.md」选项，使旁支想法不再丢失。

## Problem Frame

独立开发者间歇性回到项目时，面临三个断点：brainstorm 产生的未执行方向散落在各文件（创意断点）、没有"从哪里开始"的统一入口（入口断点）、bug/已知任务被迫经过创意流程（旁路缺失）。详见 origin 文档。

(see origin: docs/brainstorms/2026-04-10-workflow-chain-ideas-resume-requirements.md)

## Requirements Trace

- R1. IDEAS.md：每条一行 + 简要描述 + 来源链接 + 记录日期，目标 < 50 行
- R5. /ce:ideas 无参数：展示 IDEAS.md，推荐优先级最高 2-3 个，引导选择进入 brainstorm
- R6. /ce:ideas 有参数：针对该方向生成新改进建议（原 ideate 行为）
- R7. /ce:ideas 生成新想法后询问是否存入 IDEAS.md
- R8. brainstorm 结束时提示旁支想法是否存入 IDEAS.md
- R9–R13. /ce:resume：读 git log → IDEAS.md → active plan → 三段摘要 + 下一步选项
- R14. /ce:plan 和 /ce:work 可直接调用（链路旁路，不需要代码变更，文档说明即可）

## Scope Boundaries

- IDEAS.md 不自动维护，AI 只在用户确认时写入（见 origin R4）
- /ce:resume 不在每次会话自动触发，只在用户主动调用时运行
- /ce:next 不作为独立命令实现（合并进 /ce:ideas）
- IDEAS.md 不与 GitHub Issues 同步
- 想法老化提醒机制暂不实现（在 IDEAS.md 里有记录，留待未来）

## Context & Research

### Relevant Code and Patterns

- **命令文件格式**：`plugins/compound-engineering/commands/ce/brainstorm.md`——7 行转发结构，name + description + argument-hint + `Invoke skill ... with args: $ARGUMENTS`
- **skill 结构参考**：`plugins/compound-engineering/skills/ce-ideate/SKILL.md`——Phase 0（resume/scope）→ Phase 1-4（research/generate/filter）→ Phase 6（handoff + AskUserQuestion）
- **handoff 规范**：`plugins/compound-engineering/skills/ce-brainstorm/references/handoff.md`——`AskUserQuestion` + `Based on selection:` 行为约束 + 选项格式
- **plan 状态字段**：`docs/plans/*.md` frontmatter 中 `status: active` = 未完成，`status: completed` = 已完成

### Institutional Learnings

docs/solutions/ 中无相关经验记录——本次为全新概念引入。

## Key Technical Decisions

- **`/ce:ideas` 用参数区分行为，不用子命令**：无参数 → 读停车场；有参数 → 生成新想法。理由：与现有命令一致（$ARGUMENTS 转发），避免引入子命令解析复杂度（see origin: §Key Decisions）
- **`/ce:resume` 内联 skill，不复用 ce-ideate**：resume 是只读信息摘要，无创意生成逻辑，单独 skill 文件更清晰，避免与 ideate 混杂
- **brainstorm handoff 轻度扩展**：在现有 `handoff.md` 的 Phase 4.1 选项中追加「存入 IDEAS.md」，而非新建整个 handoff 流程（YAGNI）
- **`/ce:resume` 有 handoff**：虽然是"只读摘要"，但摘要后需引导用户选择下一步（继续上次 / 从 IDEAS.md 选 / 全新开始），所以需要 AskUserQuestion（see origin: R13）

## Open Questions

### Resolved During Planning

- **`/ce:ideas` 无参数 + IDEAS.md 为空时怎么办？**→ 默认触发 ideate 行为（与有参数路径合并），提示用户"IDEAS.md 还没有内容，我来帮你生成第一批想法"
- **`/ce:resume` 如何识别"未完成" plan？**→ 扫描 `docs/plans/` 所有 .md 文件，读取 frontmatter `status` 字段，取 `status: active` 且 `date` 最新的 1-3 个

### Deferred to Implementation

- `ce-ideas` skill 内的 Phase 具体命名和步骤编排（参考 ce-ideate，执行时对齐）
- `ce-resume` git log 解析的具体格式（执行时测试实际输出决定）

## High-Level Technical Design

> *此图说明各组件的关系和数据流，是方向性指导，不是实现规范。*

```
用户调用 /ce:ideas
    │
    ├─ 无参数 ──────→ 读 IDEAS.md
    │                    ├─ 有内容 → 展示 + 推荐 → AskUserQuestion → brainstorm 选中项
    │                    └─ 空    → 触发 ideate 路径（生成新想法）
    │
    └─ 有参数 ──────→ ideate 路径（生成新方向）
                        └─ handoff: 是否存入 IDEAS.md？→ 写入 / 跳过

用户调用 /ce:resume
    │
    ├─ 读 git log --oneline -10（最近提交摘要）
    ├─ 读 IDEAS.md（停车场条目数量 + 前 3 条预览）
    ├─ 扫描 docs/plans/*.md → 取 status:active 最新 1-3 个
    │
    └─ 输出三段摘要 → AskUserQuestion（继续上次 / IDEAS.md 选 / 全新开始）
```

---

## Implementation Units

- [x] **Unit 1: `/ce:ideas` 命令文件**

**Goal:** 创建命令入口，将 `/ce:ideas` 转发到新 `ce-ideas` skill

**Requirements:** R5, R6, R7

**Dependencies:** Unit 2（ce-ideas skill）必须先存在，但命令文件可同步创建

**Files:**
- Create: `plugins/compound-engineering/commands/ce/ideas.md`

**Approach:**
- 遵循现有 7 行命令文件格式
- `description` 使用 `"0.5: 管理想法停车场 IDEAS.md，无参数时从停车场选方向，有参数时生成新方向"`
- `argument-hint` 使用 `"[功能方向或关注点，留空则从 IDEAS.md 选]"`

**Patterns to follow:**
- `plugins/compound-engineering/commands/ce/brainstorm.md`（直接参考）
- `plugins/compound-engineering/commands/ce/ideate.md`（同类型命令）

**Test scenarios:**
- Test expectation: none — 纯转发文件，逻辑在 skill 中验证

**Verification:**
- `plugins/compound-engineering/commands/ce/ideas.md` 存在，格式与其他命令文件一致

---

- [x] **Unit 2: `ce-ideas` skill**

**Goal:** 实现 /ce:ideas 的核心逻辑：无参数读停车场选方向，有参数生成新方向，结束时询问是否存入 IDEAS.md

**Requirements:** R5, R6, R7, R8（R8 在 Unit 4 实现，此处只处理 ideas 流程）

**Dependencies:** 无

**Files:**
- Create: `plugins/compound-engineering/skills/ce-ideas/SKILL.md`

**Approach:**

Phase 0（路由）：
- 检测 `$ARGUMENTS` 是否为空
- 空 → Phase 1A（停车场路径）
- 非空 → Phase 1B（生成路径）

Phase 1A（停车场选择）：
- 读取 `IDEAS.md`
- 若为空 → 跳转 Phase 1B，提示"IDEAS.md 还没有内容，帮你生成第一批想法"
- 若有内容 → 展示全部条目（带序号），对未完成条目按「已等待时间 + 来源文件是否存在」简单排序，推荐前 2-3 个
- AskUserQuestion：选择一个条目 / 生成新想法 / 退出

Phase 1B（生成路径）：
- 参考 `ce-ideate` 的 Phase 1-4 逻辑：扫描仓库 → 生成候选 → 批判过滤 → 排序输出
- 若 `$ARGUMENTS` 为空（从 Phase 1A 跳转来），提示用户描述关注方向

Phase 2（handoff）：
- 用户已选或已生成某个方向后：
  - 询问是否存入 IDEAS.md（若该条目不在 IDEAS.md 中）
  - 若存入：追加到 `IDEAS.md`，格式：`- [ ] **[标题]**：[1句描述]\n  来源：[当前日期自动]`
  - 引导进入 brainstorm：`Invoke skill compound-engineering:ce-brainstorm with args: [选中方向]`

**Patterns to follow:**
- `plugins/compound-engineering/skills/ce-ideate/SKILL.md`（Phase 结构参考）
- handoff 使用 AskUserQuestion + `Based on selection:` 约束（参考 handoff.md）

**Test scenarios:**
- Happy path A：IDEAS.md 有内容，无参数调用 → 展示条目 → 选中一个 → 跳入 brainstorm
- Happy path B：有参数调用 → 生成新方向 → 存入 IDEAS.md → 跳入 brainstorm
- Edge case：IDEAS.md 不存在或为空 + 无参数 → 触发生成路径，提示内容
- Edge case：用户在 handoff 选"不存入 IDEAS.md" → 直接跳入 brainstorm，不写文件

**Verification:**
- 无参数调用时，能读取并展示 IDEAS.md 内容
- 有参数调用时，能生成至少 3 个方向建议
- handoff 询问"存入 IDEAS.md？"并在确认后正确追加

---

- [x] **Unit 3: `/ce:resume` 命令文件**

**Goal:** 创建命令入口，将 `/ce:resume` 转发到 `ce-resume` skill

**Requirements:** R9–R13

**Dependencies:** Unit 4（ce-resume skill）

**Files:**
- Create: `plugins/compound-engineering/commands/ce/resume.md`

**Approach:**
- 同 Unit 1，7 行转发格式
- `description`：`"回归项目入口：读取最近 git log、IDEAS.md 和 active plan，输出三段摘要"`
- 无 argument-hint（此命令不接受参数）

**Patterns to follow:**
- `plugins/compound-engineering/commands/ce/brainstorm.md`

**Test scenarios:**
- Test expectation: none — 纯转发文件

**Verification:**
- `plugins/compound-engineering/commands/ce/resume.md` 存在，格式正确

---

- [x] **Unit 4: `ce-resume` skill**

**Goal:** 实现 /ce:resume 核心逻辑：三个数据源聚合 → 三段摘要输出 → 引导下一步

**Requirements:** R9, R10, R11, R12, R13

**Dependencies:** 无（只读操作）

**Files:**
- Create: `plugins/compound-engineering/skills/ce-resume/SKILL.md`

**Approach:**

Phase 1（数据收集，并行读取三个来源）：
- **来源 A**：`git log --oneline -10`，提取最近 10 条提交，识别最后一个功能性 commit（跳过 chore/docs）
- **来源 B**：读取 `IDEAS.md`，统计未完成条目数量（`- [ ]` 数量），提取前 3 条标题
- **来源 C**：扫描 `docs/plans/*.md` frontmatter，筛选 `status: active` 且 `date` 最新的 1-3 个，提取 title + date

Phase 2（三段摘要输出）：
```
## 上次做了什么
[最近功能性 commit 的描述，1-2 句]

## 有什么在等待
IDEAS.md：N 个未执行想法（预览前 3 条标题）
Active plan：[plan title] (YYYY-MM-DD)

## 建议下一步
[基于数据推断：若有 active plan → 继续该 plan；若无 → 从 IDEAS.md 选；若两者都空 → 全新开始]
```

Phase 3（handoff）：
- AskUserQuestion 三个选项（参考 R13）：
  1. 继续上次任务（若有 active plan）→ `Invoke skill ce-plan` 或直接 `ce:work`
  2. 从 IDEAS.md 选方向 → `Invoke skill ce-ideas`
  3. 全新开始 → `Invoke skill ce-ideate` 或 `ce-brainstorm`

**边界处理**：
- `docs/plans/` 目录不存在 → 跳过来源 C，摘要中注明"尚无规划文档"
- `IDEAS.md` 不存在 → 摘要中注明"IDEAS.md 为空"，建议运行 `/ce:ideas`
- git log 失败（非 git 仓库）→ 跳过来源 A，注明"无法读取 git 历史"

**Patterns to follow:**
- `plugins/compound-engineering/skills/ce-brainstorm/references/handoff.md`（AskUserQuestion + Based on selection 结构）
- phase 结构参考 `ce-ideate` 的 Phase 0 + 6

**Test scenarios:**
- Happy path：三个来源都有数据 → 输出完整三段摘要 → 用户选"继续上次" → 正确跳转
- Edge case：IDEAS.md 为空 + 无 active plan → 摘要仅有 git log 段 → 建议全新开始
- Edge case：docs/plans/ 目录不存在 → 摘要跳过 active plan 段，不报错
- Edge case：git log 失败（无 git 仓库）→ 跳过来源 A，摘要仍正常输出

**Verification:**
- 输出始终包含三段（即使某段为空占位提示）
- AskUserQuestion 选项始终出现，选项数量根据数据动态调整（无 active plan 时不显示"继续上次"）

---

- [x] **Unit 5: 扩展 brainstorm handoff，增加「存入 IDEAS.md」选项**

**Goal:** 在 brainstorm 结束时，允许用户把本次旁支想法或未采纳方向存入 IDEAS.md

**Requirements:** R8

**Dependencies:** Unit 2（IDEAS.md 写入格式定义完成后对齐）

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-brainstorm/references/handoff.md`

**Approach:**
- 在 Phase 4.1 的选项列表末尾追加新选项（在"Done for now"之前）：
  - **「存入 IDEAS.md」**：将本次探索中未采纳的方向或旁支想法存入 `IDEAS.md`，格式与 Unit 2 一致
- 在 Phase 4.2 增加对应 handler：读取对话中的旁支想法，展示供用户确认，写入 IDEAS.md
- 该选项不中断主流程：存入后返回 Phase 4.1，继续其他选项

**Patterns to follow:**
- handoff.md 现有选项格式（加粗选项名 + 一句描述）
- Phase 4.2 existing handler 格式

**Test scenarios:**
- Happy path：brainstorm 产生旁支想法 → 用户选"存入 IDEAS.md" → AI 展示待存条目 → 确认 → 写入 → 返回 Phase 4.1
- Edge case：brainstorm 没有旁支想法 → 该选项仍展示 → 用户选择 → AI 提示"本次 brainstorm 无额外想法可存"
- Edge case：IDEAS.md 不存在 → 自动创建（带标准头部注释）再写入

**Verification:**
- handoff.md 中新增选项存在，格式与现有选项一致
- 写入 IDEAS.md 的内容符合 R1 格式要求（标题 + 描述 + 日期）

---

## System-Wide Impact

- **入口变化**：`/ce:ideate` 仍保留（单独触发 ideate），`/ce:ideas` 是新入口，两者并存不冲突
- **IDEAS.md 写入点**：Unit 2（ce-ideas handoff）和 Unit 5（brainstorm handoff）两处写入，格式需保持一致（在 Unit 2 实现时定义，Unit 5 对齐）
- **不变量**：`ce:brainstorm`、`ce:plan`、`ce:work`、`ce:review`、`ce:compound` 核心逻辑不变；`/ce:ideate` 命令和 skill 不变
- **handoff.md 是共享文件**：修改 brainstorm handoff 会影响所有调用 brainstorm 的场景，需确保新选项不干扰现有选项逻辑

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| ce-ideas skill 与 ce-ideate skill 功能重叠，用户不知道选哪个 | CLAUDE.md 和 README 明确说明：`/ce:ideas` = 管理停车场（有 IDEAS.md 时优先用）；`/ce:ideate` = 从零生成新方向（无停车场时或想全新探索时用） |
| handoff.md 修改影响所有 brainstorm 用户 | 新选项在列表末尾追加，不修改现有选项，最小化影响 |
| /ce:resume git log 解析在不同平台输出不同 | 使用 `--oneline` 标准格式，只取 subject 行，不依赖具体格式细节 |

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-10-workflow-chain-ideas-resume-requirements.md](docs/brainstorms/2026-04-10-workflow-chain-ideas-resume-requirements.md)
- Related skill: `plugins/compound-engineering/skills/ce-ideate/SKILL.md`
- Related handoff: `plugins/compound-engineering/skills/ce-brainstorm/references/handoff.md`
- Related commands: `plugins/compound-engineering/commands/ce/`
