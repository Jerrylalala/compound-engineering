---
title: 审查代理事实核查机制设计
date: 2026-03-24
participants:
  - 用户（Jerry）
  - Claude 派对模式（李明远/陈思琪/孙测试）
  - Codex（gpt-5.4）
status: 方案已收敛，待规划
---

# 审查代理事实核查机制设计

## What We're Building

在 `/plan_review` 和 `/workflows:review` 的审查代理输出与用户之间，插入自动化的事实核查与裁决层，防止审查代理的事实性错误直接影响用户决策。

## Why This Approach

### 事件触发

2 个审查代理（kieran-rails-reviewer、code-simplicity-reviewer）在 plan_review 中声称"Task 1 是死工作——GlassSelect 已有 disabled prop"，但实际上混淆了组件级 `disabled`（GlassSelectProps）和选项级 `disabled`（Option interface 不存在此字段）。如果用户直接信任，会删掉必要任务。

### 根因

1. **流程架构缺陷**：plan_review 是纯扇出模式（3 代理并行 → 直接呈现），无验证层
2. **Prompt 缺陷**：审查代理没被要求提供精确证据（interface名+字段名）
3. **共因失效**：3 个代理读同一份代码，用类似推理模式，错误不独立
4. **选项设计缺陷**：plan_review 选项中"推荐：更新计划后执行"引导用户跳过验证

## Key Decisions

### 决策 1：四段式裁决链（Claude + Codex 共识）

```
Reviewers → Fact Checker → Adjudicator → Presenter
```

| 阶段 | 职责 | 实现方式 |
|------|------|---------|
| Reviewers | 产出结构化 finding（不是自由文本结论） | 修改审查代理 prompt |
| Fact Checker | 验证事实性原子声明 | grep/read 自动验证 |
| Adjudicator | 过滤错误建议、检测伪共识 | plan_review.md 内逻辑 |
| Presenter | 展示结论+验证状态+不确定性 | 改呈现格式 |

### 决策 2：风险分层验证（Codex 提出）

| 建议类型 | 风险等级 | 验证要求 |
|----------|---------|---------|
| 风格/命名/组织建议 | Level 0 | 无验证 |
| 普通代码事实声明 | Level 1 | symbol existence + file/line 校验 |
| "已实现/不需要/dead work/删除 task" | Level 2 | symbol + scope + 反例检查 |
| 架构迁移/数据删除/功能裁撤 | Level 3 | 自动验证 + 人工确认 |

### 决策 3：高风险结论硬规则

以下类型的结论**必须经过验证**才能呈现给用户：
- 删除任务 / 判定已实现 / 建议砍功能 → 必须 `verified`
- 风格建议 / 简化建议 → 允许 `not_verifiable`
- 设计推断 / 产品判断 → 明确标记为 `opinion`

裸结论（"Task 1 是死工作"）**禁止出现**，必须变成：
- "候选结论：Task 1 可能与现有能力重叠"
- "验证状态：`ambiguous`"
- "原因：发现组件级 disabled，未发现选项级 disabled 证据"

### 决策 4：防共识偏差策略

- **按证据聚合，不按票数聚合**：2 个 reviewer 引用同一前提 = 1 票
- **高风险结论必须列出反例检查**：没有反例检查，不允许给 "dead work" 结论
- **dependency collapse**：多个 finding 共享同一错误前提时，合并为一个证据簇

### 决策 5：分阶段实施

| 优先级 | 命令 | 改什么 | 原因 |
|--------|------|--------|------|
| P0 | /plan_review | 完整四段式裁决链 | 直接影响"删不删任务"，风险最高 |
| P1 | /workflows:review | 复用同一机制 | 同模式风险 |
| P2 | /deepen-plan | 仅接第一层（证据格式） | 输出是参考信息，非决策 |

## Finding Schema（审查代理输出格式）

