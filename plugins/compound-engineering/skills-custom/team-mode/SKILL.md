---
name: team-mode
description: "Multi-agent collaboration overlay for ce:plan/work/review. ce:brainstorm structured convergence is built-in to [P] mode, not via [T]. Enables contract-gated execution with single writer principle, real Agent Teams verifier, and deterministic patch gate."
argument-hint: "[T] | [T+]"
---

# Team Mode Overlay

> **核心理念**：合约边界 + 单写者原则 + 独立验证者 = 问题在发生前被拦截。
>
> **各命令的实现层次不同**：
> - `ce:work [T]`：真实 Claude Code Agent Teams（TeamCreate + 独立 context window + SendMessage）
> - `ce:brainstorm [P]`：[P] 结束后自动触发探索者+挑战者收敛（无独立 [T] 参数，避免与 Claude Code Agent Teams 混淆）
> - `ce:plan [T]`：同一 agent 多任务（有意设计，合约生成和追溯审查是顺序文档处理，不需要验证循环）
> - `ce:review [T]`：规则引擎（有意设计，Patch Gate 是 deterministic whitelist check，零 token）

本 skill 是叠加在 `ce:plan`/`ce:work`/`ce:review` 之上的 overlay。各命令通过检测 `[T]`、`[T+]` token 激活对应的角色集和机制。`ce:brainstorm` 不支持 `[T]` 参数，结构化收敛已内置为 `[P]` 的自动后续行为。

---

## 参数变体

| Token | ce:work 实现 | ce:plan/review 实现 | 适用场景 |
|-------|-------------|---------------------|---------|
| `[T]` | TeamCreate + verifier teammate（独立 context window）+ lead 扮演合约主+执行者 | 同一 agent（plan=合约生成，review=规则引擎） | 默认，大多数任务 |
| `[T+]` | 在 `[T]` 基础上额外 spawn risk-guard teammate | 同 `[T]`（plan/review 无额外角色） | auth/payment/migration 高风险路径 |

> **ce:brainstorm 不使用 [T] 参数**：结构化收敛（探索者+挑战者）已内置为 [P] 结束后的自动行为，避免与 Claude Code 原生 Agent Teams 混淆。

---

## 角色定义

| 中文名 | 适用阶段 | 职责 | 生命周期 |
|--------|---------|------|---------|
| **合约主** | plan, work | 执行前写边界合约（allowed_files/forbidden_surfaces/invariants），全程持有合约权威。`.team-contract.md` 作为团队章程（所有 teammate 启动时读取），不是通信介质 | 全程存活（文件持久化） |
| **执行者** | work | **唯一可写共享代码的角色**（单写者原则）。遇越界暂停上报，不自行决策 | 按任务运行 |
| **验证者** | work | 独立 context window 的真实 teammate。等待 lead 发 SendMessage 通知，运行不变式检查，只读不写，回复 PASS/FAIL | 事件驱动（每 Unit 完成后收到 SendMessage） |
| **风险卫** | work（[T+]） | 独立 context window 的真实 teammate。等待 lead 发 Unit 开始通知，检测高风险关键词，回复拦截或通过，要求用户确认才继续 | 仅 [T+] 模式，Unit 开始前 |
| **追溯审查** | plan | 搜索 `docs/solutions/` 查找历史相关案例，检查计划决策是否与已记录 gotcha 矛盾，将发现追加到计划 Open Questions 节 | ce:plan Phase 4.5（只读） |
| **探索者** | brainstorm | 聚焦「这个想法在技术上可行吗？」，提出具体验证路径和可达条件 | ce:brainstorm [P] 结束后自动触发（非独立参数） |
| **挑战者** | brainstorm | 质疑假设，寻找边界条件和反例，防止过早收敛 | ce:brainstorm [P] 结束后自动触发（非独立参数） |

### 各阶段角色集

| 阶段 | 默认角色 | [T+] 追加 |
|------|---------|-----------------|
| `/ce:brainstorm [P]` | [P] 结束后自动收敛（探索者+挑战者，内置，无需 [T]） | — |
| `/ce:plan [T]` | 合约主 + 追溯审查 | — |
| `/ce:work [T]` | 合约主 + 执行者 + 验证者 | 风险卫 |
| `/ce:review [T]` | 现有多个专业审查 agent + Patch Gate | — |

