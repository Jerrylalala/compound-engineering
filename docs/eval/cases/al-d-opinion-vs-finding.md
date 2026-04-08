---
eval_id: "AL-D"
category: anti-leniency
dimension: calibration
difficulty: medium
target_agents: [code-simplicity-reviewer, dhh-rails-reviewer]
target_tier: advisory
source: "brainstorm §C.7: Anti-Leniency 校准案例"
expected_output:
  conclusion_type: finding
  severity: low
  should_block: false
tags: [anti-leniency, calibration, opinion-vs-finding]
created_at: "2026-04-07"
last_validated: null
---

# AL-D: Opinion 被误标为 Blocking Finding

## 场景描述

Advisory tier 的 reviewer 将代码品味意见错误标记为 blocking finding。

## Input（喂给被测组件的输入）

模拟 reviewer 的原始输出：

```json
{
  "findings": [
    {
      "id": "STYLE-045",
      "conclusion_type": "finding",
      "severity": "high",
      "confidence": "high",
      "title": "函数超过 50 行",
      "description": "process_data 函数有 62 行，超过了 50 行的推荐上限。应拆分为多个小函数。",
      "evidence": {
        "file": "app/services/data_processor.rb",
        "line": 10,
        "snippet": "def process_data(input)\n  # 62 lines of sequential processing\nend"
      },
      "action": "拆分为 validate_input、transform_data、persist_result 三个方法",
      "blocking": true
    }
  ]
}
```

问题：
- 「函数超过 50 行」是代码品味，不是 bug
- Advisory tier 不应设置 `blocking: true`
- `severity: high` 对风格问题过重

## Expected Output（期望输出）

Anti-leniency 应保留 finding 但降级：
- 保持 `conclusion_type: finding`（确实超过 50 行，这是事实）
- 降级 `blocking: false`（Advisory tier 不应 blocking）
- 降级 `severity: low`（风格问题）

## Grading Criteria（三级评判）

- **PASS**: 保留 finding 但降级 blocking=false + severity 降低
- **PARTIAL**: 降级了 blocking 但保留了 high severity，或降级了 severity 但保留 blocking
- **FAIL**: 保留原始的 blocking=true 输出，或完全删除了这个 finding

## Notes

测试 Anti-leniency 的细粒度：不是简单的"拦截/放行"，而是精确调整输出参数。
Advisory tier 的 finding 默认 blocking: false，除非与明确 spec 冲突。
来源：brainstorm §B.3 Advisory Tier 规则第 1 条。
