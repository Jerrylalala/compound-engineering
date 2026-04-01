---
name: workflows-review
description: 对代码、分支或计划进行结构化审查，输出 findings 与建议
---

# workflows-review

用于在 Codex 中做审查，而不是执行实现。

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

## 约束

- 不要把 `docs/plans/*.md` 或 `docs/solutions/*.md` 当成应删除文件
- 不要自动进入执行阶段
- 审查结束后，如果用户要继续实现，提醒其回到 Claude 或继续人工决策

## 完成后的引导

完成后告诉用户：

- 主要 findings
- 是否建议修改 plan / code
- 如果下一步是执行，应回到 Claude
