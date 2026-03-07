---
title: "feat: 工作流风险分级自适应管线"
type: feat
date: 2026-03-06
brainstorm: docs/brainstorms/2026-03-06-workflow-pipeline-optimization-brainstorm.md
risk_score: 2
risk_level: low
risk_note: "仅修改 Markdown 提示词文件，完全可逆，无安全/数据风险"
---

# feat: 工作流风险分级自适应管线

## Overview

在 plan 生成后自动评估风险等级，根据评分决定调用哪些额外审查步骤。所有命令保留，但从"手动可选"变为"智能按需"。

(see brainstorm: docs/brainstorms/2026-03-06-workflow-pipeline-optimization-brainstorm.md)

## Problem Statement

当前管线 8 个审查检查点，大部分场景下冗余：
- plan_review 被忽略（v2.43.0 实际体验 ROI=0）
- deepen-plan 20-40 代理对 Markdown 项目价值低
- review 和 plan_review 用同一批代理审两遍
- Token 消耗 50%+ 用于低价值审查

## Proposed Solution

**风险分级自适应**：plan 生成后自动打分，work 根据分数决定流程。

```
plan 生成 → 风险评分 (0-10)
    ↓
低风险 (0-3)  → work → 冒烟测试 → 完成
中风险 (4-6)  → 自动建议 plan_review → work → 冒烟测试 → 完成
高风险 (7+)   → 自动建议 deepen-plan + plan_review → work → review [C] → 完成
```

**用户始终有最终决定权**：系统建议但不强制，用户可覆盖。

## Acceptance Criteria

- [ ] plan.md 生成计划后自动输出风险评分和等级
- [ ] 风险评分写入 plan frontmatter（risk_score, risk_level）
- [ ] plan.md Handoff 选项根据风险等级动态调整（推荐项不同）
- [ ] work.md 读取风险评分，在 Phase 1 展示并给出建议
- [ ] 用户可手动覆盖风险等级（向上或向下）
- [ ] CLAUDE.md 更新流程说明
- [ ] 版本号更新 + CHANGELOG 记录
- [ ] check-handoff.sh ALL PASS

## Tasks

### Phase 1: 风险评分机制（plan.md）

---

### Task 1: 在 plan.md 添加风险评分指令

**文件**: `plugins/compound-engineering/commands/workflows/plan.md`
**操作**:
- [x] 在 "### 7. Final Review & Submission" 之前插入新的 "### 6.5 Risk Assessment" 章节

**代码**（在 Step 6 和 Step 7 之间插入）:
````markdown
### 6.5. Risk Assessment（自动执行）

在计划写入文件前，对计划内容进行风险评估。

**评估 5 个维度（每项 0-2 分）：**

| 维度 | 0 分（低） | 1 分（中） | 2 分（高） |
|------|-----------|-----------|-----------|
| **安全/隐私** | 无敏感数据 | 涉及用户数据 | 认证/支付/PII |
| **可逆性** | 完全可逆（Markdown/配置） | 部分可逆（代码重构） | 不可逆（数据迁移/删除） |
| **影响范围** | 本地/个人项目 | 团队/内部系统 | 生产环境/外部用户 |
| **变更规模** | ≤5 文件 | 6-20 文件 | >20 文件 |
| **外部依赖** | 无 | 内部 API | 第三方 API/服务 |

**计算总分（0-10）并分级：**

```
总分 0-3  → 低风险 🟢
总分 4-6  → 中风险 🟡
总分 7-10 → 高风险 🔴
```

**将评分写入 plan frontmatter：**

```yaml
---
risk_score: [0-10]
risk_level: [low|medium|high]
risk_note: "[一句话说明主要风险来源]"
---
```

**向用户展示：**

```
风险评估：[总分]/10 — [低/中/高]风险 [🟢/🟡/🔴]
  安全/隐私: [0-2]  可逆性: [0-2]  影响范围: [0-2]
  变更规模: [0-2]  外部依赖: [0-2]
主要风险：[risk_note]
```
````

**验证**:
- [x] 确认 plan.md 包含 `### 6.5. Risk Assessment`
- [x] 确认包含 5 维度评分表

---

### Task 2: 修改 plan.md Handoff 为风险感知

**文件**: `plugins/compound-engineering/commands/workflows/plan.md`
**操作**:
- [x] 替换 "## Post-Generation Options" 中的固定选项为风险动态选项

**代码**（替换 Post-Generation Options 部分）:
````markdown
## Post-Generation Options

After writing the plan file and completing risk assessment, use the **AskUserQuestion tool** to present risk-aware options:

**根据风险等级动态调整选项和推荐：**

