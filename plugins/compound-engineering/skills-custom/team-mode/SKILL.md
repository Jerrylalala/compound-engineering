---
name: team-mode
description: "Multi-agent collaboration overlay for ce:brainstorm/plan/work/review. Enables contract-gated execution with single writer principle, verifier hooks, and deterministic patch gate for autofix stability."
argument-hint: "[team] | [team:full]"
---

# Team Mode Overlay

> **核心理念**：稳定性来自规则，不来自更多 agent。合约白名单 + 单写者原则 + 验证前移 = 问题被拦截在发生前。

本 skill 是叠加在 `ce:brainstorm`/`ce:plan`/`ce:work`/`ce:review` 之上的 overlay。各命令通过检测 `[team]`、`[team:full]` token 激活对应的角色集和机制。

---

## 参数变体

| Token | 角色集 | 适用场景 |
|-------|--------|---------|
| `[team]` | 合约主 + 执行者 + 验证者（3角色） | 默认，大多数任务 |
| `[team:full]` | 合约主 + 执行者 + 验证者 + 风险卫（4角色） | auth/payment/migration 高风险路径 |

---

## 角色定义

| 中文名 | 适用阶段 | 职责 | 生命周期 |
|--------|---------|------|---------|
| **合约主** | plan, work | 执行前写边界合约（allowed_files/forbidden_surfaces/invariants），全程持有合约权威。通过 `.team-contract.md` 文件持久化，不是独立 subagent | 全程存活（文件持久化） |
| **执行者** | work | **唯一可写共享代码的角色**（单写者原则）。遇越界暂停上报，不自行决策 | 按任务运行 |
| **验证者** | work | 每 Implementation Unit 完成后运行集成测试和不变式检查，只读不写。发现回归立即报警，不继续 | 事件驱动（每任务后） |
| **风险卫** | work（[team:full]） | 专门拦截高风险路径（auth/session/permission/payment/billing/migration/schema），执行前生成风险摘要并要求用户确认 | 仅 [team:full] 模式 |
| **追溯审查** | plan | 搜索 `docs/solutions/` 查找历史相关案例，检查计划决策是否与已记录 gotcha 矛盾，将发现追加到计划 Open Questions 节 | ce:plan Phase 4.5（只读） |
| **探索者** | brainstorm | 聚焦「这个想法在技术上可行吗？」，提出具体验证路径和可达条件 | ce:brainstorm [team] 激活期间 |
| **挑战者** | brainstorm | 质疑假设，寻找边界条件和反例，防止过早收敛 | ce:brainstorm [team] 激活期间 |

### 各阶段角色集

| 阶段 | 默认角色 | [team:full] 追加 |
|------|---------|-----------------|
| `/ce:brainstorm [team]` | 探索者 + 挑战者 | — |
| `/ce:plan [team]` | 合约主 + 追溯审查 | — |
| `/ce:work [team]` | 合约主 + 执行者 + 验证者 | 风险卫 |
| `/ce:review [team]` | 现有多个专业审查 agent + Patch Gate | — |

**[team:full] 在各命令的行为**：
- `ce:brainstorm [team:full]`：等同于 `[team]`（brainstorm 阶段无风险卫角色，[team:full] 与 [team] 行为相同）
- `ce:plan [team:full]`：等同于 `[team]`（plan 阶段无风险卫角色，触发同样的 Phase 4.5 合约生成）
- `ce:work [team:full]`：在 3 角色基础上追加风险卫（4 角色完整模式）
- `ce:review [team:full]`：等同于 `[team]`（Patch Gate 行为无差别）

传入不支持 [team:full] 差异的命令时，AI 应将其等同处理为 [team]，不产生错误。

---

## 单写者原则（Iron Law）

**ONLY 执行者 writes to shared checkout.**

```
其他角色职责分配：
  合约主   → 只读 .team-contract.md；写入仅限合约文件本身（初始化阶段）
  验证者   → 只读代码和测试输出；不修改任何文件（包括 .team-contract.md）
  风险卫   → 只读代码；不修改任何文件
  执行者   → 唯一可修改业务代码的角色；验证失败时负责写入 last_verification_failure
```

**违反后果**：
- 如果非执行者角色尝试写代码 → 立即停止，上报违规，等待用户确认
- 如果执行者尝试写 allowed_files 以外的文件 → 暂停，报告越界，等待用户确认
- 如果执行者尝试写 forbidden_surfaces 中的文件 → 拒绝执行，要求修改计划

**为什么这条规则比增加 agent 更有效**：多个 agent 并发写代码会导致冲突、覆盖、和状态不一致。单写者消除这类错误的根源，而不是事后补救。

---

## .team-contract.md 格式规范

> **Source of Truth**：本节是 `.team-contract.md` 格式的唯一权威定义。`ce:plan/SKILL.md` 的 Phase 4.5 包含格式副本用于生成指引，若两处有出入，以本节为准。

