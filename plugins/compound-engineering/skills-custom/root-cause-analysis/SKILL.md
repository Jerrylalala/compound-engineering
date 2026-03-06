---
name: root-cause-analysis
description: This skill should be used when a bug's surface symptoms have been identified but the underlying cause remains unclear. It complements systematic-debugging by focusing specifically on causal chain analysis.
---

# 根因分析技能

## 与 systematic-debugging 的关系

- `systematic-debugging`：从症状出发，系统排查定位问题
- `root-cause-analysis`：问题已定位后，深挖根因防止复发

## 5-Why 分析法

对已知问题连续追问"为什么"，直到触及根本原因：

```
症状：用户会话数据丢失
→ 为什么？SessionStart hook 未执行
→ 为什么？hook async=true 导致竞态
→ 为什么？默认配置未考虑慢速环境
→ 为什么？缺少跨平台测试覆盖
→ 根因：hook 执行模型假设了快速同步环境
```

## 执行流程

1. **症状确认**：复现问题，记录准确症状
2. **直接原因**：定位触发问题的代码/配置
3. **5-Why 链**：连续追问至根因（通常 3-5 层）
4. **验证根因**：修改根因后确认症状消失
5. **防复发**：提出结构性修复（非只修表面）

## 输出格式

````markdown
## 根因分析报告

**症状**: [用户可见的问题]
**直接原因**: [触发问题的代码/配置]
**根因链**:
1. [第一层 why]
2. [第二层 why]
3. [根因]

**修复方案**: [结构性修复]
**防复发措施**: [测试/监控/约束]
````
