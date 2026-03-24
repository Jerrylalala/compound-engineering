---
name: plan_review
description: Have multiple specialized agents review a plan in parallel
argument-hint: "[plan file path or plan content]"
---

Have @agent-dhh-rails-reviewer @agent-kieran-rails-reviewer @agent-code-simplicity-reviewer review this plan in parallel.

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

Based on selection:
- **更新计划后执行** → 根据审查意见修改 plan 文件，修改完成后自动调用 `/workflows:work <plan_path>`
- **直接执行** → 直接调用 `/workflows:work <plan_path>`
- **仅更新计划** → 修改 plan 文件后回到选项菜单
- **查看被过滤的建议** → 展示所有被 Adjudicator 移除的建议的详细信息（包括原始声明、验证过程、移除原因），展示后回到选项菜单
- **重新审查** → 重新调用 `/plan_review <plan_path>`
- **停止** → 结束流程

⚠️ **约束**：选择"更新计划后执行"或"直接执行"时，必须通过 `/workflows:work <plan_path>` 执行计划，不得在主对话中直接编写代码实现计划中的任务。这确保 ≥2 任务时自动启用 Subagent 并行模式。

**注意**：`<plan_path>` 应从调用 `/plan_review` 时传入的参数中获取。如果参数为空，扫描 `docs/plans/*.md` 获取最近修改的计划文件。