合约文件使用 YAML frontmatter（而非 Markdown 表格），便于规则引擎程序化解析：

```yaml
---
team_mode: true
generated_by: "ce:plan [team]"
generated_at: YYYY-MM-DD
plan_source: docs/plans/PLAN_FILENAME.md
plan_source_commit: <git-commit-hash>   # 生成时 plan_source 的最新 commit hash，用于检测计划是否已更新
allowed_files:
  - path/to/file1.md
  - path/to/file2.md
forbidden_surfaces:
  - plugins/compound-engineering/.claude-plugin/plugin.json
  - CHANGELOG.md
required_invariants:
  - "bash scripts/check-handoff.sh 必须通过"
  - "不得移除 argument-hint 中已有的 [C][G][P] 标志"
max_files_per_patch: 1
last_verification_failure: null
---

# Team Contract

## 背景
[可选：描述本次任务的背景和边界约束]
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `allowed_files` | string[] | 执行者在本次任务中允许修改的文件列表（由 ce:plan 从 Implementation Units 提取）。**匹配规则：精确路径匹配（完整 repo-relative 路径），不支持通配符（`src/*` 无效），不支持目录前缀（`src/` 不匹配 `src/foo.ts`），如需覆盖目录须逐个列出文件** |
| `forbidden_surfaces` | string[] | 绝对禁止自动修改的文件（版本文件、schema、认证配置等） |
| `required_invariants` | string[] | 每次变更后必须满足的不变式（由 ce:plan 从 Acceptance Criteria 转换） |
| `max_files_per_patch` | int | 单次 autofix patch 允许修改的最大文件数（默认 1，即 one-finding-one-patch） |
| `last_verification_failure` | string\|null | 执行者记录最近一次验证失败信息（null 表示无失败） |
| `plan_source_commit` | string\|null | 生成合约时 plan_source 的 git commit hash；ce:work 加载时与当前 hash 对比，检测计划是否已更新 |

---

## 各命令激活方式

### ce:brainstorm [team]

激活探索者 + 挑战者角色对（结构化探索，有明确收敛条件）：

```
探索者：聚焦「这个想法在技术上可行吗？」，提出具体验证路径
挑战者：质疑假设，寻找边界条件和反例，防止过早收敛

退出条件（满足任一）：
  - 双方达成「方向共识」（可行性 + 主要风险均已识别）
  - 用户输入 [E]
  - 未达共识降级（经过 3 轮）：用 AskUserQuestion 展示双方核心分歧点，让用户选择采纳方向，然后继续

「1轮」= 探索者 + 挑战者各回应一次（不含用户初始触发）
  
与 [P] 的区别：
  [P] = 发散（14个专家自由讨论）
  [team] = 收敛（2个角色结构化验证）
  [P][team] = 先 [P] 发散 → 退出 → [team] 结构化挑战验证（顺序执行）
```

### ce:plan [team]

在 Phase 4（Write the Plan）之后触发 Phase 4.5（合约生成）：

```
合约主激活：
  1. 读取刚生成的计划文件
  2. 从所有 Implementation Units 的 Files 字段收集 allowed_files
  3. 从计划描述识别高风险文件 → forbidden_surfaces
  4. 从 Acceptance Criteria 转换 → required_invariants
  5. 写入 .team-contract.md（repo 根目录）

追溯审查激活：
  1. 搜索 docs/solutions/ 查找历史相关案例
  2. 检查计划决策是否与历史 gotcha 矛盾
  3. 将发现追加到计划的 Open Questions 节
```

### ce:work [team] / [team:full]

在 Phase 0（Input Triage）之前执行 Phase -1（Team Mode 初始化）：

```
1. 检测 team token 变体（default/full）
2. 加载 .team-contract.md（如不存在，提示并询问是否继续无合约模式）
   版本检测：合约加载后，运行：
     git log -1 --format='%H' -- <plan_source>
   将结果与合约中的 plan_source_commit 对比：
   - plan_source_commit 为 null：提示"计划版本未记录"，跳过版本检测，继续
   **版本检测说明**：`plan_source_commit` 在典型工作流（ce:plan 生成后立即执行 ce:work，计划未提交）中始终为 null，版本检测跳过是预期行为。
   如需启用版本检测：
   1. 运行 `ce:plan [team]` 生成计划和合约
   2. `git commit` 计划文件
   3. 手动更新 `.team-contract.md` 中的 `plan_source_commit` 字段为 commit hash
   4. 再运行 `ce:work [team]`
   - 一致：正常继续
   - 不一致：警告"⚠️ 计划已更新（合约版本不匹配），建议重新运行 /ce:plan [team] 刷新合约"
             询问用户是否继续使用旧合约
3. 宣告激活的角色集
4. 在每个 Implementation Unit 前：
   - 执行者检查文件边界（allowed_files / forbidden_surfaces）
   - [team:full] 风险卫检查高风险模式 → 要求用户确认
     **风险卫执行规范**：
     - 时机：每个 Implementation Unit 开始前（执行者读计划、准备修改文件前）
     - 输入：当前 Unit 的描述文字 + Files 列表（不读代码，不消耗额外 token）
     - 匹配：检测高风险关键词（`auth`/`session`/`permission`/`payment`/`billing`/`migration`/`schema`/`seed`）
     - 用户确认后：继续执行该 Unit
     - 用户拒绝后：跳过该 Unit，记录到 `.team-contract.md` 的 work_log，不自动 fail

**并行 subagent 的文件边界约束**（当 ce:work 派发多个并行 subagent 时）：
- 合约主在派发前检查各 Implementation Unit 的 Files 列表：
  - 各 subagent 的文件集合必须**互不重叠**（no intersection）
  - 如有交集：将涉及共享文件的任务改为串行执行，不并行
- 所有并行 subagent 完成后，验证者额外运行一次全局不变式检查（覆盖跨 subagent 的组合影响）
- 这不影响每个 subagent 完成后的局部验证者 Hook（局部 + 全局双层保护）

5. 在每个 Implementation Unit 完成后：
   - 验证者运行 Verification 步骤中的测试命令
   - 验证者检查 required_invariants
   - 如失败：停止，写入 last_verification_failure，等待执行者修复
```

**[T]+[team] 的 Phase 3.5 Layer 3 全局确认**（补充单任务局部验证）：
- Layer 3 只核查跨任务维度的验收场景（不重复 team 验证者 Hook 已覆盖的单任务条目）
- 若发现跨任务组合破坏了不变式：进入标准 BLOCKED 检查点（见下方），不触发新一轮 team 验证者 Hook
- 并行 subagent 场景下，Layer 3 全局确认在所有 subagent 完成后额外运行一次全局不变式检查

#### BLOCKED 检查点（仅当 [T] 同时激活时）

当 Phase 3.5 验证失败达到 2 轮上限，ce:work 使用标准 AskUserQuestion 工具（team 模式下的提示文字包含团队上下文）：

> "⚠️ [T]+[team] 验证未通过（已重试 N 轮）
> 团队模式失败层：[层名] — [失败原因摘要]
> Layer 0 层内重试：[N] 次
>
> 1. 查看详细错误，执行者手动修复后重新运行验证（重置轮次）
> 2. 跳过验证，降级为标准模式继续 Phase 4（PR 描述标注验证未通过）
> 3. 停止，稍后处理"

选择说明：
- 选 1 → 执行者读取 `.ce-work-verification.json` 的 layer 失败信息，修复后重置 verification_rounds，重跑 Phase 3.5
- 选 2 → 继续 Phase 4，在 PR/commit 描述中标注「⚠️ [T] 验证未通过，人工跳过」
- 选 3 → 结束，保留 `.ce-work-verification.json` 供后续参考

### ce:review [team]（autofix 和 interactive 模式有效，report-only/headless 无效）

在 Stage 5 路由规范化后执行 Deterministic Patch Gate（规则引擎，不消耗额外 token）。

完整 Patch Gate 逻辑见 `ce:review Stage 5 步骤 6.5`。规则摘要：

```
加载 .team-contract.md → 对每条 safe_auto finding：
  规则1（文件范围）：finding.file ∉ allowed_files → gated_auto
  规则2（禁止区域）：finding.file ∈ forbidden_surfaces → gated_auto（需人工确认）
  规则3（单补丁约束）：涉及文件数 > max_files_per_patch → gated_auto
  规则4（不变式验证）：required_invariants 非空 → fixer 需验证后落盘
```

---

## 降级行为（无 .team-contract.md 时）

所有命令在未找到 `.team-contract.md` 时必须优雅降级：

| 情况 | 行为 | 设计原因 |
|------|------|---------|
| ce:work [team] 无合约 | 提示建议先运行 `/ce:plan [team]`；询问是否继续无合约模式（仅宣告角色，不检查边界） | ce:work 会实际修改代码，无合约执行风险较高，需用户知情后确认 |
| ce:review [team] 无合约 | 跳过 Patch Gate，记录警告："未找到 .team-contract.md，Patch Gate 已禁用" | Patch Gate 是审查加强层，跳过不影响代码修改安全性；中断审查流程对用户影响更大 |
| ce:brainstorm/plan [team] | 合约不适用于这两个阶段，正常执行 | — |

---

## 与现有 overlays 的关系

| 现有 Overlay | 与 team-mode 的关系 |
|-------------|-------------------|
| `review-contract` | [team] 模式下，review-contract 的 Tier 分类被 Patch Gate 消费（Blocking Tier → 强制 gated_auto） |
| `patch-approval` | patch-approval 使用隔离 git clone 生成 patch；team-mode 的 Patch Gate 在此之前执行白名单检查 |
| `ce-work-integration` | task-bundle 状态追踪与 team-mode 互补：bundle 追踪任务状态，team-mode 追踪边界合约 |