**[T+] 在各命令的行为**：
- `ce:plan [T+]`：等同于 `[T]`（plan 阶段无风险卫角色，触发同样的 Phase 4.5 合约生成）
- `ce:work [T+]`：在 3 角色基础上追加风险卫（4 角色完整模式）
- `ce:review [T+]`：等同于 `[T]`（Patch Gate 行为无差别）

传入不支持 [T+] 差异的命令时，AI 应将其等同处理为 [T]，不产生错误。

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
generated_by: "ce:plan [T]"
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
| `required_invariants` | string[] | 每次变更后必须满足的不变式（由 ce:plan 从 `## 验收场景` 章节和 Unit Verification 字段转换） |
| `max_files_per_patch` | int | 单次 autofix patch 允许修改的最大文件数（默认 1，即 one-finding-one-patch） |
| `last_verification_failure` | string\|null | 执行者记录最近一次验证失败信息（null 表示无失败） |
| `plan_source_commit` | string\|null | 生成合约时 plan_source 的 git commit hash；ce:work 加载时与当前 hash 对比，检测计划是否已更新 |

---

## 各命令激活方式

### ce:plan [T]

> **实现层次**：同一 agent 执行合约主和追溯审查两项任务（有意设计）。
> 原因：plan 阶段是文档生成，不是验证循环；合约主从计划文件提取 allowed_files 是文档处理，追溯审查是历史搜索，两者都是顺序任务，spawn 真实 teammate 的开销不合理。`.team-contract.md` 作为后续 ce:work 阶段所有 teammate 共享的团队章程。

在 Phase 4（Write the Plan）之后触发 Phase 4.5（合约生成）：

```
合约主激活：
  1. 读取刚生成的计划文件
  2. 从所有 Implementation Units 的 Files 字段收集 allowed_files
  3. 从计划描述识别高风险文件 → forbidden_surfaces
  4. 从 `## 验收场景` 章节和 Unit Verification 字段转换 → required_invariants
  5. 写入 .team-contract.md（repo 根目录）

追溯审查激活：
  1. 搜索 docs/solutions/ 查找历史相关案例
  2. 检查计划决策是否与历史 gotcha 矛盾
  3. 将发现追加到计划的 Open Questions 节
```

### ce:work [T] / [T+]

使用 Claude Code 原生 Agent Teams（真实独立 context window），而非角色模拟。

#### Phase -1: 真实 Agent Teams 初始化

```
1. 检测 team token 变体（default/full）

2. 创建命名团队（精确到秒，防止同小时内重复碰撞）：
   TEAM_NAME = "ce-work-{YYYYMMDDTHHmmss，如20260410T143022}"
   TeamCreate(TEAM_NAME)

3. 读取 .team-contract.md（如存在，来自 ce:plan [T] 生成的合约）
   版本检测：合约加载后，运行：
     git log -1 --format='%H' -- <plan_source>
   将结果与合约中的 plan_source_commit 对比：
   - plan_source_commit 为 null：提示"计划版本未记录"，跳过版本检测，继续
   **版本检测说明**：`plan_source_commit` 在典型工作流（ce:plan 生成后立即执行 ce:work）中始终为 null，版本检测跳过是预期行为。
   - 一致：正常继续
   - 不一致：警告"⚠️ 计划已更新，建议重新运行 /ce:plan [T] 刷新合约"，询问用户是否继续

4. Spawn verifier teammate（只读角色，独立 context window）：
   Agent(
     team=TEAM_NAME,
     name="verifier",
     prompt="""
       你是验证者 teammate（只读角色，不修改任何文件）。
       启动后读取 .team-contract.md，了解 required_invariants。
       等待 lead 通过 SendMessage 激活。每次收到消息时执行一次验证，完成后回复结果，然后等待下一次激活。

       消息格式（Lead → 你）：
         「Unit {unit_id} 已完成。变更文件：[file1, file2, ...]。请验证。」
         「所有 Unit 完成。请运行全量集成验证。」

       收到后执行：
       1. 读取 .team-contract.md 中的 required_invariants（只读）
       2. 读取变更文件内容（只读）
       3. 运行 required_invariants 中的所有验证命令
       4. 通过 SendMessage 回复 lead：
          - 通过：「Unit {unit_id}: PASS. 所有 invariants 验证通过。」
          - 失败：「Unit {unit_id}: FAIL. 原因：{reason}. 命令输出：{output}」

       铁律：
       - 严禁修改任何文件（包括 .team-contract.md）
       - 严禁执行写操作（git commit、文件写入等）
       - 收到「所有 Unit 完成」后，运行全量验证，这是最后一次检查
     """
   )

