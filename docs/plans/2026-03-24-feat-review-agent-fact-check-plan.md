---
title: "feat: 审查代理四段式裁决链（事实核查机制）"
type: feat
date: 2026-03-24
risk_score: 1
risk_level: low
risk_note: "全部改动为 .md 文件，完全可逆，无外部依赖"
---

# feat: 审查代理四段式裁决链（事实核查机制）

## Overview

**Goal**: 在审查代理输出与用户之间插入自动化事实核查与裁决层，防止事实性错误直接影响用户决策
**Tech Stack**: 纯 Prompt Engineering（.md 文件修改，无代码）
**Architecture**: 四段式裁决链 — Reviewers → Fact Checker → Adjudicator → Presenter

(see brainstorm: docs/brainstorms/2026-03-24-review-agent-fact-check-brainstorm.md)

## Problem Statement / Motivation

审查代理在 plan_review 中把「组件级 disabled」和「选项级 disabled」混为一谈，2/3 代理产出相同的事实性错误，形成"共识假象"，差点导致必要 Task 被删除。根因是 plan_review 流程无验证层——纯扇出模式直接呈现结果。

(see brainstorm: 根因分析)

## Proposed Solution

### 架构决策

| 决策 | 选择 | 理由 |
|------|------|------|
| Fact Checker 实现方式 | 内联在命令 .md 中的 prompt 指令 | 简单，无需新 skill；两个命令各自内联；未来可抽取为 skill |
| Finding 格式 | 结构化 Markdown（非严格 YAML） | LLM 产出 YAML 不稳定，Markdown 更可靠 |
| 与现有输出格式的关系 | 追加在代理现有输出末尾的独立 section | 不破坏现有格式，fact-checker 只解析新 section |
| plan_review vs review 的 fact-check 差异 | plan_review 验证当前代码库状态；review 验证 diff 中的代码 | 两者上下文不同 |
| Ambiguous P1 finding 处理 | 展示给用户带警告标记，用户决定 | 不自动删除也不自动创建 todo |
| 独立调用 @agent 时 | 输出新格式但无验证层 | 向后兼容，不强制 |

### Finding 输出格式（审查代理追加在报告末尾）

```markdown
## Structured Findings

### Finding 1
- **Claim**: [具体声明]
- **Type**: exists | missing | dead_work | conflicts_with_plan | risk | opinion
- **Scope**: component | option | method | file | api
- **Evidence**: `[InterfaceName]` in `[file:line]` — "[引用的代码片段]"
- **Proposed Action**: [建议的操作]
- **Confidence**: high | medium | low
- **Assumptions**: [显式列出假设]
- **Counter-checks** (高风险必填):
  - [x] 检查了 [具体内容] — 结果: [结果]
  - [ ] 未检查 [具体内容]
```

### 验证分层

| 验证级别 | 触发条件 | 验证内容 | 自动化程度 |
|----------|---------|---------|-----------|
| L0 不验证 | type=opinion，或纯风格建议 | — | — |
| L1 轻验证 | 普通代码事实声明 | symbol existence + file 校验 | 高 |
| L2 强验证 | type=dead_work/exists/missing 且 proposed_action 涉及删除 task | symbol + scope + counter-check | 高 |
| L3 人工确认 | 架构迁移、数据删除、功能裁撤 | 自动验证 + 标记需人工确认 | 中 |

### 效率控制

- 只验证 type ≠ opinion 的 finding
- 如果 finding 总数 > 20，只验证 L2+ 的 finding
- plan_review 只有 3 个代理，finding 数量可控

## Task Breakdown

### Phase 1: 审查代理 Prompt 强化（6 个 Task）

---

### Task 1: 为 kieran-rails-reviewer 添加 Finding 格式要求

**文件**: `plugins/compound-engineering/agents/review/kieran-rails-reviewer.md:115`
**操作**:
- [ ] 在文件末尾（第 115 行后）追加事实性声明规范和 Structured Findings 输出格式

