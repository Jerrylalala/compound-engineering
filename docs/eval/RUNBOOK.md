# 评测执行手册

## 快速开始（5 分钟上手）

### 1. 选择一个 easy 案例

```bash
# 推荐从 fp-01 开始
cat docs/eval/cases/fp-01-safe-env-var.md
```

### 2. 准备输入

将 `docs/eval/fixtures/safe-env-var.diff` 的内容作为审查输入。

### 3. 运行 agent

方式 A：直接调用 agent
```
请以 security-sentinel 的身份审查以下 diff：
[粘贴 fixture 内容]
```

方式 B：通过 review 命令（未来支持 [E] 标志）
```
/workflows:review [E] fp-01
```

### 4. 收集输出

将 agent 的完整输出复制到 `docs/eval/results/fp-01-<日期>.md`。

### 5. 标注

对照案例的"评判标准"表格，为每个 finding 标注 TP/FP/FN。

### 6. 计算分数

按 SCORING.md 的公式计算，填入结果文件的 `scores` 字段。

---

## 完整流程

### Phase 1：单案例执行

```
读取案例定义 → 准备 fixture → 运行 agent → 收集输出 → 人工标注 → 计算分数
```

每个案例预计耗时：
- easy: 10 分钟
- medium: 20 分钟
- hard: 30 分钟

### Phase 2：维度汇总

完成一个维度的所有案例后：

1. 收集该维度所有案例的分数
2. 计算维度级指标（FPR/FNR/RSR/CCR/FVR）
3. 对照阈值判定 pass/fail
4. 如果 fail，记录需要修改的 agent 和具体问题

### Phase 3：修复与回归

1. 修改 agent prompt（`plugins/compound-engineering/agents/review/*.md`）
2. 只重跑该 agent 相关的案例
3. 确认分数改善且未引入新问题
4. 更新 SUMMARY.md

---

## 结果文件模板

```yaml
---
case_id: "fp-01"
run_date: "2026-04-07T14:30:00+08:00"
agents_tested:
  - security-sentinel
raw_finding_count: 0
annotations: []
scores:
  core_judgment: 1.0
  contract_compliance: 1.0
  evidence_quality: 1.0
  noise_free: 1.0
  total: 1.0
pass: true
---

## Agent 原始输出

[粘贴完整输出]

## 标注记录

无 finding，符合预期。
```

---

## 注意事项

1. **fixture 不可修改**：评测的可重复性依赖固定输入
2. **每次运行都是新结果文件**：用时间戳区分，不覆盖历史
3. **人工标注是核心**：当前阶段不使用 LLM-as-judge，避免二次幻觉
4. **只在 agent prompt 修改后重跑**：不要为了"刷分"多次运行同一案例
5. **结果文件不提交 git**：`results/` 目录下只保留 `.gitkeep` 和 `SUMMARY.md`
