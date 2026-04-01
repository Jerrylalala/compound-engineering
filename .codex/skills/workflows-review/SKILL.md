---
name: workflows-review
description: 对代码、分支或计划进行多角度结构化审查，输出 findings、风险与建议
---

# workflows-review

用于在 Codex 中做审查，而不是执行实现。

这是 Codex 中的 review 主入口。目标不是简单写几条意见，而是做出可信、可排序、可继续处理的结构化审查。

## 适用对象

- 当前分支改动
- 指定 PR / 分支
- 指定 plan 文档

## 输出原则

- findings first
- 按严重性排序
- 明确区分已验证问题与假设
- 尽量给出文件引用

## 审查步骤

1. 明确审查目标：
   - 当前分支
   - 指定 PR / 分支
   - plan 文档
2. 查看 diff、相关文件和上下文。
3. 从这些角度审查：
   - 正确性
   - 风险与回归
   - 复杂度
   - 性能
   - 安全
   - 与现有模式的一致性
4. 如果是 plan 审查，还要检查：
   - 是否可执行
   - 是否原子化
   - 是否缺少验证步骤
   - 是否缺少关键风险说明

## 高价值能力

### 1. 多角度审查

至少从这些角度扫描：

- 正确性
- 风险与回归
- 架构一致性
- 性能
- 安全
- 简化空间

如果范围较大，可以显式调用相关专长技能或子代理，但最终必须统一整合成一份 review 结果。

### 2. Findings 优先

默认以 findings 开头，而不是先写总结。

每条 finding 尽量包含：

- 严重性
- 问题描述
- 影响
- 文件或位置
- 为什么这是真问题

### 3. 保护工件

不得建议删除：

- `docs/plans/*.md`
- `docs/solutions/*.md`

如果某个审查思路会导向“这些文档应删除”，要主动丢弃该建议。

### 4. Plan 审查专用检查

如果目标是 plan，还要检查：

- 是否能交给 Claude 执行
- 是否缺少 checkbox
- 是否缺少 `## Overview`
- 是否缺少 `Goal / Tech Stack`
- 是否把任务写得过大
- 是否缺少具体验证

### 5. 输出可信度

不要把猜测写成结论。

如果某点只是怀疑，明确写成：

- assumption
- open question
- residual risk

## 输出格式

优先输出：

```md
## Findings

1. [severity] 问题描述
2. ...
```

然后可选输出：

- open questions
- residual risks
- next step

如果没有明确问题，也要明确写：

- no material findings

并补充剩余风险或验证盲区。

## 约束

- 不要把 `docs/plans/*.md` 或 `docs/solutions/*.md` 当成应删除文件
- 不要自动进入执行阶段
- 审查结束后，如果用户要继续实现，提醒其回到 Claude 或继续人工决策
- 不要把低把握度推断包装成高置信结论

## 完成后的引导

完成后告诉用户：

- 主要 findings
- 是否建议修改 plan / code
- 如果下一步是执行，应回到 Claude