**代码**:
```markdown

## 事实性声明规范（铁律）

当你的审查涉及以下类型的声明时，必须提供精确证据：

| 声明类型 | 必须提供 |
|----------|---------|
| "X 已存在" | interface/class 名 + 字段/方法名 + 文件:行号 + 代码引用 |
| "X 不需要/是死工作" | 理由 + 替代方案的精确位置 + counter-check |
| "X 是死代码/未使用" | grep 结果证明无引用 |
| "X 已被测试覆盖" | 测试文件:行号 + 测试内容 |

**高风险结论门槛**（涉及"删除 task""判定已实现""建议砍功能"时）：
- 至少 1 条正向证据：现有实现确实覆盖该需求
- 至少 1 条反例排除：不存在需求层级错配（如 component-level vs option-level）
- 没有满足以上条件时，只能输出：`possible overlap, needs human check`

## Structured Findings（必须在报告末尾输出）

在你的审查报告正文之后，追加以下格式的结构化发现：

### Finding N
- **Claim**: [你的具体声明]
- **Type**: exists | missing | dead_work | conflicts_with_plan | risk | opinion
- **Scope**: component | option | method | file | api
- **Evidence**: `[InterfaceName]` in `[file:line]` — "[代码片段]"
- **Proposed Action**: [建议操作]
- **Confidence**: high | medium | low
- **Assumptions**: [你做了什么假设]
- **Counter-checks** (type=dead_work/exists/missing 时必填):
  - [x] 检查了 [内容] — 结果: [结果]
```

**验证**:
- [ ] 读取修改后的文件，确认格式正确且不破坏现有内容

---

### Task 2: 为 kieran-typescript-reviewer 添加同样的 Finding 格式要求

**文件**: `plugins/compound-engineering/agents/review/kieran-typescript-reviewer.md:124`
**操作**:
- [ ] 在文件末尾追加与 Task 1 相同的事实性声明规范和 Structured Findings 格式

**验证**:
- [ ] 读取修改后的文件确认

---

### Task 3: 为 code-simplicity-reviewer 添加 Finding 格式要求

**文件**: `plugins/compound-engineering/agents/review/code-simplicity-reviewer.md:101`
**操作**:
- [ ] 在现有 output format 之后追加事实性声明规范和 Structured Findings 格式
- [ ] 注意保留第 51 行的 protected artifacts 例外规则

**验证**:
- [ ] 读取修改后的文件，确认 protected artifacts 规则未被覆盖

---

### Task 4: 为 dhh-rails-reviewer 添加 Finding 格式要求

**文件**: `plugins/compound-engineering/agents/review/dhh-rails-reviewer.md`
**操作**:
- [ ] 在文件末尾追加事实性声明规范和 Structured Findings 格式

**验证**:
- [ ] 读取修改后的文件确认

---

### Task 5: 为其余 review 代理批量添加 Finding 格式（6 个文件）

**文件**:
- `agents/review/architecture-strategist.md`
- `agents/review/security-sentinel.md`
- `agents/review/performance-oracle.md`
- `agents/review/pattern-recognition-specialist.md`
- `agents/review/data-integrity-guardian.md`
- `agents/review/agent-native-reviewer.md`

**操作**:
- [ ] 为每个文件在末尾追加事实性声明规范和 Structured Findings 格式
- [ ] 对于已有 output format 的代理（security-sentinel、performance-oracle、agent-native-reviewer），在现有格式之后追加

**验证**:
- [ ] 逐一读取确认每个文件的修改

---

### Task 6: 为条件性 review 代理添加 Finding 格式（4 个文件）

**文件**:
- `agents/review/data-migration-expert.md`
- `agents/review/deployment-verification-agent.md`
- `agents/review/julik-frontend-races-reviewer.md`
- `agents/review/schema-drift-detector.md`

**操作**:
- [ ] 为每个文件在末尾追加事实性声明规范和 Structured Findings 格式

**验证**:
- [ ] 逐一读取确认

---

### Phase 2: plan_review 四段式裁决链（2 个 Task）

---

### Task 7: 重写 plan_review.md 添加 Fact-Check + Adjudicator + Presenter

