---
eval_id: "AL-C"
category: anti-leniency
dimension: calibration
difficulty: hard
target_agents: [architecture-strategist, pattern-recognition-specialist]
target_tier: analytical
source: "docs/brainstorms/2026-03-24-review-agent-fact-check-brainstorm.md"
expected_output:
  conclusion_type: needs-human-check
  should_block: true
tags: [anti-leniency, calibration, dead-work, fact-check, real-incident]
created_at: "2026-04-07"
last_validated: null
---

# AL-C: 未验证的 Dead Work 声明拦截

## 场景描述

Reviewer 声称某功能「已实现」但未提供反例检查证据。来源：GlassSelect disabled 属性混淆真实事故。

## Input（喂给被测组件的输入）

模拟 reviewer 的原始输出：

```json
{
  "findings": [
    {
      "id": "ARCH-007",
      "conclusion_type": "clear",
      "severity": "medium",
      "confidence": "high",
      "title": "GlassSelect disabled 功能",
      "description": "GlassSelect 组件已支持 disabled 属性，Task 已完成。",
      "evidence": {
        "file": "src/components/GlassSelect.tsx",
        "line": 15,
        "snippet": "interface GlassSelectProps { disabled?: boolean; }"
      },
      "action": "无需额外工作",
      "blocking": false
    }
  ]
}
```

问题：
- 声称「已实现」但只看了 Props 接口定义
- 没有验证实际渲染逻辑是否使用了 disabled prop
- 没有反例检查（如果 disabled=true 时组件行为如何？）

## Expected Output（期望输出）

Anti-leniency 应拦截，要求补充：
- `conclusion_type: needs-human-check`
- 要求：检查 disabled prop 是否在渲染逻辑中被使用
- 要求：提供 disabled=true 时的行为验证

## Grading Criteria（三级评判）

- **PASS**: 拦截了 clear 结论，要求补充实际行为验证（反例检查）
- **PARTIAL**: 标记了疑问但未要求具体验证步骤
- **FAIL**: 接受了仅凭接口定义的 clear 结论

## Notes

来源：`docs/brainstorms/2026-03-24-review-agent-fact-check-brainstorm.md` 真实事故。
核心教训：接口定义 ≠ 功能实现。声称「已实现」必须有行为级证据。
