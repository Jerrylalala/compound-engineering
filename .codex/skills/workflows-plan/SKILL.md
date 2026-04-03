---
name: workflows-plan
description: 基于需求或 brainstorm 产出 Claude 可执行、风险明确、任务原子化的计划文档
---

# workflows-plan

用于把功能描述或 brainstorm 结果转成 Claude 可继续执行的 plan 文档。

这是 Codex 中的 plan 主入口。目标不是做一篇泛泛的分析报告，而是产出一份真正能交给 Claude `/workflows:work` 继续执行的计划。

**铁律**：输出必须优先满足 Claude `/workflows:work` 的消费协议，而不是追求漂亮或自由发挥的文风。

## 目标

写入：

`docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

并确保格式兼容 Claude 的 `/workflows:work`。

## 输入

- 功能描述
- bug 描述
- 改进需求
- 或已有 brainstorm 的主题

## 执行步骤

1. 先检查 `docs/brainstorms/` 下是否有相关 brainstorm。
2. 如果有相关 brainstorm：
   - 读取并沿用其中的关键决策、约束、开放问题
3. 如果没有：
   - 通过简短对话补足目的、范围、约束、成功标准
4. 进行本地研究：
   - 现有模式
   - 相关文件
   - 项目约束
   - 已有经验文档
5. 基于风险、上下文清晰度和现有模式决定是否需要外部研究。
6. 生成计划文档。

## 研究策略

优先做本地研究：

- `$repo-research-analyst`
- `$learnings-researcher`

仅在这些情况下补做外部研究：

- 安全、支付、隐私、外部 API 等高风险主题
- 仓库里没有相似实现
- 技术选型明显不确定

外部研究优先调用：

- `$best-practices-researcher`
- `$framework-docs-researcher`

## 必须保留的高价值能力

### 1. Brainstorm 继承

如果存在相关 brainstorm，不要只把它当参考。
必须显式继承：

- 关键决策
- 被否决方案
- 约束
- 开放问题
- 成功标准

必要时在计划正文中引用 brainstorm 路径。

### 2. 任务原子化

每个任务应尽量控制在 2-5 分钟级别。

禁止出现这种大任务：

- “实现整个认证系统”
- “完成前端重构”
- “修复所有 bug”

必须拆成原子任务。

### 3. 风险评估

写入计划前必须做风险评估，并生成：

- `risk_score`
- `risk_level`
- `risk_note`

至少从这些维度考虑：

- 安全/隐私
- 可逆性
- 影响范围
- 变更规模
- 外部依赖

### 4. 可执行验证

每个任务都应包含可执行验证，而不是模糊表述。

例如：

- 运行某个测试命令
- 打开某个页面验证行为
- 查看某个文件输出
- 检查某个日志或状态

## 计划格式要求

### 1. 文件名必须固定模式

必须写到：

`docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

要求：

- `type` 只能是 `feat`、`fix`、`refactor`
- `<descriptive-name>` 必须具体，不要用 `thing`、`feature`、`update` 这类空名字
- 文件名必须可搜索
- 不允许省略日期前缀

### 2. frontmatter 必须固定输出

frontmatter 必须包含：

```yaml
---
risk_score: 0
risk_level: low
risk_note: "主要风险描述"
plan_protocol: executable_checkboxes_v1
source_brainstorm: docs/brainstorms/...   # 如果有
---
```

要求：

- `risk_score` 必须是 0-10 整数
- `risk_level` 必须是 `low|medium|high`
- `risk_note` 必须是单句风险摘要
- `plan_protocol` 必须是 `executable_checkboxes_v1`
- 如果本计划基于 brainstorm，必须写 `source_brainstorm`

### 3. Header 必须固定输出

正文必须包含：

```md
## Overview

**Goal**: ...
**Tech Stack**: ...
**Architecture**: ...
```

要求：

- `## Overview` 必须出现
- `**Goal**:` 必须出现
- `**Tech Stack**:` 必须出现
- `**Architecture**:` 强烈建议出现；如果确实简单到不需要，也要用一句话说明采用的方式