5. [T+] 额外 spawn risk-guard teammate（只读角色）：
   Agent(
     team=TEAM_NAME,
     name="risk-guard",
     prompt="""
       你是风险卫 teammate（只读角色，不修改任何文件）。
       等待 lead 发来 Unit 开始通知。每次收到通知时执行一次风险检测，完成后回复结果，然后等待下一次通知。

       消息格式（Lead → 你）：
         「Unit {unit_id} 开始。描述：{desc}。文件：[file1, ...]」

       收到后执行：
       检测以下高风险关键词（在描述和文件名中）：
         auth / session / permission / payment / billing / migration / schema / seed

       回复格式：
       - 无风险：「Unit {unit_id}: 风险卫通过。」
       - 有风险：「⚠️ Unit {unit_id}: 风险拦截。涉及高风险路径 [{keywords}]。需用户确认后继续。」

       铁律：严禁修改任何文件
     """
   )

6. 宣告团队就绪：
   「🤝 Agent Team 已就绪：{TEAM_NAME}
    - lead（主 agent）：执行实现，持有合约权威
    - verifier：独立 context window，接收单元完成通知，运行不变式验证（只读）
    [T+]: - risk-guard：独立 context window，拦截高风险路径（只读）」
```

#### Phase 2: 每个 Implementation Unit 的执行流程

```
[T+] 模式 - Unit 开始前：
  1. SendMessage("risk-guard", "Unit {unit_id} 开始。描述：{desc}。文件：[files]")
  2. 等待 risk-guard 回复（最多 30 秒）：
     - 通过 → 继续执行该 Unit
     - 风险拦截 → 使用 AskUserQuestion 要求用户确认，用户确认后继续，拒绝后跳过该 Unit

执行前文件边界检查（主 agent 自检）：
  - 核对 Unit 的 Files 列表是否都在 allowed_files 内
  - 如有越界：暂停，上报，等待用户确认

Unit 执行完成后：
  1. SendMessage("verifier", "Unit {unit_id} 已完成。变更文件：[files]。请验证。")
  2. 等待 verifier 回复（最多 60 秒）：
     - PASS → 继续下一 Unit
     - FAIL → 读取失败详情 → 修复 → 重发：
       「Unit {unit_id} 已修复：{修复说明}。变更文件：[files]。请重新验证。」
     - 超时（60s 无回复）：
       「⚠️ Verifier 未响应，切换主 agent 同步验证模式」
       主 agent 直接运行 required_invariants，继续流程

并行 subagent 的文件边界约束（当 ce:work 派发多个并行 subagent 时）：
  - 合约主在派发前检查各 Unit 的 Files 列表是否互不重叠
  - 如有交集：将涉及共享文件的任务改为串行
  - 所有并行 subagent 完成后，verifier 额外运行一次全量集成验证

全部 Unit 完成后（全量集成验证）：
  SendMessage("verifier", "所有 Unit 完成。请运行全量集成验证（所有 required_invariants）。")
  等待最终 PASS
```

#### Phase 4: 收尾

```
TeamDelete(TEAM_NAME)
清理 .context/compound-engineering/ 中 team 相关状态文件（如有）
```

#### 消息协议（固定格式）

```
Lead → Verifier：
  「Unit {unit_id} 已完成。变更文件：[file1, file2, ...]。请验证。」
  「Unit {unit_id} 已修复：{修复说明}。变更文件：[files]。请重新验证。」
  「所有 Unit 完成。请运行全量集成验证。」

Verifier → Lead：
  「Unit {unit_id}: PASS. {可选说明}」
  「Unit {unit_id}: FAIL. 原因：{reason}. 命令输出：{output}」

