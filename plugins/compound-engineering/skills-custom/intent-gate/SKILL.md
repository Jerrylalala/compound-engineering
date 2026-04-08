---
name: intent-gate
description: "私有 Overlay：ce:work 意图分类门控。在执行前识别任务意图（实现/修复/重构/探索），设定对应的执行策略。使用时机：ce:work Phase 0（环境扫描）之后、Phase 1（Quick Start）之前。"
---

# Intent Gate — 意图分类门控

> **参考**：oh-my-openagent 的 Intent Classification 思路，适配本仓库 ce:work 流程。
>
> **目的**：避免 ce:work 对所有任务一刀切处理；不同意图需要不同的执行策略。

---

## 意图分类

| 意图 | 英文 | 触发信号 | 执行策略 |
|------|------|----------|----------|
| **实现新功能** | implement | "新增"、"添加"、"实现"、"create"、"add"、"implement" | TDD 优先，先写测试再实现 |
| **修复问题** | fix | "修复"、"修复 bug"、"fix"、"broken"、"error" | 先定位根因（systematic-debugging），再修复 |
| **重构** | refactor | "重构"、"优化"、"清理"、"refactor"、"cleanup" | 确保有测试覆盖，小步骤重构 |
| **探索/分析** | explore | "分析"、"研究"、"了解"、"explore"、"investigate" | 只读模式，不改代码，生成报告 |
| **配置/文档** | configure | "配置"、"文档"、"设置"、"config"、"docs" | 轻量执行，无需 TDD |
| **混合** | mixed | 多种意图混合 | 拆分为独立子任务，逐一处理 |

---

## 门控检测流程

在 ce:work Phase 0 完成后，执行意图分类：

### Step 1: 自动分类

分析输入文档（plan 或 bare prompt）中的关键词，得出初始分类：

```
输入分析 → 关键词匹配 → 初始意图
```

### Step 2: 置信度评估

| 置信度 | 行为 |
|--------|------|
| ≥ 0.80 | 直接设定执行策略，不询问 |
| 0.60-0.79 | 展示分类结果，询问确认（单问） |
| < 0.60 | 明确询问用户意图 |

### Step 3: 意图确认（低置信度时）

使用 AskUserQuestion 询问：

```
检测到此任务可能是：
  A. 实现新功能（test-first）
  B. 修复问题（debug-first）
  C. 重构（refactor-safe）
  D. 其他：___

选择最准确的意图 (A/B/C/D)：
```

---

## 各意图执行策略

### implement（实现新功能）

```
1. 加载 test-driven-development skill
2. 先写失败测试
3. 实现使测试通过
4. 重构（可选）
5. 验证完整测试套件
```

### fix（修复问题）

```
1. 加载 systematic-debugging skill
2. 定位根因（不猜测）
3. 写复现测试（证明 bug 存在）
4. 修复使测试通过
5. 验证无回归
```

### refactor（重构）

```
1. 确认现有测试覆盖率
2. 如覆盖率不足 → 先补测试
3. 小步骤重构（每步运行测试）
4. 最终效果：行为不变，代码更清晰
```

### explore（探索/分析）

```
1. 设置只读模式（不改代码）
2. 使用 repo-research-analyst + learnings-researcher
3. 生成分析报告到 docs/plans/ 或标准输出
4. 明确告知用户：探索模式，不执行任何修改
```

### configure/docs（配置/文档）

```
1. 轻量执行，无需 TDD 周期
2. 修改相关配置文件或文档
3. 验证格式正确性（lint/yaml validate 等）
```

---

## 与 ce:work 的集成

Intent Gate 在 ce:work Phase 0（环境扫描）完成后、Phase 1（Quick Start）开始前执行：

```
Phase 0: 环境扫描（原有）
  ↓
[Intent Gate 插入点 — 本 overlay 在此插入]
  ├── 自动分类意图
  ├── 设定执行策略
  └── 加载对应 skill（TDD / systematic-debugging 等）
  ↓
Phase 1: Quick Start（原有，但按策略执行）
```

> **注意**：不使用分数相命名（如 Phase 0.5），以避免与 ce:work 原有整数相编号冲突。

**不修改 ce:work SKILL.md**。在调用 ce:work 前先加载 intent-gate skill，按其指导调整执行方式。

---

## 意图门控日志

在 state.md 中记录意图分类结果（如有 Task Bundle）：

```yaml
# state.md 新增字段
intent:
  detected: fix
  confidence: 0.85
  strategy: "systematic-debugging → write reproduction test → fix → verify"
  intent_gate_at: "2026-04-08T10:00:00+08:00"
```

---

## 防误用说明

| 场景 | 正确处理 |
|------|----------|
| 用户说"修复这个 bug"但实际是新功能 | Intent Gate 检测为 implement，提示用户确认 |
| 混合意图（既修复又重构） | 拆分为两个子任务，分别处理 |
| 用户明确说"直接实现，不要 TDD" | 尊重用户意图，跳过 TDD 要求 |
