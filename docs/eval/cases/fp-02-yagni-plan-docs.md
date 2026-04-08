---
id: "fp-02"
name: "计划文档和经验文档被误标为 YAGNI 违反"
dimension: false-positive
difficulty: medium
target_agents:
  - code-simplicity-reviewer
target_tier: advisory
tags: [yagni, docs, false-positive]
fixture: "plan-docs-tree.txt"
context: |
  PR 中包含功能代码 + docs/plans/feature-x-plan.md + docs/solutions/resolved-issue.md。
  code-simplicity-reviewer 的 prompt 中有明确规则：
  "Never flag docs/plans/*.md or docs/solutions/*.md for removal"
expected_finding_count: 0
expected_conclusion: clear
expected_types: []
must_not_contain: ["remove docs/plans", "remove docs/solutions", "删除计划文档"]
scoring:
  - metric: false_positive_count
    pass_if: "== 0"
  - metric: prompt_rule_compliance
    pass_if: "== 1"
---

## 场景描述

compound-engineering 的工作流会自动生成 `docs/plans/*.md` 和 `docs/solutions/*.md`。code-simplicity-reviewer 的 YAGNI 扫描可能将这些文档标记为"不必要的文件"，违反其自身 prompt 中的豁免规则。

此案例测试 agent 是否遵守自身 prompt 中的显式豁免规则。

## 输入说明

`fixtures/plan-docs-tree.txt` 模拟一个 PR 的文件列表，包含：
- `src/services/auth.ts`（功能代码）
- `docs/plans/auth-refactor-plan.md`（计划文档）
- `docs/solutions/auth-token-refresh.md`（经验文档）

## 预期行为

- 对 `src/services/auth.ts` 可以正常审查
- 对 `docs/plans/` 和 `docs/solutions/` 下的文件不应产出任何 finding
- agent 应体现出对豁免规则的理解

## 评判标准

| 条件 | 结果 |
|------|------|
| 无 finding 涉及 docs/plans/ 或 docs/solutions/ | pass |
| 有 finding 但标记为 opinion 且 confidence: low | partial pass (0.5) |
| 有 finding 建议删除/移除这些文档 | fail |

## 关联经验

code-simplicity-reviewer.md 第 51 行：`Never flag docs/plans/*.md or docs/solutions/*.md for removal`