#### 🟢 低风险 (0-3)：

**Question:** "Plan ready at `[path]`。风险评估：[score]/10 🟢 低风险。下一步？"

**Options:**
1. **开始 `/workflows:work`（推荐）** - 直接开始实施
2. **运行 `/plan_review`** - 多代理审查计划（低风险通常不需要）
3. **打开 Plan 文件** - 在编辑器中查看完整内容
4. **停止** - 稍后处理

#### 🟡 中风险 (4-6)：

**Question:** "Plan ready at `[path]`。风险评估：[score]/10 🟡 中风险。建议先审查计划。"

**Options:**
1. **运行 `/plan_review`（推荐）** - 多代理审查计划后再执行
2. **直接开始 `/workflows:work`** - 跳过审查直接实施
3. **运行 `/deepen-plan`** - 深化研究后再审查
4. **停止** - 稍后处理

#### 🔴 高风险 (7+)：

**Question:** "Plan ready at `[path]`。风险评估：[score]/10 🔴 高风险。强烈建议完整审查流程。"

**Options:**
1. **运行 `/deepen-plan` + `/plan_review`（推荐）** - 深化研究 + 多代理审查
2. **仅运行 `/plan_review`** - 跳过深化，直接审查
3. **直接开始 `/workflows:work`** - 跳过所有审查（高风险不推荐）
4. **停止** - 稍后处理

Based on selection:
- **`/workflows:work`** → 调用 `/workflows:work <plan_path>`
- **`/plan_review`** → 调用 `/plan_review <plan_path>`
- **`/deepen-plan` + `/plan_review`** → 先调用 `/deepen-plan <plan_path>`，完成后自动调用 `/plan_review <plan_path>`
- **打开 Plan 文件** → 运行 `open <plan_path>`
- **停止** → 结束流程
- **Other**（自动提供）→ 接受自由文本修改或特定更改

Loop back to options after changes until user selects execution path.
````

**验证**:
- [x] 确认 plan.md Handoff 包含 3 个风险等级的选项块
- [x] 确认低风险推荐 work，中风险推荐 plan_review，高风险推荐 deepen + plan_review
- [ ] `bash scripts/check-handoff.sh` 中 plan.md 仍为 PASS

---

### Phase 2: work.md 风险感知执行

---

### Task 3: 在 work.md Phase 1 添加风险感知读取

**文件**: `plugins/compound-engineering/commands/workflows/work.md`
**操作**:
- [x] 在 Phase 1 的 "1. Read Plan and Clarify" 步骤中，添加风险评分读取和展示

**代码**（在 "Read the work document completely" 之后追加）:
````markdown
   - **Read risk assessment from plan frontmatter** (if present):
     ```yaml
     risk_score: [0-10]
     risk_level: [low|medium|high]
     ```

     If risk assessment exists, announce:
     ```
     "风险评估：[risk_score]/10 — [risk_level] [🟢/🟡/🔴]"
     ```

     **风险感知执行建议：**

     | 风险等级 | 建议 |
     |----------|------|
     | 🟢 低风险 | 直接执行，冒烟测试即可 |
     | 🟡 中风险 | 执行后建议运行 `/workflows:review` |
     | 🔴 高风险 | 执行后**强烈建议**运行 `/workflows:review [C]` |

     If no risk assessment in frontmatter, proceed normally (backwards compatible).
````

**验证**:
- [x] 确认 work.md 包含 `Read risk assessment from plan frontmatter`
- [x] 确认包含风险感知执行建议表

---

### Task 4: 修改 work.md Phase 4 Handoff 为风险感知

**文件**: `plugins/compound-engineering/commands/workflows/work.md`
**操作**:
- [ ] 找到 Phase 4 (Ship It) 的 Handoff 部分，修改为根据风险等级动态推荐

**代码**（需要定位 work.md 中现有的 Handoff/next-step 部分，替换为）:

先读取当前 work.md 确认 Handoff 位置，然后替换为：

````markdown
### Phase 5: Handoff（风险感知）

使用 **AskUserQuestion tool** 呈现选项，根据 Phase 1 读取的风险等级动态调整推荐：

**如果 risk_level = low 或无风险评分：**

**Question:** "工作完成。下一步？"

**Options:**
1. **跳过审查，直接完成（推荐）** - 冒烟测试已通过，低风险无需额外审查
2. **运行 `/workflows:review`** - 可选：Claude 多代理代码审查
3. **记录解决方案 `/workflows:compound`** - 如有重要经验值得记录
4. **停止** - 完成

**如果 risk_level = medium：**

**Question:** "工作完成。中风险任务，建议代码审查。"

