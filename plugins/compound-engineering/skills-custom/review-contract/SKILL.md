---
name: review-contract
description: "私有 Overlay：Review Contract 三档 Tier 分类 + Anti-Leniency 注入。在 ce:review 基础上增加 Blocking/Analytical/Advisory 分层和结论类型系统。使用时机：运行 ce:review 前阅读此协议以理解审查标准。"
---

# Review Contract — 私有 Overlay

> **基础层**：上游 `ce:review` 已实现 P0-P3 严重级别、confidence 阈值（≥0.60 才报告）、autofix_class 路由。
>
> **本 Overlay 增量**：三档 Tier 分类 + 对应的 anti-leniency 强度 + `conclusion_type` 覆盖层。

---

## Tier 分类

> **命名规范**：`[上游]` = 在 `skills/ce-review/references/persona-catalog.md` 中有记录，由 ce:review 编排器实际派发。
> `[本地]` = 仅在 `agents/review/` 中存在但不在 persona-catalog，需手动调用，不被编排器自动派发。

| Tier | Agents | Anti-Leniency 强度 |
|------|--------|-------------------|
| **Blocking** | `security-reviewer` [上游], `data-migrations-reviewer` [上游], `deployment-verification-agent` [上游] | 零容忍：confidence ≥ 0.50 且 severity P0 必须报告，不确定时用 `needs-human-check` |
| **Analytical** | `architecture-strategist` [本地], `performance-reviewer` [上游], `kieran-rails-reviewer` [上游], `kieran-typescript-reviewer` [上游], `kieran-python-reviewer` [上游], `julik-frontend-races-reviewer` [上游], `dhh-rails-reviewer` [上游], `pattern-recognition-specialist` [本地] | 严格务实：必须提供触发条件/复现场景；没有场景的担忧降级为 `question` |
| **Advisory** | `code-simplicity-reviewer` [本地], `agent-native-reviewer` [上游], `schema-drift-detector` [上游] | 建议为主：默认 `autofix_class: advisory`，除非与明确 spec/CLAUDE.md 冲突 |

**已更正的名称对照**（原名 → persona-catalog 名）：
- `security-sentinel` → `security-reviewer`
- `data-integrity-guardian` + `data-migration-expert` → `data-migrations-reviewer`（合并，上游统一入口）
- `performance-oracle` → `performance-reviewer`

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

## Anti-Leniency 参考原则（仅供分类框架参考）

> **注意**：以下原则是读取本 skill 时的行为指南，**不是**通过 `system_prompt_suffix` 自动注入到 agent 中。
> ce:review 不支持动态 prompt 注入机制。加载本 skill 后，Claude 在调用各 Tier agent 时应主动遵循对应原则。

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