**文件**: `plugins/compound-engineering/commands/plan_review.md`
**操作**:
- [ ] 保留 frontmatter（第 1-5 行）
- [ ] 保留第 7 行的代理调用
- [ ] 在代理调用和 Post-Review Actions 之间，插入三个新阶段

**代码**（在第 7 行之后、第 9 行之前插入）:

```markdown

## Fact-Check Phase（审查代理完成后自动执行）

审查代理报告收集完成后，对所有 Structured Findings 中的事实性声明进行自动验证。

### Step 1: 提取需验证的 Finding

从每份审查报告的 `## Structured Findings` 部分提取所有 finding。

**验证分层规则：**
- `type: opinion` → 标记为 `verification: not_applicable`，跳过验证
- `type: risk` 且无具体代码引用 → 标记为 `verification: not_applicable`
- `type: exists | missing | dead_work | conflicts_with_plan` → 必须验证
- 如果 `proposed_action` 包含"删除""跳过""不需要"等词且指向 Plan 中的 Task → 标记为 **高风险**，必须 L2 验证

### Step 2: 执行分级验证

对每条需验证的 finding，按级别执行：

**L1 轻验证（所有可验证 finding）：**
- 使用 Grep 工具搜索 `evidence.symbol` 在 `evidence.file` 中是否存在
- 如果文件不存在 → `verification: file_not_found`
- 如果 symbol 不存在 → `verification: symbol_not_found`

**L2 强验证（高风险 finding，涉及删除 Task）：**
- L1 的所有检查
- **Scope Check**: 使用 Read 工具读取 evidence.file 的相关区域（±20 行），确认 symbol 所在的 interface/class/function 是否与 finding 声称的 scope 一致
- **Counter-check 验证**: 检查 finding 中列出的 counter-checks 是否完整
  - 如果 counter-checks 为空或缺失 → `verification: insufficient_evidence`
- **需求匹配**: 将 finding 声称的"已存在能力"与 Plan 中对应 Task 的目标进行对比，检查是否存在 scope 错配（如 component-level vs option-level）

### Step 3: 标注验证结果

为每条 finding 追加验证状态：
- ✅ `verified` — 声明与代码一致，scope 正确
- ❌ `refuted` — 声明与代码矛盾（symbol 不存在、scope 错配等）
- ⚠️ `ambiguous` — 无法确定（symbol 存在但 scope 不明确、counter-check 不完整）
- ℹ️ `not_applicable` — opinion 类型或无代码引用
- 🔍 `not_checked` — 超出自动验证能力

## Adjudicator Phase

基于验证结果进行裁决：

### 规则 1: 过滤已证伪的高风险建议
如果 finding 的 `verification: refuted` 且 `proposed_action` 涉及删除 Plan 中的 Task：
→ **自动移除该建议**
→ 在报告中说明：「审查代理建议删除 Task N，但事实核查发现其依据不成立（[具体原因]），建议保留该任务。」

### 规则 2: Dependency Collapse（伪共识检测）
如果多个代理的 finding 引用了同一 symbol + 同一 file + 同一 scope 作为前提：
→ 将这些 finding 视为 **同一证据簇**（1 票），而非独立共识（N 票）
→ 在报告中标注：「N 个代理基于相同前提得出相同结论，算作 1 条独立证据」

### 规则 3: 降级未验证的高风险建议
如果 finding 的 `verification: ambiguous` 且 `proposed_action` 涉及删除 Task：
→ 不直接展示为结论
→ 改为：「候选结论：[claim]。验证状态：⚠️ 待确认。原因：[原因]。请人工核实。」

### 规则 4: 保留已验证的建议
`verification: verified` 的 finding → 正常展示，标注 ✅

## Presenter Phase

向用户展示经过事实核查的审查结果：

