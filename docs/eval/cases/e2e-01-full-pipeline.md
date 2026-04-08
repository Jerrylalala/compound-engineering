---
id: "e2e-01"
name: "完整 review 流水线端到端测试"
dimension: e2e
difficulty: hard
target_agents:
  - all
target_tier: mixed
tags: [e2e, pipeline, full-review]
fixture: "full-pipeline-pr.diff"
context: |
  模拟一个真实 PR，包含：
  - Rails 控制器（含 1 个隐蔽的 mass assignment 漏洞）
  - React 组件（含 1 个 useEffect 依赖数组遗漏）
  - Migration + schema.rb
  - 配置文件变更
  预埋问题：
  1. [blocking] mass assignment：permit 中遗漏了 :role 但视图中有 role 字段
  2. [analytical] 架构违反：Controller 直接操作另一个 Model 的 scope
  3. [advisory] 命名不一致：新方法用 camelCase 但项目惯例是 snake_case
expected_finding_count: "3-10"
expected_conclusion: finding
expected_types: [risk, missing, opinion]
must_not_contain: []
scoring:
  - metric: planted_issues_detected
    pass_if: ">= 2 of 3"
  - metric: blocking_fpr
    pass_if: "== 0"
  - metric: contract_compliance
    pass_if: ">= 0.90"
  - metric: no_contradictions
    pass_if: "agents don't contradict each other on same issue"
---

## 场景描述

通过 `/workflows:review` 调度全部 15 个 agent 审查一个中等规模的 PR。测试整个流水线的端到端表现：
- agent 调度是否正确
- 预埋问题是否被正确 Tier 的 agent 发现
- blocking Tier 的 FPR 是否为 0
- 多 agent 输出是否存在矛盾

## 输入说明

`fixtures/full-pipeline-pr.diff` 是一个约 200 行的综合 diff，覆盖 Rails + React + DB migration。

## 预期行为

- security-sentinel 或相关 blocking agent 发现 mass assignment
- architecture-strategist 或相关 analytical agent 发现架构违反
- pattern-recognition-specialist 或 code-simplicity-reviewer 发现命名不一致
- blocking Tier 不产出误报

## 评判标准

| 条件 | 结果 |
|------|------|
| 3/3 预埋问题被发现 + blocking FPR == 0 | pass (1.0) |
| 2/3 预埋问题被发现 + blocking FPR == 0 | pass (0.8) |
| 2/3 但 blocking 有误报 | partial pass (0.5) |
| < 2/3 预埋问题被发现 | fail |

## 关联经验

`docs/solutions/integration-issues/` 中的多个案例展示了 agent 交互中的实际问题。
