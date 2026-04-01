---
name: workflows-plan
description: 基于需求或 brainstorm 产出 Claude 可执行的计划文档
---

# workflows-plan

用于把功能描述或 brainstorm 结果转成 Claude 可继续执行的 plan 文档。

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
5. 只在确实必要时做外部研究。
6. 生成计划文档。

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

## 完成后的引导

完成后告诉用户：

- plan 文件路径
- 风险等级
- 如果要执行，实现阶段应回到 Claude 使用：

```text
/workflows:work <plan_path>
```

如果用户只是想继续完善方案，可以继续修改 plan，但不要在 Codex 中把执行层冒充成 Claude 的 `/workflows:work`。
