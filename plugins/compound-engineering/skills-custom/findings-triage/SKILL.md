---
name: findings-triage
description: This skill should be used when review findings need structured prioritization. It categorizes findings by severity (P0-P3) and provides actionable resolution guidance.
---

# 发现分类技能

## 触发条件

当代码审查、安全扫描或测试报告产生多个发现需要优先级排序时使用。

## 分类标准

| 级别 | 标准 | 响应 |
|------|------|------|
| **P0** | 阻断发布、数据丢失、安全漏洞 | 立即修复 |
| **P1** | 功能缺陷、用户可见 bug | 本轮修复 |
| **P2** | 代码质量、可维护性 | 下轮修复 |
| **P3** | 优化建议、样式偏好 | 记录备忘 |

## 执行流程

1. 收集所有发现（审查报告、测试输出、lint 结果）
2. 按上表分类每个发现
3. 对 P0/P1 生成修复任务（含文件路径和预期修改）
4. 对 P2/P3 记录到 backlog
5. 输出结构化报告

## 输出格式

````markdown
## Triage 报告

### P0 — 立即修复
- [ ] [发现描述] → [文件:行号] → [修复方案]

### P1 — 本轮修复
- [ ] [发现描述] → [文件:行号] → [修复方案]

### P2 — 下轮修复
- [发现描述]

### P3 — 记录备忘
- [发现描述]
````