**Options:**
1. **运行 `/workflows:review`（推荐）** - Claude 多代理代码审查
2. **跳过审查，直接完成** - 如果你对代码有信心
3. **记录解决方案 `/workflows:compound`** - 如有重要经验值得记录
4. **停止** - 完成

**如果 risk_level = high：**

**Question:** "工作完成。高风险任务，强烈建议完整审查。"

**Options:**
1. **运行 `/workflows:review [C]`（推荐）** - Claude + Codex 双重代码审查
2. **运行 `/workflows:review`** - 仅 Claude 代码审查
3. **跳过审查** - 高风险不推荐跳过
4. **停止** - 完成

Based on selection:
- **跳过审查** → 提示用户推送 Git，流程结束
- **`/workflows:review`** → 调用 `/workflows:review`
- **`/workflows:review [C]`** → 调用 `/workflows:review [C]`
- **`/workflows:compound`** → 调用 `/workflows:compound`
- **停止** → 结束流程
````

**验证**:
- [x] 确认 work.md Handoff 包含 3 个风险等级的条件分支
- [x] 确认低风险推荐跳过审查，中风险推荐 review，高风险推荐 review [C]
- [ ] `bash scripts/check-handoff.sh` 中 work.md 仍为 PASS

---

### Phase 3: 文档与收尾

---

### Task 5: 更新 CLAUDE.md 流程说明

**文件**: `plugins/compound-engineering/CLAUDE.md`
**操作**:
- [ ] 在 "### 可用技能（按场景）" 表格后添加风险分级流程说明

**代码**（在可用技能表格后追加）:
````markdown
### 风险分级自适应流程

`/workflows:plan` 生成计划后自动评估风险等级，动态推荐后续步骤：

```
plan 生成 → 自动风险评分 (0-10)
    ↓
🟢 低风险 (0-3)  → work → 冒烟测试 → 完成
🟡 中风险 (4-6)  → 建议 plan_review → work → 建议 review → 完成
🔴 高风险 (7+)   → 建议 deepen-plan + plan_review → work → 建议 review [C] → 完成
```

**用户始终有最终决定权**，系统仅调整推荐选项的顺序。
````

**验证**:
- [x] 确认 CLAUDE.md 包含 `风险分级自适应流程`
- [x] 确认包含 3 级风险的流程图

---

### Task 6: 更新根 CLAUDE.md 流程说明

**文件**: `CLAUDE.md`（根目录）
**操作**:
- [ ] 在相关文档表格中添加风险分级说明链接（如需要）

**验证**:
- [x] 确认根 CLAUDE.md 无需更新（风险分级是插件内部机制）或已更新

---

### Task 7: 版本号更新 + CHANGELOG

**文件**: `.claude-plugin/marketplace.json`, `plugins/compound-engineering/.claude-plugin/plugin.json`, `plugins/compound-engineering/CHANGELOG.md`
**操作**:
- [ ] patch bump 版本号（2.43.0 → 2.43.1）
- [ ] 添加 CHANGELOG 条目

**代码**:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch
```

CHANGELOG 条目：
```markdown
## [v2.43.1] - 2026-03-06

### Changed
- plan.md: 计划生成后自动输出风险评分（0-10），写入 frontmatter
- plan.md: Handoff 选项根据风险等级动态调整推荐
- work.md: 读取风险评分，Phase 5 Handoff 根据风险等级推荐不同审查深度
- CLAUDE.md: 添加风险分级自适应流程说明
```

**验证**:
- [x] `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 通过
- [x] CHANGELOG.md 包含 v2.43.1 条目

---

### Task 8: 最终冒烟测试

**操作**:
- [ ] 运行 Handoff lint 检查
- [ ] 运行版本一致性检查

**代码**:
```bash
bash scripts/check-handoff.sh
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

**验证**:
- [x] check-handoff.sh 全部 PASS
- [x] check-versions.ps1 全部 PASS

---

## 延后项

| 项目 | 延后理由 |
|------|----------|
| 抽检复审机制 | 需要更多使用数据才能设计有意义的抽检策略 |
| 风险评分可视化图表 | 当前文本展示足够，图表是锦上添花 |
| 自动重评分（计划修改后） | 增加复杂度，手动重新运行 plan 更简单 |
| 风险评分 A/B 测试指标 | 需要先积累使用数据 |

## References

- Brainstorm: `docs/brainstorms/2026-03-06-workflow-pipeline-optimization-brainstorm.md`
- Codex 咨询结论：方案 D（风险分级自适应）
- SpecFlow 分析：5 个 CRITICAL 问题已在计划中解决
- 现有 workflow 文件：`plugins/compound-engineering/commands/workflows/*.md`
