---
name: workflows-brainstorm
description: 探索需求和方案，支持 [P]/[P+] 多视角讨论，并写出可继续规划的 brainstorm 文档
---

# workflows-brainstorm

用于在实现前澄清做什么，而不是直接进入编码。

这是 Codex 中的 brainstorm 主入口。它不尝试复刻 Claude Code 的完整运行时，而是用明确状态机保留高价值能力：

- `[P]` 触发 3 个核心视角的多轮讨论
- `[P+]` 触发 8-12 个视角的深度发散和挑战收敛
- `[R]` 强制历史经验检索；未传 `[R]` 时，Standard/Deep 场景自动做历史检索
- 每轮后等待用户选择继续、换视角或收敛
- 写出可继续交给 `$workflows-plan` 的 brainstorm 文档

不要调用 Codex CLI。
不要调用 Gemini CLI。

## 目标

通过协作对话、轻量仓库研究、历史经验检索和方案比较，产出一份可继续规划的 brainstorm 文档：

`docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

## 输入

- 功能想法
- 问题描述
- 改进方向
- 可选参数：
  - `[P]`：3 个核心视角，适合普通复杂度
  - `[P+]`：8-12 个视角，适合模糊、高风险或架构性问题
  - `[R]`：强制检索 `docs/solutions/` 历史经验

如果用户没有给出清晰主题，先追问，不要直接写文档。

如果用户传入旧的外部 AI 咨询标记，只说明本 Codex brainstorm 入口不处理外部 AI 咨询，清洗掉该标记后继续主流程。

## 参数解析

开始时先解析参数，并向用户回显：

- `PARTY_MODE = none|quick|deep`
- `HISTORICAL_RESEARCH = auto|force|skip`
- 清洗后的功能描述

规则：

- 包含 `[P+]` -> `PARTY_MODE = deep`
- 包含 `[P]` -> `PARTY_MODE = quick`
- 包含 `[R]` -> `HISTORICAL_RESEARCH = force`
- 未包含 `[R]` 时，先按 Phase 0 判断范围；Standard/Deep 软件或仓库改动场景使用 `HISTORICAL_RESEARCH = auto`
- Lightweight 且无历史相关信号时可设为 `skip`
- 解析后从功能描述中移除所有参数标记
- 如果检测到用户把一长段对话历史、系统标签或工具输出粘进参数里，要先让用户重新给出一句简洁描述

## Phase 0: 范围判断

先判断是否真的需要 brainstorm：

- **Lightweight**：目标清楚、范围小、低风险；可以短讨论后直接写简短文档或建议进入 `$workflows-plan`
- **Standard**：正常功能、流程、体验或工具改进；需要完整覆盖矩阵
- **Deep**：跨模块、架构、工作流、运行时适配、高风险或需求模糊；建议自动提升到 `[P+]` 级别，即使用户只传 `[P]`

如果需求已经非常清晰，不要硬拖长讨论；但仍要确认是否需要持久化 brainstorm 文档。

## Phase 1: 本地上下文与历史检索

### 1.1 仓库上下文

先做轻量研究，了解：

- 是否已有相近实现
- 项目里是否已有类似模式
- 是否有现成约束或历史决策
- 本次改动可能影响哪些文档协议或工作流入口

如果 `$repo-research-analyst` 可用，优先使用它。
如果不可用，直接用本地搜索完成同等最小研究：`rg` 查主题关键词、相关 skill、相关 docs、相关 tests。

### 1.2 历史经验检索

`[R]` 的含义是：强制查历史经验。它不是联网搜索，也不是外部 AI 咨询。

历史检索来源：

- `docs/solutions/`
- `docs/brainstorms/`
- `docs/plans/`

执行规则：

- `HISTORICAL_RESEARCH = force`：必须检索
- `HISTORICAL_RESEARCH = auto`：Standard/Deep 场景自动检索
- `HISTORICAL_RESEARCH = skip`：只在 Lightweight 或明显无历史价值时跳过

如果 `$learnings-researcher` 可用，自动运行 `$learnings-researcher`。
如果不可用，用 `rg` 搜索 `docs/solutions/` 和相关文档，提炼 3-5 条历史约束、坑点或可复用经验。

输出到后续讨论时，标注：

- 已命中的历史文档
- 可复用经验
- 与当前想法冲突或需要避开的坑
- 没有命中时写明 `No relevant learnings found`

## Phase 2: 协作对话

### 2.1 默认模式

如果 `PARTY_MODE = none`：

- 一次只问一个问题
- 先问用户已经想过什么，避免 AI 过早锚定
- 按覆盖矩阵逐步补齐缺口
- 当用户表达“继续”“proceed”“写文档”时进入 Phase 3

### 2.2 Party Mode

如果 `PARTY_MODE = quick`：

- 选择 3 个核心视角：用户代言人、技术负责人、魔鬼代言人
- 最少 2 轮：第一轮发散，第二轮挑战和补洞
- 除非用户明确要求结束，不要一轮后直接写文档

如果 `PARTY_MODE = deep`：

- 选择 8-12 个视角，按批次发言，避免一次输出过载
- 推荐视角：产品、用户、架构、开发、QA、安全、性能、运维、极简主义、反向思考、历史经验、文档/交付
- 最少 3 轮：发散、冲突、收敛
- 每轮都要明确新增了什么信息，避免重复观点

每轮讨论必须包含：

- 当前推荐方向
- 主要分歧
- 风险与边界
- 更简单方案
- 历史经验或现有模式的影响
- 下一轮应该追问的问题

每轮结束后必须暂停，向用户提供编号选项并等待回应：

1. 继续当前方向再深入一轮
2. 换一组视角看同一问题
3. 收敛成 2-3 个方案
4. 结束讨论并写 brainstorm 文档

只有用户明确选择收敛、结束、进入计划，或只给出纯执行指令时，才退出 Party Mode。

## Phase 3: 覆盖矩阵

在写方案前检查覆盖矩阵。不要只因为已经有几个角色发言就宣布完成。

| 维度 | 必须回答的问题 |
|------|----------------|
| Problem | 真正要解决的问题是什么？不做会怎样？ |
| Users | 谁受影响？他们当前如何完成这件事？ |
| Outcome | 成功标准是什么？如何判断体验变好？ |
| Scope | 本轮做什么，不做什么？ |
| Constraints | 有哪些技术、流程、时间或兼容约束？ |
| Existing Patterns | 仓库里有哪些相近实现、协议或约定？ |
| Historical Lessons | 历史文档里有哪些坑、决策或可复用经验？ |
| Alternatives | 至少 2 个可行方案和 1 个更简单方案是什么？ |
| Risks | 失败模式、边界条件、长期维护成本是什么？ |
| Open Questions | 哪些问题必须现在问用户，哪些可交给 plan 阶段？ |

如果任一关键维度为空，优先补问用户或补做本地研究，不要直接写文档。

## Phase 4: 方案比较

基于研究与对话，提出 2-3 个具体方案。

每个方案至少要写：

- 简要描述
- 优点
- 缺点
- 适用场景
- 风险和未知
- 与历史经验或现有模式的关系

要明确给出推荐方案，并解释为什么。

如果其中一个方案明显过度工程，要指出它的维护成本。
如果存在低成本高收益的增强项，可以作为 challenger option，而不是默认方案。

## Phase 5: 完成度门禁

写文档前执行完成度门禁。

只有全部满足时，才能写入 brainstorm 文档：

- 问题框架清楚
- 目标用户或受影响对象清楚
- 成功标准清楚
- 范围边界清楚
- 至少比较过 2 个方案，或解释为什么只有 1 个方案有意义
- 历史经验已检索或明确跳过理由
- Party Mode 的共识和分歧已记录
- `Resolve Before Planning` 中没有仍需用户裁决的阻塞问题

如果门禁未通过：

- 继续问一个最关键问题
- 或把问题放入 `Resolve Before Planning`
- 不要输出“Brainstorm complete”

## Phase 6: 写回 brainstorm 文档

写入：

`docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