Lead → Risk-Guard：
  「Unit {unit_id} 开始。描述：{desc}。文件：[file1, ...]」

Risk-Guard → Lead：
  「Unit {unit_id}: 风险卫通过。」
  「⚠️ Unit {unit_id}: 风险拦截。涉及高风险路径 [{keywords}]。需用户确认。」
```

#### 降级策略

```
若 TeamCreate 调用失败或平台不支持 Agent Teams：
  - 宣告：「⚠️ Agent Teams 不可用，降级为角色模拟模式（主 agent 顺序切换角色）」
  - 验证者逻辑：每 Unit 完成后，主 agent 直接运行 required_invariants
  - 其余流程不变（合约边界、风险卫关键词检测仍生效）

若 verifier teammate 意外停止（TeammateIdle hook 触发）：
  - 宣告：「⚠️ Verifier teammate 已停止，切换主 agent 验证模式」
  - 主 agent 直接运行 required_invariants 完成剩余验证
```

**[T]+[T] 的 Phase 3.5 Layer 3 全局确认**（补充单任务局部验证）：
- Layer 3 只核查跨任务维度的验收场景（不重复 team 验证者 Hook 已覆盖的单任务条目）
- 若发现跨任务组合破坏了不变式：进入标准 BLOCKED 检查点（见下方），不触发新一轮 team 验证者 Hook
- 并行 subagent 场景下，Layer 3 全局确认在所有 subagent 完成后额外运行一次全局不变式检查

#### BLOCKED 检查点（仅当 [T] 同时激活时）

当 Phase 3.5 验证失败达到 2 轮上限，ce:work 使用标准 AskUserQuestion 工具（team 模式下的提示文字包含团队上下文）：

> "⚠️ [T]+[T] 验证未通过（已重试 N 轮）
> 团队模式失败层：[层名] — [失败原因摘要]
> Layer 0 层内重试：[N] 次
>
> 1. 查看详细错误，执行者手动修复后重新运行验证（重置轮次）
> 2. 跳过验证，降级为标准模式继续 Phase 4（PR 描述标注验证未通过）
> 3. 停止，稍后处理"

选择说明：
- 选 1 → 执行者读取 `.context/compound-engineering/ce-work-verification.json` 的 layer 失败信息，修复后重置 verification_rounds，重跑 Phase 3.5
- 选 2 → 继续 Phase 4，在 PR/commit 描述中标注「⚠️ [T] 验证未通过，人工跳过」
- 选 3 → 结束，保留 `.context/compound-engineering/ce-work-verification.json` 供后续参考

### ce:review [T]（autofix 和 interactive 模式有效，report-only/headless 无效）

> **实现层次**：规则引擎，无需 Agent Teams（有意设计）。
> Patch Gate 是 deterministic whitelist check：对每条 finding 检查 allowed_files/forbidden_surfaces/max_files_per_patch/required_invariants，无需 agent 间通信，零额外 token。

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
| ce:work [T] 无合约 | 提示建议先运行 `/ce:plan [T]`；询问是否继续无合约模式（仅宣告角色，不检查边界） | ce:work 会实际修改代码，无合约执行风险较高，需用户知情后确认 |
| ce:review [T] 无合约 | 跳过 Patch Gate，记录警告："未找到 .team-contract.md，Patch Gate 已禁用" | Patch Gate 是审查加强层，跳过不影响代码修改安全性；中断审查流程对用户影响更大 |
| ce:plan [T] | 合约不适用于 plan 前阶段，正常执行合约生成 | — |

---

## 与现有 overlays 的关系

| 现有 Overlay | 与 team-mode 的关系 |
|-------------|-------------------|
| `review-contract` | [T] 模式下，review-contract 的 Tier 分类被 Patch Gate 消费（Blocking Tier → 强制 gated_auto） |
| `patch-approval` | patch-approval 使用隔离 git clone 生成 patch；team-mode 的 Patch Gate 在此之前执行白名单检查 |
| `ce-work-integration` | task-bundle 状态追踪与 team-mode 互补：bundle 追踪任务状态，team-mode 追踪边界合约 |