```
## 审查结果（已经过事实核查）

| # | 审查意见 | 代理 | 类型 | 验证状态 | 风险 |
|---|---------|------|------|---------|------|
| 1 | [claim] | [agents] | [type] | ✅/❌/⚠️ | 高/中/低 |

### ❌ 已移除的建议（事实核查未通过）
[列出被 Adjudicator 移除的建议及原因]

### ⚠️ 待确认的建议（需人工核实）
[列出 ambiguous 的高风险建议]

### ✅ 已验证的建议
[列出 verified 的建议，按优先级排序]

### ℹ️ 设计意见（无需事实验证）
[列出 opinion 类型的建议]
```
```

**验证**:
- [ ] 读取完整文件，确认 Fact-Check + Adjudicator + Presenter + Post-Review Actions 四个阶段完整且顺序正确
- [ ] 确认 frontmatter 和代理调用行未被修改

---

### Task 8: 更新 plan_review.md 的 Post-Review Options

**文件**: `plugins/compound-engineering/commands/plan_review.md`
**操作**:
- [ ] 在现有选项 4（重新审查）之前插入"查看被过滤的建议"选项

**代码**（修改 Post-Review Actions 部分）:

```markdown
## Post-Review Actions

审查代理完成并经过事实核查后，整合并展示所有审查意见摘要。

然后使用 **AskUserQuestion tool** 呈现选项：

**Question:** "计划审查完成（含事实核查）。下一步？"

**Options:**
1. **更新计划后执行** - 根据已验证的审查意见修改计划，然后运行 `/workflows:work`（推荐）
2. **直接执行 `/workflows:work`** - 按原计划开始实现
3. **仅更新计划** - 修改计划但暂不执行
4. **查看被过滤的建议** - 查看事实核查未通过而被移除的建议详情
5. **重新审查** - 重新运行 `/plan_review`
6. **停止** - 不执行，稍后处理
```

**验证**:
- [ ] 读取完整文件确认选项完整

---

### Phase 3: workflows:review 四段式裁决链（2 个 Task）

---

### Task 9: 在 workflows:review 的 Synthesis 阶段前插入 Fact-Check + Adjudicator

**文件**: `plugins/compound-engineering/commands/workflows/review.md:265`
**操作**:
- [ ] 在现有 Step 5（Findings Synthesis）之前，插入 Fact-Check Phase 和 Adjudicator Phase
- [ ] 复用 Task 7 中定义的三个阶段的 prompt 指令（适配 code review 上下文）
- [ ] 修改 Step 5 的 synthesis_tasks，增加"Discard findings with verification: refuted"规则

**关键差异**（与 plan_review 的不同）：
- review 验证的是 diff 中的代码，不是 plan 引用的代码
- review 的 finding 数量更多（9+ 代理），需要 finding 数量 > 20 时只验证 L2+ 的效率控制
- review 的 todo 创建流程需要传递 verification_status

**代码**（在 Step 4 code-simplicity-reviewer 调用之后、Step 5 之前插入）:

```markdown
### 4.5. Fact-Check Phase（代理审查完成后自动执行）

对所有代理产出的 Structured Findings 进行事实核查。

**效率控制：** 如果所有代理产出的 finding 总数 > 20，只对 type=dead_work/exists/missing 且 proposed_action 涉及代码修改的 finding 执行 L2 验证。其余 finding 标记为 `not_checked`。

执行与 plan_review 相同的三步验证流程（Step 1 提取 → Step 2 分级验证 → Step 3 标注），差异点：
- **Evidence 验证基于 diff**：使用 `git diff` 确认 finding 引用的代码行在当前 PR 中是否存在
- **Scope Check 使用 PR 文件列表**：只在 PR 变更的文件中搜索，而非全项目

### 4.6. Adjudicator Phase

执行与 plan_review 相同的四条裁决规则。

额外规则（code review 特有）：
- **规则 5: Protected Artifacts 过滤** — 任何建议删除 `docs/plans/*.md` 或 `docs/solutions/*.md` 的 finding，自动标记为 `refuted`（与 Step 1 Protected Artifacts 一致）
```

**验证**:
- [ ] 读取 review.md 第 260-290 行，确认新阶段插入位置正确
- [ ] 确认 Step 5 synthesis_tasks 中包含"Discard findings with verification: refuted"

---

### Task 10: 修改 workflows:review 的 Step 5 Synthesis 以集成验证状态

**文件**: `plugins/compound-engineering/commands/workflows/review.md:275-283`
**操作**:
- [ ] 在 synthesis_tasks 的第二条"Discard any findings that recommend deleting..."之后，追加 verification 相关过滤规则
- [ ] 在 todo 文件创建时，将 verification_status 写入 YAML frontmatter

**代码**（修改 synthesis_tasks）:

```markdown
<synthesis_tasks>