如果已存在同主题文档，不要直接覆盖。
应先让用户决定：

1. 续接已有文档
2. 新建新文档
3. 先查看已有内容

文档至少包含以下章节：

- `## What We're Building`
- `## Problem Frame`
- `## Why This Approach`
- `## Approaches Considered`
- `## Key Decisions`
- `## Scope Boundaries`
- `## Historical Context`
- `## Open Questions`
- `## Next Step`

如果启用 Party Mode，还必须补充：

- `## Party Mode Summary`
- `## Areas Of Agreement`
- `## Areas Of Disagreement`
- `## Coverage Matrix`

文档要简洁，但必须保留：

- 选择了什么
- 为什么这样选
- 放弃了什么
- 还有什么待定问题
- 哪些问题必须在计划前解决

## Phase 7: 输出摘要与下一步

完成后向用户展示：

- brainstorm 文件路径
- 关键决策
- 仍然开放的问题
- 是否可以进入 `$workflows-plan`

如果仍有 `Resolve Before Planning` 问题，不要建议直接进入计划；建议继续 `$workflows-brainstorm` 解决阻塞问题。

## 约束

- 不要开始编码
- 不要写实现细节，除非 brainstorm 本身就是技术/架构决策
- 重点是 WHAT，不是 HOW
- 不要把 Party Mode 变成无结论闲聊
- 不要在用户没有明确结束时一轮后自动收束
- 不要把未验证的仓库现状写成事实
