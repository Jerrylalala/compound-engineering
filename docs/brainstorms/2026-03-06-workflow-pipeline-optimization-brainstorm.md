---
title: "工作流管线性价比优化"
date: 2026-03-06
participants:
  - Claude（派对模式：李明远/陈思琪/张晓峰）
  - Codex (gpt-5.3-codex)
status: decided
---

# 工作流管线性价比优化

## 问题

当前完整管线有 **8 个审查检查点**，token 消耗高、审查间矛盾、性价比低。

实际体验（v2.43.0 上游整合）：
- plan_review 给出建议（删减到 7-9 任务）→ 被完全忽略
- 17 任务全部执行成功，冒烟测试 ALL PASS
- plan_review 的 ROI = 0

## 当前管线（Before）

```
brainstorm [P][C]       ← ① 派对模式 + ② Codex 方案咨询
    ↓
plan                    ← ③ SpecFlow 分析
    ↓
deepen-plan             ← ④ 20-40 个并行研究代理
    ↓
plan_review             ← ⑤ DHH/Kieran/Simplicity 三方审查
    ↓
work (Subagent)         ← ⑥ spec-compliance-review + ⑦ 质量检查
    ↓
review [C]              ← ⑧ 9-11 个审查代理 + ⑨ Codex 再审
    ↓
compound → save
```

**问题诊断**：
1. 审查间矛盾：brainstorm [C] 确认方案 → plan_review 否定方案 → 用户无所适从
2. 同质化审查：plan_review 和 review 用同一批代理（DHH/Kieran），等于看两遍
3. 边际递减：第 1-2 层审查价值高，第 3 层后快速递减（Claude + Codex 共识）
4. Token 浪费：plan_review + deepen-plan + review ≈ 330K tokens，占总量 50%+

## 决定的方案：方案 D（风险分级自适应管线）

**来源**：Claude 方案 A + Codex 方案 D 综合

### 默认流程（低风险，~90% 场景）

```
brainstorm [P][C] → plan → work → 冒烟测试 → 完成
```

- 2 层审查：派对模式 + Codex
- Token 消耗：约为完整管线的 35%
- 适用：个人项目、方向已确定的功能、提示词/文档修改

### 中风险流程

```
brainstorm [P][C] → plan → plan_review → work → 冒烟测试 → 完成
```

- 3 层审查：+ plan_review
- 触发条件：安全相关、数据迁移、外部 API 集成

### 高风险流程（~5% 场景）

```
brainstorm [P][C] → plan → plan_review → work → review [C] → 完成
```

- 4 层审查：+ post-work review
- 触发条件：支付系统、不可逆操作、影响生产数据

### 风险评分参考

| 维度 | 低 (0) | 中 (1) | 高 (2) |
|------|--------|--------|--------|
| 安全/隐私 | 无敏感数据 | 涉及用户数据 | 认证/支付/PII |
| 可逆性 | 完全可逆 | 部分可逆 | 不可逆（数据迁移） |
| 影响范围 | 本地/个人 | 团队/内部 | 生产/外部用户 |
| 变更规模 | < 5 文件 | 5-20 文件 | > 20 文件 |
| 外部依赖 | 无 | 内部 API | 第三方 API/服务 |

```
总分 0-2 → 低风险（默认流程）
总分 3-5 → 中风险
总分 6+  → 高风险
```

### deepen-plan 的处理

**删除当前版本**（20-40 个并行代理，ROI 过低）。

如需深化研究，改为在 plan 阶段内嵌：
- 仅 3-5 个专题代理（安全/架构/性能）
- 不作为独立步骤

## 关键决策

1. **默认流程精简到 2 层审查**：brainstorm [P][C] → plan → work → 冒烟测试
2. **plan_review 改为条件触发**：仅中高风险
3. **review 改为条件触发**：仅高风险或测试失败
4. **deepen-plan 降级**：从独立步骤改为 plan 内嵌的可选子步骤
5. **冒烟测试 = 最终审查**：测试通过即质量足够
6. **compound 和 save 保留**：属于知识管理，不是审查，成本低价值高

## 外部 AI 咨询结果

### Codex 核心观点

1. 边际递减**确实存在且很明显**，第 1-2 层收益最大
2. 多代理审查存在**相关性**（同一上下文），并非独立增益
3. 建议用可量化的风险评分替代主观判断
4. 审查层数建议：常规 2-3 层，高风险 4 层封顶
5. 保留少量"抽检复审"防止质量漂移

### Claude 派对模式核心观点

1. plan_review 和 review 使用**同一批代理**审两遍 = 结构性冗余
2. brainstorm [P][C] 已是最强前置审查（多视角 + 外部 AI）
3. 审查越多决策越瘫痪，核心问题是**没有权威链**
4. 冒烟测试 > 人工审查（对结构化任务）

## 开放问题

1. 风险评分是否需要写入 plan 的 frontmatter（自动化触发）？
2. 是否需要"抽检机制"防止流程简化后质量漂移？
3. Codex 模型从 gpt-5.2 迁移到 gpt-5.3，是否需要更新 config.toml？

## References

- 实际体验数据：v2.43.0 上游整合（17 任务，plan_review 被忽略）
- Codex 配置：`~/.codex/config.toml` → model = gpt-5.2-codex（自动迁移到 gpt-5.3-codex）
- 当前工作流定义：`plugins/compound-engineering/commands/workflows/*.md`