### 4. 任务块必须固定结构

任务必须使用可勾选格式，并尽量原子化：

````md
### Task 1: ...

**文件**: `path/to/file`
**操作**:
- [ ] ...
- [ ] ...

**代码**:
```language
...
```

**验证**:
- [ ] 运行 `...`
````

要求：

- 每个任务标题必须是 `### Task N: ...`
- 必须包含 `**文件**`
- 必须包含 `**操作**`
- 必须包含 `**代码**`
- 必须包含 `**验证**`
- `**操作**` 下必须至少有一个真实 `- [ ]`
- `**验证**` 下必须至少有一个真实 `- [ ]`
- 不允许把一整个功能写成一个大 Task
- 如果某任务没有明确代码片段，也要写出目标修改形式，不能空着

### 4.1 可执行 checkbox 协议

最终写入 `docs/plans/*.md` 的活状态 checkbox 必须满足：

- 只能出现在 `### Task N:` 任务块内部
- 只能出现在该任务的 `**操作**` 或 `**验证**` 下
- 任务块之外的说明性内容、验收标准、注释、补充说明，优先使用普通列表 `-`
- 不要把模板示例、占位说明、`未检查 [具体内容]` 这类演示性 checkbox 写入最终 plan
- 已完成项之后如果发现返工需求，新增 follow-up task，不要把 `- [x]` 改回 `- [ ]`

共享协议见：`docs/specs/executable-plan-protocol.md`

### 5. Claude work 兼容检查（写完后必须自检）

在输出最终计划前，必须逐项自检：

- [ ] 文件是否在 `docs/plans/`
- [ ] frontmatter 是否包含 `risk_score`
- [ ] frontmatter 是否包含 `risk_level`
- [ ] frontmatter 是否包含 `plan_protocol: executable_checkboxes_v1`
- [ ] 是否包含 `## Overview`
- [ ] 是否包含 `**Goal**`
- [ ] 是否包含 `**Tech Stack**`
- [ ] 是否包含至少一个 `### Task N`
- [ ] 是否包含真实未完成 checkbox `- [ ]`
- [ ] 每个 Task 是否都有 `文件 / 操作 / 代码 / 验证`
- [ ] 活状态 checkbox 是否只出现在任务块的 `操作 / 验证` 下
- [ ] 是否避免把模板或示例性 checkbox 写进最终 plan

如果任一项不满足，不要输出“计划已完成”，先修正文档。

## 质量要求

- 计划必须让 Claude 后续可以继续执行
- 不要写成纯分析报告
- 必须有真实 `- [ ]`
- 文件路径尽量具体
- 验证步骤必须可执行
- 标题、文件名、任务描述都要可搜索
- 如果计划过大，应主动收敛范围或拆阶段
- 不要遗漏 brainstorm 中的关键结论
- 不要把开放问题伪装成已决事项

## 输出顺序要求

最终对用户的输出必须按这个顺序：

1. 写入 plan 文件
2. 自检 Claude work 兼容性
3. 告知：
   - `plan_path`
   - `risk_score / risk_level`
   - 是否建议直接交给 Claude `/workflows:work`

不要只在聊天里给计划摘要却不落盘。

## 输出后的处理

完成后要向用户明确说明：

- 计划路径
- 风险等级
- 计划是否更适合直接执行，还是先审查

如果用户下一步是执行，提醒其回到 Claude：

`/workflows:work <plan_path>`

如果用户下一步是继续审视计划，可在 Codex 内继续微调，但不要把执行层模拟成完整的 Claude workflow。

## 完成后的引导

完成后告诉用户：

- plan 文件路径
- 风险等级
- 如果要执行，实现阶段应回到 Claude 使用：

```text
/workflows:work <plan_path>
```

如果用户只是想继续完善方案，可以继续修改 plan，但不要在 Codex 中把执行层冒充成 Claude 的 `/workflows:work`。
