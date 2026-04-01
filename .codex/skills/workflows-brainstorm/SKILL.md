---
name: workflows-brainstorm
description: 探索需求和方案，支持 [P] 多视角讨论，并写出可继续规划的 brainstorm 文档
---

# workflows-brainstorm

用于在实现前澄清做什么，而不是直接进入编码。

这是 Codex 中的 brainstorm 主入口，目标是保留原始 workflow 中最重要的能力：

- 参数 `[P]` 触发多视角讨论
- 调用 `party-mode`
- 多代理协作
- 明确退出条件
- 将讨论结果回写到 brainstorm 文档

## 目标

通过协作对话、轻量仓库研究和方案比较，产出一份可继续规划的 brainstorm 文档：

`docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

## 输入

- 功能想法
- 问题描述
- 改进方向
- 可选参数：`[P]` 表示启用多视角讨论

如果用户没有给出清晰主题，先追问，不要直接写文档。

## 参数解析

开始时先解析参数，并向用户回显：

- `PARTY_MODE = true|false`
- 清洗后的功能描述

规则：

- 如果包含 `[P]` 或用户明确说“开启派对模式”“多视角讨论”“听听专家意见”，则 `PARTY_MODE = true`
- 解析后要把 `[P]` 从功能描述中移除
- 如果检测到用户把一长段对话历史、系统标签或工具输出粘进参数里，要先让用户重新给出一句简洁描述

## 需求已清晰时的处理

如果用户需求已经足够明确，不要硬拖入长讨论。直接说明：

- 需求看起来已经清晰
- 可以继续 brainstorm 细化
- 也可以直接进入 `$workflows-plan`

## 执行步骤

### Phase 1: 轻量仓库研究

先做轻量研究，了解：

- 是否已有相近实现
- 项目里是否已有类似模式
- 是否有现成约束或历史决策

优先调用：

- `$repo-research-analyst`

如果话题明显涉及复杂功能设计、现有模式或历史经验，也可以补充：

- `$learnings-researcher`

### Phase 2: 协作对话

#### 默认模式

如果 `PARTY_MODE = false`：

- 一次只问一个问题
- 优先澄清：
  - 目标
  - 用户/对象
  - 约束
  - 成功标准
  - 边界与不做什么
- 持续到：
  - 需求已经清晰
  - 或用户说“继续”“proceed”

#### Party Mode

如果 `PARTY_MODE = true`：

立即切入多视角讨论，并明确告诉用户已进入 Party Mode。

执行方式：

- 加载 `$party-mode`
- 让 2-3 个最相关视角参与讨论

选择原则：

- 至少一个主视角负责当前话题的核心判断
- 至少一个互补视角负责约束、风险或用户价值
- 如有必要，加入第三个异议视角制造张力

每轮讨论至少覆盖：

- 推荐方向
- 主要分歧
- 风险与边界
- 是否存在更简单方案

### Party Mode 退出条件

退出必须基于明确意图，默认继续讨论。

继续讨论：

- 用户还在追问、比较、追加约束
- 用户表达“但是”“另外”“那如果”
- 用户要求再看看别的方案

退出：

- 用户明确输入 `[E]`
- 用户明确说“结束派对”“exit”
- 用户明确要求进入计划阶段
- 用户只给出纯执行指令，不再继续探索

### Phase 3: 方案比较

基于研究与对话，提出 2-3 个具体方案。

每个方案至少要写：

- 简要描述
- 优点
- 缺点
- 适用场景

要明确给出推荐方案，并解释为什么。

### Phase 4: 结果写回 brainstorm 文档

写入：

`docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

如果已存在同主题文档，不要直接覆盖。
应先让用户决定：

- 续接
- 新建
- 先查看已有内容

如果本轮启用了 Party Mode，文档中必须额外写出：

- 参与视角/角色
- 共识点
- 分歧点
- 最终结论

### Phase 5: 输出摘要

完成后向用户展示：

- 文档路径
- 关键决策
- 未决问题
- 下一步建议：`$workflows-plan`

## 文档要求

文档至少包含以下章节：

- `## What We're Building`
- `## Why This Approach`
- `## Approaches Considered`
- `## Key Decisions`
- `## Open Questions`
- `## Next Step`

文档要简洁，但必须保留：

- 选择了什么
- 为什么这样选
- 放弃了什么
- 还有什么待定问题

如果启用 Party Mode，还必须补充：

- `## Party Mode Summary`
- `## Areas Of Agreement`
- `## Areas Of Disagreement`

## 约束

- 不要开始编码
- 不要写实现细节
- 重点是 WHAT，不是 HOW
- 不要把 Party Mode 变成无结论闲聊
- 如果讨论已经收敛，要主动推动进入文档化

## 完成后的引导

完成后告诉用户：

- brainstorm 文件路径
- 关键决策摘要
- 下一步建议使用 `$workflows-plan`