- [ ] Collect findings from all parallel agents
- [ ] Discard any findings that recommend deleting or gitignoring files in `docs/plans/` or `docs/solutions/` (see Protected Artifacts above)
- [ ] **Discard findings with `verification: refuted`**（事实核查未通过的建议）
- [ ] **将 `verification: ambiguous` 的高风险 finding 降级为 P3**，并标注需人工确认
- [ ] Categorize by type: security, performance, architecture, quality, etc.
- [ ] Assign severity levels: 🔴 CRITICAL (P1), 🟡 IMPORTANT (P2), 🔵 NICE-TO-HAVE (P3)
- [ ] Remove duplicate or overlapping findings
- [ ] **Apply dependency collapse**: 多个 finding 基于同一前提时合并为一条
- [ ] Estimate effort for each finding (Small/Medium/Large)

</synthesis_tasks>
```

**验证**:
- [ ] 读取修改后的 synthesis_tasks 确认规则完整

---

### Phase 4: 收尾（2 个 Task）

---

### Task 11: 更新版本号

**操作**:
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch`
- [ ] 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认一致

**验证**:
- [ ] check-versions.ps1 输出无错误

---

### Task 12: 更新 CHANGELOG.md

**文件**: `CHANGELOG.md`
**操作**:
- [ ] 在最新版本条目下添加本次变更记录

**代码**:
```markdown
### [新版本号]
- feat(review): 审查代理添加 Structured Findings 输出格式（15 个 review agents）
- feat(plan-review): plan_review 添加四段式裁决链（Fact-Check → Adjudicator → Presenter）
- feat(review): workflows:review 添加四段式裁决链
- fix(review): 防止审查代理事实性错误直接影响用户决策
```

**验证**:
- [ ] 读取 CHANGELOG.md 确认条目格式正确

---

## Acceptance Criteria

- [ ] 所有 15 个 review agent .md 文件包含事实性声明规范和 Structured Findings 格式
- [ ] plan_review.md 包含完整的 Fact-Check + Adjudicator + Presenter 三阶段
- [ ] workflows/review.md 包含完整的 Fact-Check + Adjudicator + Presenter 三阶段
- [ ] plan_review 的高风险建议（删除 Task）必须经过 L2 验证才能呈现
- [ ] 被证伪的建议不直接展示给用户
- [ ] 多代理相同前提的 finding 通过 dependency collapse 合并为 1 票
- [ ] 版本号已更新且一致
- [ ] CHANGELOG 已更新

## Success Metrics

- 审查代理的事实性错误不再直接呈现给用户
- 用户看到的审查结果带有验证状态标注
- 高风险建议（删除 Task）需要有 verified 证据才能呈现

## Dependencies & Risks

| 风险 | 缓解 |
|------|------|
| LLM 不严格遵循 Structured Findings 格式 | 使用 Markdown 而非 YAML；格式为"best-effort" |
| Fact-check grep 产生假阳性（找到同名但不同 scope 的 symbol） | L2 验证包含 Scope Check 读取上下文 |
| Finding 数量过多导致 fact-check 耗时 | >20 findings 时只验证高风险项 |
| 代理独立调用时无验证层 | 向后兼容：格式 informational，无 false precision 风险声明 |

## References & Research

- Brainstorm: `docs/brainstorms/2026-03-24-review-agent-fact-check-brainstorm.md`
- 经验库: `docs/solutions/integration-issues/superpowers-fusion-code-review-2026-03-11.md`（5 步验证门控）
- 经验库: `~/.compound/solutions/prompt-redundancy-vs-dry-in-llm-instructions.md`（冗余策略）
- Codex 分析: 四段式裁决链、8 个 fact-check 难点、分级证据核查（见 brainstorm 文档）
