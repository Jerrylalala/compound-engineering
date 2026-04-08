---
name: review-contract
description: "私有 Overlay：Review Contract 三档 Tier 分类 + Anti-Leniency 注入。在 ce:review 基础上增加 Blocking/Analytical/Advisory 分层和结论类型系统。使用时机：运行 ce:review 前阅读此协议以理解审查标准。"
---

# Review Contract — 私有 Overlay

> **基础层**：上游 `ce:review` 已实现 P0-P3 严重级别、confidence 阈值（≥0.60 才报告）、autofix_class 路由。
>
> **本 Overlay 增量**：三档 Tier 分类 + 对应的 anti-leniency 强度 + `conclusion_type` 覆盖层。

---

## Tier 分类（15 个 Reviewer）

| Tier | Agents | Anti-Leniency 强度 |
|------|--------|-------------------|
| **Blocking** | security-sentinel, data-integrity-guardian, data-migration-expert, deployment-verification-agent | 零容忍：confidence ≥ 0.50 且 severity P0 必须报告，不确定时用 `needs-human-check` |
| **Analytical** | architecture-strategist, performance-oracle, kieran-rails-reviewer, kieran-typescript-reviewer, kieran-python-reviewer, julik-frontend-races-reviewer, dhh-rails-reviewer, pattern-recognition-specialist | 严格务实：必须提供触发条件/复现场景；没有场景的担忧降级为 `question` |
| **Advisory** | code-simplicity-reviewer, agent-native-reviewer, schema-drift-detector | 建议为主：默认 `autofix_class: advisory`，除非与明确 spec/CLAUDE.md 冲突 |

---

## 结论类型系统（`conclusion_type` 覆盖层）

上游 schema 已有 `autofix_class` 路由。本 overlay 增加一个更语义化的 `conclusion_type` 字段，与上游字段并存：

| `conclusion_type` | 映射关系 | 何时使用 |
|-------------------|----------|----------|
| `finding` | 上游 P0/P1/P2 + confidence ≥ 0.70 | 有确凿证据的问题，有代码引用 |
| `question` | 上游 `residual_risks` / confidence 0.60-0.69 | 不确定，需要讨论 |
| `needs-human-check` | 上游 `requires_verification: true` | 超出 AI 判断能力 |
| `clear` | 上游 findings 为空 | 此项无问题 |

---

## Anti-Leniency Prompt 注入（按 Tier）

以下 Prompt 作为 `system_prompt_suffix` 注入到对应 Tier 的 agent 调用中，不修改 agent 原始 prompt。

### Blocking Tier — 零容忍

```
你是 [agent-name]，属于 Blocking Tier。你的审查结论直接影响生产环境安全。

铁律（在上游 confidence_thresholds 基础上加强）：
1. P0 问题：confidence ≥ 0.50 即必须报告（上游默认 0.60，Blocking Tier 降低阈值）
2. 不确定时必须输出 requires_verification: true，不能直接给 safe_auto
3. 每个 finding 必须有 evidence[]，包含文件路径 + 行号 + 代码片段
4. 禁止使用「应该没问题」「可能不影响」等措辞
5. 自问：「如果这段代码导致数据泄露，我的 clear 结论能站住脚吗？」
```

### Analytical Tier — 严格务实

```
你是 [agent-name]，属于 Analytical Tier。

规则（在上游 confidence_thresholds 基础上）：
1. 每个 finding 必须提供触发条件或复现场景
2. 没有具体场景的担忧 → 放入 residual_risks，不作为 findings
3. 性能问题必须估算影响量级（O(n) vs O(n²)、毫秒 vs 秒级）
4. 「理论上可能有问题」→ residual_risks，不是 findings
```

### Advisory Tier — 建议为主

```
你是 [agent-name]，属于 Advisory Tier。

规则：
1. 默认 autofix_class: advisory，除非与明确 spec/CLAUDE.md 冲突
2. 代码品味问题 → P3 + advisory，不是 P0-P2
3. 不要因为「代码可以更好」就报 finding，放入 residual_risks 更合适
```

---

## 与上游 ce:review 的集成方式

**不修改上游 ce:review SKILL.md**。在调用 ce:review 前：

1. 加载本 skill（`review-contract`）
2. 确认当前 PR 涉及哪些 Tier 的 agent（根据 diff 类型）
3. ce:review 运行时，对 Blocking Tier agent 的结果验证 evidence[] 是否完整
4. 对 Advisory Tier 的 P0-P2 findings 降级为 P3（代码品味不应 blocking）

**Eval Set 测试**：本协议的正确性由 `docs/eval/` 中的案例验证：
- `fn-01-sql-injection` → Blocking Tier 漏报测试
- `fp-01-safe-env-var` → Blocking Tier 误报测试
- `al-d-opinion-vs-finding` → Advisory Tier 降级测试

---

## 与上游 findings-schema.json 的对齐

| 本 overlay 字段 | 上游 schema 对应字段 | 说明 |
|----------------|---------------------|------|
| `conclusion_type: finding` | `severity: P0-P2` + `confidence ≥ 0.70` | 高置信度有证据问题 |
| `conclusion_type: question` | `residual_risks[]` + `confidence 0.60-0.69` | 不确定的担忧 |
| `conclusion_type: needs-human-check` | `requires_verification: true` | 需要人工判断 |
| `conclusion_type: clear` | `findings: []` (空数组) | 此项无问题 |
| Blocking Tier | 无上游对应 | 本 overlay 新增分类 |
| confidence ≥ 0.50 (P0) | 上游默认 0.60 | Blocking Tier 降低阈值 |

---

## 遗留问题（待 P2 完成后评估）

1. `conclusion_type` 是否需要写入 findings-schema.json？（当前策略：不修改上游 schema，在 overlay 层处理）
2. Anti-leniency prompt suffix 的具体注入机制（system_prompt_suffix vs overlay skill 说明）
3. 多模型仲裁权重：Claude 1.0 / Codex 0.85 / Gemini 0.80（待 P7 实现时启用）
