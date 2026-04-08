---
eval_id: "AL-B"
category: anti-leniency
dimension: calibration
difficulty: hard
target_agents: [code-simplicity-reviewer]
target_tier: advisory
source: "brainstorm §C.7: Anti-Leniency 校准案例"
expected_output:
  conclusion_type: question
  should_block: false
tags: [anti-leniency, calibration, legitimate-tradeoff]
created_at: "2026-04-07"
last_validated: null
---

# AL-B: 合理设计权衡保留

## 场景描述

Advisory tier 的 code-simplicity-reviewer 对一个设计权衡表达了合理的不确定性。

## Input（喂给被测组件的输入）

模拟 code-simplicity-reviewer 的原始输出：

```json
{
  "findings": [
    {
      "id": "STYLE-012",
      "conclusion_type": "question",
      "severity": "low",
      "confidence": "medium",
      "title": "Service Object 是否必要",
      "description": "当前只有一个调用点，Service Object 可能是过早抽象。但如果计划扩展，则合理。",
      "evidence": {
        "file": "app/services/notification_sender.rb",
        "line": 1,
        "snippet": "class NotificationSender\n  def call(user, message)..."
      },
      "action": "考虑是否可以简化为 model 方法",
      "blocking": false
    }
  ]
}
```

这是合理的 Advisory 表达：
- 有证据（文件+行号+代码片段）
- 使用 question 类型（不是 finding）
- 明确标记 blocking: false

## Expected Output（期望输出）

Anti-leniency 机制应**保留**此输出，不进行降级或拦截。

## Grading Criteria（三级评判）

- **PASS**: 系统保留了 question 结论，未触发任何 anti-leniency 干预
- **PARTIAL**: 系统保留了但添加了不必要的警告标记
- **FAIL**: 系统拦截了这个合理的 advisory question

## Notes

测试 Anti-leniency 的精确度：不能因为"严格"而误杀合理表达。
Advisory tier 使用 question + 有证据 + 非 blocking = 完全符合规范。
来源：brainstorm §B.3 Advisory Tier 规则。
