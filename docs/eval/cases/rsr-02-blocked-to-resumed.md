---
id: "rsr-02"
name: "Failure FSM 完整状态转移：blocked → debugging → replanned → resumed"
dimension: resume
difficulty: hard
target_agents:
  - deployment-verification-agent
target_tier: blocking
tags: [resume, fsm, blocked, state-machine]
fixture: "blocked-state.md"
context: |
  FSM 历史：
  1. active: 开始部署验证
  2. blocked: 缺少生产环境 AWS 凭证，无法执行 smoke test
  3. debugging: 确认凭证在 SSM Parameter Store，需要 IAM 角色
  4. replanned: 改为通过 staging 环境代理执行 smoke test
  5. resumed: 使用 staging 代理继续验证
  
  blocked 之前已完成：health check endpoint 验证（通过）、migration 状态检查（通过）
  blocked 原因：AWS credentials for production smoke test
expected_finding_count: "1-4"
expected_conclusion: finding
expected_types: [risk, missing]
must_not_contain: []
scoring:
  - metric: fsm_context_understood
    pass_if: "output references blocked reason"
  - metric: no_duplicate_checks
    pass_if: "health check and migration not re-verified"
  - metric: plan_adaptation
    pass_if: "uses staging proxy approach"
---

## 场景描述

deployment-verification-agent 在验证生产部署时遭遇凭证缺失，触发了完整的 Failure FSM 状态链。恢复后 agent 需要：
1. 理解为什么被 block
2. 理解 replanned 的新策略（使用 staging 代理）
3. 在新策略下继续验证，不重复已完成的检查

这是 FSM 最复杂的场景，测试 state.md 能否完整传递上下文。

## 输入说明

`fixtures/blocked-state.md` 包含完整的 FSM 状态历史，每个状态转移都有时间戳和原因。

## 预期行为

- 输出中引用 blocked 原因（AWS 凭证缺失）
- 不重复 health check 和 migration 检查
- 采用 staging 代理方案执行剩余验证
- 如果 staging 代理也有限制，应标记为 `needs-human-check`

## 评判标准

| 条件 | 结果 |
|------|------|
| 理解 FSM 历史 + 不重复 + 采用新策略 | pass |
| 理解 FSM 历史但仍尝试直接访问 prod | partial pass (0.5) |
| 完全忽略 FSM 历史，从头开始 | fail |

## 关联经验

Failure FSM 协议：active → blocked → debugging → replanned → resumed → reviewed → compounded
