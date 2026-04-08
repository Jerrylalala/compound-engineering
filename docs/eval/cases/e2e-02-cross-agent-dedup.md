---
id: "e2e-02"
name: "多 Agent 发现同一根因时的去重与关联"
dimension: e2e
difficulty: medium
target_agents:
  - security-sentinel
  - data-integrity-guardian
  - architecture-strategist
target_tier: mixed
tags: [e2e, dedup, cross-agent, root-cause]
fixture: "cross-agent-pr.diff"
context: |
  PR 中有一个数据库操作：在没有事务包裹的情况下，先删除旧记录再插入新记录。
  三个 agent 会从不同角度发现同一问题：
  - security-sentinel: "数据一致性风险"
  - data-integrity-guardian: "缺少事务边界"
  - architecture-strategist: "Service 层违反事务管理职责"
expected_finding_count: "3-6"
expected_conclusion: finding
expected_types: [risk]
must_not_contain: []
scoring:
  - metric: root_cause_linked
    pass_if: "related findings are associated"
  - metric: no_triple_count
    pass_if: "final report doesn't present as 3 separate unrelated issues"
---

## 场景描述

一个缺少事务包裹的数据库操作会被 3 个不同 agent 从不同角度发现。这测试 review 流水线的汇总阶段是否能识别"多个 finding 指向同一根因"并合理呈现。

如果汇总阶段简单地列出 3 个 "critical" issue，用户会误以为有 3 个独立问题，实际只需修复 1 个地方（添加事务包裹）。

## 输入说明

`fixtures/cross-agent-pr.diff` 包含一个 Service 方法：
```ruby
def replace_user_settings(user, new_settings)
  UserSetting.where(user_id: user.id).delete_all
  new_settings.each { |s| UserSetting.create!(s.merge(user_id: user.id)) }
end
```

## 预期行为

- 三个 agent 各自发现问题（这是正确的）
- 汇总报告中将这些 finding 关联到同一根因
- 修复建议只有一个：添加事务包裹
- 不应呈现为 3 个需要分别修复的独立问题

## 评判标准

| 条件 | 结果 |
|------|------|
| 最终报告将 3 个 finding 关联到同一根因 + 统一修复建议 | pass |
| 各 agent 独立报告但提到了其他 agent 的类似发现 | partial pass (0.7) |
| 呈现为 3 个完全独立的问题 | fail |

## 关联经验

此案例反映了多 agent 架构的固有挑战：信息孤岛导致重复报告。
