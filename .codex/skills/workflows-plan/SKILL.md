---
name: workflows-plan
description: 基于需求或 brainstorm 产出 Claude 可执行、风险明确、任务原子化的计划文档
---

# workflows-plan

用于把功能描述或 brainstorm 结果转成 Claude 可继续执行的 plan 文档。

这是 Codex 中的 plan 主入口。目标不是做一篇泛泛的分析报告，而是产出一份真正能交给 Claude `/workflows:work` 继续执行的计划。

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

frontmatter 必须包含：

```yaml
---
risk_score: 0
risk_level: low
risk_note: "主要风险描述"
---
```

正文必须包含：

```md
## Overview

**Goal**: ...
**Tech Stack**: ...
**Architecture**: ...
```

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

## 质量要求

- 计划必须让 Claude 后续可以继续执行
- 不要写成纯分析报告
- 必须有真实 `- [ ]`
- 文件路径尽量具体
- 验证步骤必须可执行
- 标题、文件名、任务描述都要可搜索
- 如果计划过大，应主动收敛范围或拆阶段

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
