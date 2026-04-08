---
id: "ccr-01"
name: "多 Tier Agent 混合审查的合约合规性"
dimension: contract
difficulty: medium
target_agents:
  - security-sentinel
  - code-simplicity-reviewer
  - architecture-strategist
target_tier: mixed
tags: [contract, structured-finding, multi-agent]
fixture: "multi-tier-diff.py"
context: |
  一个 Python PR 包含：
  - 硬编码的 API key（security-sentinel 应发现）
  - 过度工程的 Factory 模式只用了一次（code-simplicity-reviewer 应发现）
  - Service 层直接访问 Repository 的私有方法（architecture-strategist 应发现）
expected_finding_count: "3-6"
expected_conclusion: finding
expected_types: [risk, opinion, missing]
must_not_contain: []
scoring:
  - metric: contract_compliance
    pass_if: ">= 0.95"
  - metric: all_7_fields_present
    pass_if: "for every finding"
  - metric: counter_checks_when_required
    pass_if: "present for type=exists/missing/dead_work"
---

## 场景描述

三个不同 Tier 的 agent 审查同一个 PR，测试它们的输出是否都严格遵循 Review Contract 的 Structured Finding 格式。

重点检查：
1. 所有 7 个必填字段是否存在
2. Type 值是否在允许的枚举中
3. Confidence 值是否在 high/medium/low 中
4. type=exists/missing/dead_work 时是否有 Counter-checks

## 输入说明

`fixtures/multi-tier-diff.py` 是一个约 80 行的 Python 文件，预埋了 3 个不同类型的问题，分别对应三个 agent 的专长。

## 预期行为

- 每个 agent 至少产出 1 个 finding
- 所有 finding 严格遵循 Structured Finding 格式
- 字段值在预定义枚举范围内

## 评判标准

| 条件 | 结果 |
|------|------|
| 所有 finding 的 7 个字段完整，枚举值正确 | pass |
| 95% 以上字段完整 | pass（CCR >= 0.95） |
| 80%-95% 字段完整 | partial pass |
| < 80% 字段完整 | fail |

## 关联经验

所有 15 个 review agent 的末尾都有 "Structured Findings" 输出格式要求。