```yaml
findings:
  - claim_type: dead_work | exists | missing | conflicts_with_plan | risk
    scope: component | option | method | database | api
    evidence:
      symbol: "disabled"
      interface: "GlassSelectProps"  # 精确到 interface/class
      file: "GlassSelect.tsx"
      line: 21
      quote: "disabled?: boolean"
    proposed_action: "删除 Task 1"
    confidence: high | medium | low
    assumptions:
      - "disabled 同时适用于组件级和选项级"  # 显式列出假设
    counter_checks:  # 反例检查（高风险结论必须提供）
      - checked: "Option interface 是否有 disabled"
        result: "无 — Option 只有 value 和 label"
```

## Fact-Check 分级

| 级别 | 检查内容 | 自动化程度 | 实现方式 |
|------|---------|-----------|---------|
| Symbol Check | 字段/方法/接口是否存在 | 高 | grep |
| Scope Check | 该字段属于哪个 interface/class | 高 | grep + 上下文读取 |
| Behavior Check | 渲染/调用路径是否消费该字段 | 中 | grep 调用链 |
| Conclusion Check | 现有实现是否覆盖 task 目标 | 低 | 需 LLM 或人工 |

### 已知难点（Codex 识别的 8 个）

1. 术语映射歧义（字符串命中 ≠ 语义命中）
2. 否定性声明难验证（证明 absence 比证明 existence 难）
3. 符号解析不稳定（类型别名、泛型、re-export）
4. 行为与声明脱节（接口有字段 ≠ 渲染逻辑真支持）
5. 计划语义需解析（task 目标是 option-level 还是 component-level）
6. 行号漂移（代码变化后行号过期）
7. false precision（行号让错结论看起来更可信）
8. 验证器也可能犯语义错误

## 具体改动范围

### 需要修改的文件

| 文件 | 改动内容 | 改动量 |
|------|---------|--------|
| `agents/review/*.md`（~10个） | 添加 finding schema 和证据格式要求 | 每个 +15-20 行 |
| `commands/plan_review.md` | 插入 Fact-Check + Adjudicator + Presenter 阶段 | +50-60 行 |
| `commands/workflows/review.md` | 同上（复用相同逻辑） | +50-60 行 |

### 可选新增文件

| 文件 | 用途 |
|------|------|
| `skills/fact-check/SKILL.md`（可选） | 抽象可复用的事实核查能力 |

## 用户体验变化

```
修改前：
  /plan_review → 3份报告直接展示 → 用户需人工判断准确性

修改后：
  /plan_review → 3份结构化 finding → [自动fact-check] → [裁决过滤] → 带验证状态的报告
                                        ↑ 用户无感               ↑ 用户无感

用户看到的变化：
  ❌ 之前：「Task 1 是死工作——GlassSelect 已有 disabled prop」
  ✅ 之后：「候选结论：Task 1 可能与现有能力重叠 | 验证: ❌ 事实错误 | 已自动移除」
```

## Open Questions

1. **fact-check 的 LLM 成本**：Scope Check 需要读取代码上下文，是否会显著增加 token 消耗？
2. **adjudicator 用 LLM 还是规则引擎**：术语偷换检测用规则匹配还是让 LLM 做？
3. **是否需要新增专门的 skeptic agent**：Codex 建议引入"只拆别人建议"的对抗性代理，但可能增加复杂度

## 外部 AI 咨询结果

| 评估维度 | Claude 派对模式 | Codex (gpt-5.4) | 共识度 |
|----------|----------------|-----------------|--------|
| 核心诊断 | 流程缺验证层 | 流程缺裁决层 | 一致（Codex 更深一层） |
| 方案框架 | 三层防护 | 四段式裁决链 | Codex 方案是我们的超集 |
| /deepen-plan | 暂缓 | 暂缓，但共享底层能力 | 一致 |
| 防共识偏差 | 引入不同验证方法 | 按证据聚合+反例检查 | 互补 |
| 实施优先级 | plan_review > review > deepen-plan | 相同 | 一致 |
| fact-check 难点 | 考虑了 3 个 | 识别了 8 个 | Codex 更全面 |

**综合建议**：采用 Codex 的四段式裁决链作为框架，融入派对模式讨论的具体实现细节。
