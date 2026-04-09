---
title: "feat: Team Mode — 多代理协作稳定性框架"
type: feat
date: 2026-04-08
risk_score: 3
risk_level: low
risk_note: "主要风险：修改4个核心skill文件（ce-brainstorm/plan/work/review），参数解析逻辑错误可能影响现有[C][G][P]标志行为"
origin: docs/brainstorms/2026-04-08-team-mode-design-brainstorm.md
---

# feat: Team Mode — 多代理协作稳定性框架

## Overview

**Goal**: 为 `ce:brainstorm`/`ce:plan`/`ce:work`/`ce:review` 添加统一的 `[team]` 参数，通过合约白名单 + 单写者原则 + 验证者集成，在执行阶段前移拦截问题，从根本提升稳定性。  
**Tech Stack**: Markdown skill files, YAML frontmatter, `.team-contract.md` (新增), `skills-custom/team-mode/` (新增 overlay)  
**Architecture**: 新增 overlay skill 叠加在现有 ce:work/ce:review 之上，通过 `.team-contract.md` 文件在 plan → work → review 阶段间传递合约，review 的 autofix 路径增加 deterministic patch gate（规则引擎，非 agent）

---

## Problem Statement / Motivation

（见 brainstorm: `docs/brainstorms/2026-04-08-team-mode-design-brainstorm.md#根因分析`）

当前稳定性问题四个根因：
1. **无单写者原则** — 多个逻辑修改者可并发作用于代码
2. **无合约白名单** — autofix 不知道哪些文件不该碰
3. **验证滞后** — 问题在所有任务完成后才被 ce:review 发现，返工成本高
4. **patch 粒度太粗** — 一次 autofix 改多处，出错难以定位和回滚

Codex 读源码后确认：现有 `patch-approval` 和 `review-contract` overlay 方向正确，但"入口未接通、职责重复、虚拟字段无消费者"——**不是缺角色，是现有机制没有串联**。

---

## Proposed Solution

添加 `[team]` 参数，按阶段启用不同角色集。核心架构约束：**只有执行者可以写共享 checkout**，其他角色只读或在隔离 worktree 工作。

### 参数设计

```bash
# ce:work（核心）
/ce:work [team]            → 3角色：合约主 + 执行者 + 验证者（默认）
/ce:work [team:light]      → 2角色：执行者 + 验证者（快速小任务）
/ce:work [team:full]       → 4角色：全部（auth/payment/migration 等高风险）

# 其他阶段
/ce:brainstorm [team]      → 探索者 + 挑战者（结构化探索）
/ce:plan [team]            → 合约主 + 追溯审查 + 生成 .team-contract.md
/ce:review mode:autofix [team]  → 合约白名单门控（现有 autofix + patch gate）
```

### 角色定义（work 阶段）

| 中文名 | tmux短名 | 职责 | 生命周期 |
|--------|---------|------|---------|
| **合约主** | `合约` | 执行前写边界合约，全程持有合约权威 | 全程存活 |
| **执行者** | `执行` | **唯一可写共享代码的角色**，越界暂停上报 | 按任务运行 |
| **验证者** | `验证` | 每单元完成后跑集成验证，只读不写 | 事件驱动 |
| **风险卫** | `风险` | 拦截 auth/payment/migration 高风险路径 | 仅 full 模式 |

---

## Technical Approach

### Architecture

```
ce:plan [team]
    ↓ 生成 .team-contract.md (allowed_files, forbidden_surfaces, invariants)
    
ce:work [team]
    ↓ 加载 team-mode overlay skill
    ↓ 合约主确认合约
    ↓ 执行者执行（单写者原则）
    ↓ 验证者验证（每任务后）
    
ce:review mode:autofix [team]
    ↓ 加载 .team-contract.md
    ↓ Deterministic Patch Gate（规则引擎）
       ├ patch.files ⊄ allowed_files → downgrade safe_auto → gated_auto
       ├ patch.touches forbidden_surface → 拒绝
       └ patch.file_count > 1 → 拒绝（one-finding-one-patch 约束）
```

### 关键机制：Deterministic Patch Gate

这是规则引擎，不是 agent。在 Stage 5 合并/路由（routing normalization）步骤中执行：

```
if .team-contract.md exists AND mode:autofix AND [team]:
  for each finding with autofix_class: safe_auto:
    if any(patch_file not in allowed_files): downgrade to gated_auto
    if any(patch_file in forbidden_surfaces): reject (advisory)
    if patch_file_count > 1: downgrade to gated_auto (one-finding-one-patch)
```

### 合约文件格式：.team-contract.md

YAML frontmatter（选择 frontmatter 而非纯 Markdown 表格，因为便于程序化解析，参见 brainstorm 开放问题1）：

```markdown
---
team_mode: true
generated_by: ce:plan [team]
generated_at: 2026-04-08
plan_source: docs/plans/2026-04-08-feat-xxx-plan.md
allowed_files:
  - plugins/compound-engineering/skills-custom/team-mode/SKILL.md
  - plugins/compound-engineering/skills/ce-work/SKILL.md
forbidden_surfaces:
  - plugins/compound-engineering/.claude-plugin/plugin.json
  - CHANGELOG.md
required_invariants:
  - "所有 skill 修改必须通过 bash scripts/check-handoff.sh 验证"
  - "不得移除现有 argument-hint 中已有的 [C][G][P] 标志"
patch_gate_enabled: true
max_files_per_patch: 1
---

# Team Contract

## 背景
...（可选描述）
```

### 合约主的"持续存在"机制（解决 brainstorm 开放问题4）

合约主不是独立 subagent。它通过 `.team-contract.md` 文件持久化——这是它的"记忆"。在 ce:work 每个任务开始时，执行者读取合约文件确认边界；在任务结束时，合约文件不变（只有执行者变更代码）。这避免了 Claude Code 里 subagent 跨任务状态丢失的问题。

---

## Implementation Units

### Unit 1: 新建 `team-mode` overlay skill

**Goal**: 创建 `skills-custom/team-mode/SKILL.md`，定义所有角色、模式规则、激活时机

**Files**:
- `plugins/compound-engineering/skills-custom/team-mode/SKILL.md` (新建)
- `plugins/compound-engineering/skills-custom/team-mode/templates/team-contract.md.tpl` (新建)

**Approach**: 参照 `skills-custom/review-contract/SKILL.md` 的结构（126行）。包含：
1. YAML frontmatter（name, description, argument-hint）
2. 角色定义表（4角色 × 4维度）
3. 模式规则（[team]/[team:light]/[team:full]）
4. 合约文件格式规范
5. 各阶段激活方式说明
6. 单写者原则强制规则（"NEVER code sections"）

**Content outline for SKILL.md**:
```markdown
---
name: team-mode
description: Multi-agent team collaboration overlay...
argument-hint: "[team] | [team:light] | [team:full]"
---

# Team Mode Overlay

## Roles

| Role | tmux | Responsibility | Lifecycle |
|...

## Mode Variants

| Token | Roles | Best for |
| [team] | 合约主+执行者+验证者 | Default |
| [team:light] | 执行者+验证者 | Quick small tasks |
| [team:full] | All 4 | auth/payment/migration |

## Single Writer Principle (Iron Law)

ONLY 执行者 writes to shared checkout.
Other roles: read-only OR isolated worktree.

## .team-contract.md Format
[YAML spec...]

## Activation Points
[per-command activation descriptions]
```

**Content outline for template**:
```yaml
---
team_mode: true
generated_by: ce:plan [team]
generated_at: YYYY-MM-DD
plan_source: PLAN_PATH
allowed_files: []
forbidden_surfaces: []
required_invariants: []
patch_gate_enabled: true
max_files_per_patch: 1
---
```

**Verification**: Read both files exist; grep for "Single Writer" in SKILL.md; confirm template has all required YAML fields

**Execution note**: Write skill file first (Unit 1), then add token parsing to each command (Units 2-5) — they reference the skill

---

### Unit 2: ce:brainstorm — 添加 `[team]` 参数

**Goal**: 在 argument-hint 和参数解析区块加入 `[team]` token，激活探索者+挑战者角色对

**Files**:
- `plugins/compound-engineering/skills/ce-brainstorm/SKILL.md`

**Approach**: 
1. 修改 `argument-hint` 行（第4行）：追加 `[team=结构化探索]`
2. 在现有 `[P][C][G]` 解析区块之后，添加 `[team]` 解析段：
   - 检测 `[team]` token → `TEAM_MODE=true`，启用探索者+挑战者角色对
   - 区分于 `[P]`（Party Mode 是14人自由讨论，[team] 是2人结构化探索，有明确收敛条件）

**Edit location**: After the `[G]` detection block in the argument parsing section

**What to add**:
```markdown
检测 [team] 标志：
  如果包含 [team]：
    → TEAM_MODE = true
    → 角色：探索者（聚焦可行性）+ 挑战者（质疑假设）
    → 退出条件：达成「方向共识」或 [E] 退出
    → 区分于 [P]：[P] 是发散（14人自由讨论），[team] 是收敛（2人结构化）
    → 两者可组合：[P][team] = Party Mode 之后接结构化验证轮
```

**[P][team] 组合机制**（解决 brainstorm 开放问题3）：
- 先 [P] 发散 → 结束后，[team] 对结论进行结构化挑战验证
- 执行顺序：party-mode → 退出 → team 挑战轮（探索者+挑战者）

**Verification**: Run `grep -n "\[team\]" plugins/compound-engineering/skills/ce-brainstorm/SKILL.md` 返回至少2行

---

### Unit 3: ce:plan — 添加 `[team]` 参数 + 合约生成 Phase

**Goal**: 添加 token 解析；在 Phase 4（Write the Plan）之后新增 Phase 4.5：合约主生成 `.team-contract.md`

**Files**:
- `plugins/compound-engineering/skills/ce-plan/SKILL.md`

**Approach**:

**Part A — argument-hint 修改（第2行）**:
```yaml
argument-hint: "[optional: feature description, requirements doc path, plan path to deepen, or any task to plan] [team=合约主+追溯审+生成合约]"
```

**Part B — 新增 Phase 4.5（在 Phase 4 Write the Plan 之后插入）**:

```markdown
### Phase 4.5: 合约生成（仅当 [team] 标志存在时）

**触发条件**: `$ARGUMENTS` 包含 `[team]`

**合约主角色激活**:
合约主读取刚生成的计划文件，提取：
1. `allowed_files`：从所有 Implementation Units 的 Files 字段收集
2. `forbidden_surfaces`：从计划描述中识别高风险文件（db/schema.rb、认证相关、支付相关）
3. `required_invariants`：从计划的 Acceptance Criteria 转换为可检查的不变式

**生成文件**: `.team-contract.md`（repo 根目录，使用 `skills-custom/team-mode/templates/team-contract.md.tpl`）

**追溯审查角色激活**:
追溯审查者检查计划的技术决策是否与 docs/solutions/ 的历史经验矛盾，输出：
- 历史中有无类似失败案例？
- 有无已知 gotcha 未在计划中提及？

**输出**: `.team-contract.md` 写入根目录；追溯审查结果追加到 plan 的 Open Questions 节
```

**Verification**: After editing, run `grep -n "Phase 4.5\|team-contract\|\[team\]" plugins/compound-engineering/skills/ce-plan/SKILL.md` 返回 ≥ 3 行

---

### Unit 4: ce:work — 添加 `[team]` 模式执行逻辑

**Goal**: 在 Phase 0 (Input Triage) 之前插入 Phase -1（Team Mode 初始化），并在 Phase 2 执行循环中添加验证者 hook

**Files**:
- `plugins/compound-engineering/skills/ce-work/SKILL.md`

**Approach**:

**Part A — argument-hint 修改（第4行）**:
```yaml
argument-hint: "[Plan doc path or description of work. Blank to auto use latest plan doc] [team=3角色协作] [team:light=2角色] [team:full=4角色含风险卫]"
```

**Part B — 在 Input Triage (Phase 0) 之前插入**:

```markdown
### Phase -1: Team Mode 初始化（仅当 [team]、[team:light]、[team:full] 时）

**检测** `$ARGUMENTS` 中的 team token：
- `[team]` → TEAM_VARIANT = default（合约主+执行者+验证者）
- `[team:light]` → TEAM_VARIANT = light（执行者+验证者）
- `[team:full]` → TEAM_VARIANT = full（全4角色）

**加载合约**:
1. 检查 `.team-contract.md` 是否存在
2. 如存在：读取 allowed_files、forbidden_surfaces、required_invariants
3. 如不存在：提示 "未找到 .team-contract.md，建议先运行 `/ce:plan [team]` 生成合约。是否继续（无合约模式）？"

**宣告角色**:
```
🤝 Team Mode 已激活 [variant]
  合约主：持有 .team-contract.md，监督边界合约（通过文件持久化，非独立subagent）
  执行者：唯一可写代码的角色（单写者原则）
  验证者：每任务后运行集成测试（只读）
  [风险卫：仅 full 模式，拦截 auth/payment/migration 路径]
```

**单写者原则（Iron Law）**:
- 执行者是唯一写代码的实体
- 在每个 Implementation Unit 开始前，检查该单元的 Files 字段：
  - 如果任何文件不在 allowed_files → 暂停，报告越界，等待用户确认
  - 如果任何文件在 forbidden_surfaces → 拒绝执行，要求修改计划
```

**Part C — 在 Phase 2 执行循环（每任务完成后）插入验证者 hook**:

在 "After completing a cluster of related implementation units (or every 2-3 units)" 段落（约第252行）之后，在 [team] 模式下插入：

```markdown
**[team] 验证者 Hook（每 Implementation Unit 完成后）**:

如果 TEAM_VARIANT ≠ off:
  验证者（只读角色）执行：
  1. 运行该单元的 Verification 步骤中指定的测试命令
  2. 检查 required_invariants 中的每条不变式
  3. 如果测试失败或不变式违反：
     - 立即报告（不继续执行下一单元）
     - 将失败信息写入 `.team-contract.md` 的 `last_verification_failure` 字段
  4. 如果全部通过：继续下一单元

注意：验证者不修改任何代码。如需修复，执行者负责修复（单写者原则）。
```

**[team:full] 风险卫激活条件**:

```markdown
**[team:full] 风险卫 Hook（在执行者开始每个单元之前）**:

如果 TEAM_VARIANT == full:
  检查该单元的 Files 和 Approach 是否包含高风险模式：
  - 认证/授权相关（auth、session、permission、role）
  - 支付相关（payment、billing、stripe、invoice）
  - 数据迁移（migration、schema、db/migrate）
  
  如果命中：
    风险卫执行只读分析：
    1. 识别变更的安全影响
    2. 检查 forbidden_surfaces 中的相关条目
    3. 生成简短风险摘要（3-5条）
    4. 使用 AskUserQuestion 确认："风险卫发现高风险路径。[摘要] 确认继续？"
    5. 用户确认后，执行者继续
```

**Verification**: `grep -n "Phase -1\|Team Mode\|TEAM_VARIANT\|单写者\|验证者" plugins/compound-engineering/skills/ce-work/SKILL.md` 返回 ≥ 5 行

---

### Unit 5: ce:review — 添加 `[team]` Patch Gate

**Goal**: 添加 token 解析；在 Stage 5 路由规范化步骤中插入 Deterministic Patch Gate 逻辑

**Files**:
- `plugins/compound-engineering/skills/ce-review/SKILL.md`

**Approach**:

**Part A — argument-hint 修改（第4行）**:
```yaml
argument-hint: "[PR# 或留空=当前分支] [mode:autofix|report-only|headless] [plan:路径] [base:ref] [C=Codex审核] [G=Gemini审核] [team=合约白名单门控]"
```

**Part B — Token 解析表（约第21行，追加一行）**:

在现有 token 表中追加：
```markdown
| `[team]` | TEAM_GATE_ENABLED = true | 加载 .team-contract.md，在 Stage 5 路由规范化时执行 Patch Gate |
```

**Part C — Stage 5 路由规范化（约第430行）末尾插入**:

在 "Normalize routing" 步骤之后追加：

```markdown
**Deterministic Patch Gate（仅当 `[team]` flag 存在 AND `mode:autofix`）**:

如果 TEAM_GATE_ENABLED AND mode == autofix:
  1. 加载 `.team-contract.md`（如不存在，跳过此步骤，记录警告）
  2. 读取 allowed_files、forbidden_surfaces、max_files_per_patch
  3. 对 autofix_class == safe_auto 的每条 finding：
     
     a. **文件范围检查**:
        if ANY(patch_file NOT IN allowed_files):
          downgrade: safe_auto → gated_auto
          note: "合约白名单：{patch_file} 不在 allowed_files 中"
     
     b. **禁止区域检查**:
        if ANY(patch_file IN forbidden_surfaces):
          downgrade: safe_auto → advisory (reject from fixer queue)
          note: "合约白名单：{patch_file} 在 forbidden_surfaces 中，拒绝自动修复"
     
     c. **One-finding-one-patch 约束**:
        if len(affected_files) > max_files_per_patch (default: 1):
          downgrade: safe_auto → gated_auto
          note: "单补丁约束：此 finding 涉及 {N} 个文件，超过 max_files_per_patch={max}"
     
     d. **不变式验证要求**:
        if required_invariants 非空:
          确保 fixer subagent 在每次 patch 应用后验证所有不变式
          如验证失败：回滚此 patch，标记为 gated_auto

此 Gate 是规则引擎（deterministic），不依赖 agent 判断，不消耗额外 token。
```

**Verification**: 
```bash
grep -n "\[team\]\|TEAM_GATE\|Patch Gate\|forbidden_surface\|one-finding" plugins/compound-engineering/skills/ce-review/SKILL.md
```
返回 ≥ 5 行

---

### Unit 6: 串联 review-contract overlay

**Goal**: 在 `review-contract` skill 中添加"[team] autofix 集成"说明，解决"虚拟字段无消费者"问题

**Files**:
- `plugins/compound-engineering/skills-custom/review-contract/SKILL.md`

**Approach**: 在文件末尾的 "Unresolved Items" 或结尾追加：

```markdown
## Integration with [team] Mode

当 `ce:review` 使用 `[team]` flag 时，本 skill 的 Tier 分类直接影响 Patch Gate 行为：

| Tier | 对应 Patch Gate 行为 |
|------|---------------------|
| Blocking (security-reviewer, data-migrations-reviewer) | 所有 findings 强制 gated_auto，不允许 safe_auto |
| Analytical (architecture-strategist, performance-reviewer) | 维持原 autofix_class，但触发不变式验证 |
| Advisory (code-simplicity-reviewer) | 维持原 autofix_class，不触发额外验证 |

**激活方式**: `review-contract` 在 `[team]` 模式下由 Stage 5 Patch Gate 自动消费。
用户不再需要手动加载此 skill — 它被 Patch Gate 的 Tier 逻辑内联引用。
```

**Verification**: `grep -n "team\|Patch Gate\|Integration" plugins/compound-engineering/skills-custom/review-contract/SKILL.md` 返回 ≥ 3 行

---

### Unit 7: 文档更新

**Goal**: 更新 CLAUDE.md 和 CHANGELOG.md，升级版本号

**Files**:
- `plugins/compound-engineering/CLAUDE.md`
- `CHANGELOG.md`
- `plugins/compound-engineering/.claude-plugin/plugin.json` (version: 2.45.7 → 2.45.8)

**CLAUDE.md 修改**（在主工作流 Skills 表格中追加 [team] 列）:

在 `| `/ce:brainstorm` | 探索需求和方案 \`[P][C][G]\` |` 行修改为：
```
| `/ce:brainstorm` | 探索需求和方案 `[P][C][G][team]` |
| `/ce:plan` | 创建实施计划 `[team]` |
| `/ce:work` | 执行工作计划 `[team][team:light][team:full]` |
| `/ce:review` | 代码审查 `[mode:autofix] [C][G][team]` |
```

并新增说明节：
```markdown
### `[team]` 参数说明

多代理协作稳定性框架。核心机制：合约白名单 + 单写者原则 + 事件驱动验证。

| 参数 | 阶段 | 效果 |
|------|------|------|
| `[team]` | ce:brainstorm | 探索者 + 挑战者角色对 |
| `[team]` | ce:plan | 合约主 + 追溯审查 + 生成 .team-contract.md |
| `[team]` | ce:work | 3角色默认（合约主+执行者+验证者） |
| `[team:light]` | ce:work | 2角色（执行者+验证者） |
| `[team:full]` | ce:work | 4角色（加风险卫，适合 auth/payment/migration） |
| `[team]` | ce:review | autofix 路径增加 Deterministic Patch Gate |
```

**CHANGELOG.md 追加**（在 Unreleased 或顶部插入）:
```markdown
## [2.45.8] - 2026-04-08

### Added
- `[team]` 参数：多代理协作稳定性框架，适用于 ce:brainstorm/plan/work/review
  - 单写者原则：执行者是唯一可写代码的角色
  - 合约白名单：ce:plan [team] 自动生成 .team-contract.md
  - 验证者集成：每任务完成后自动运行验证（ce:work）
  - Deterministic Patch Gate：规则引擎门控 autofix 边界（ce:review）
  - 三个变体：[team]（3角色）/[team:light]（2角色）/[team:full]（4角色含风险卫）
- `skills-custom/team-mode/SKILL.md`：新 overlay skill，定义角色和合约规范
- `.team-contract.md` 格式：YAML frontmatter，plan → work → review 阶段传递合约
- review-contract overlay 正式集成到 [team] autofix 路径（Tier 分类现在有消费者）

### Fixed
- review-contract skill 虚拟字段（conclusion_type, Tier 分类）现在被 Patch Gate 消费
```

**版本升级命令**:
```bash
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch
```

**Verification**: 
```bash
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
bash scripts/check-handoff.sh
```

---

## Acceptance Criteria

### Functional Requirements

- [x] `[team]`、`[team:light]`、`[team:full]` token 在所有 4 个命令（brainstorm/plan/work/review）的 argument-hint 中有文档
- [x] `skills-custom/team-mode/SKILL.md` 存在，包含4角色定义、3模式规则、单写者铁律
- [x] `team-contract.md.tpl` 模板存在，包含所有必要 YAML 字段
- [x] `ce:plan [team]` 包含合约生成 Phase 4.5
- [x] `ce:work [team]` 包含 Phase -1 初始化（合约加载、角色宣告、越界检查）
- [x] `ce:work [team]` 包含验证者 hook（每任务后）
- [x] `ce:work [team:full]` 包含风险卫激活逻辑
- [x] `ce:review [team]` 包含 Deterministic Patch Gate（3条规则：文件范围/禁止区域/单补丁约束）
- [x] `review-contract` 的 Tier 分类与 Patch Gate 集成说明已写入
- [x] CHANGELOG.md 已更新，版本已升至 2.45.8

### Non-Functional Requirements

- [x] Patch Gate 是规则引擎，不启动额外 agent，不消耗额外 token
- [x] `[team]` 与 `[C]`、`[G]`、`[P]`、`mode:autofix` 等现有 token 不冲突
- [x] 无 `.team-contract.md` 时，所有命令降级优雅（给出提示，不崩溃）
- [x] `bash scripts/check-handoff.sh` 通过（现有 Handoff 协议不受影响）
- [x] `powershell scripts/check-versions.ps1` 通过

---

## Open Questions → Resolved

| 原问题 | 决策 | 来源 |
|--------|------|------|
| `.team-contract.md` 格式：YAML frontmatter vs 纯 Markdown 表格？ | **YAML frontmatter**（便于规则引擎程序化解析，避免解析 Markdown 表格的歧义） | brainstorm 开放问题1 |
| 合约主的"持续存在"机制？ | **文件持久化**（`.team-contract.md` 是合约主的"记忆"，而非独立 subagent） | brainstorm 开放问题4 |
| `[P][team]` 可以组合吗？ | **可以**：先 [P] 发散，再 [team] 结构化挑战验证（顺序执行） | brainstorm 开放问题3 |
| tmux 集成？ | **不在本次范围**：tmux 短名是可视化层，当前实现以文本宣告为准。后续可独立添加 tmux 集成 overlay | brainstorm 开放问题2 |

---

## Implementation Sequence

```
Unit 1 (team-mode skill)      → 必须最先完成，其他 Unit 引用它
    ↓
Unit 2 (ce:brainstorm)        ─┐
Unit 3 (ce:plan)               ├ 可并行执行（独立文件）
Unit 4 (ce:work)               │
Unit 5 (ce:review)             │
Unit 6 (review-contract)      ─┘
    ↓
Unit 7 (文档 + 版本)           → 必须最后完成
```

---

## Risk Assessment Detail

| 维度 | 分 | 说明 |
|------|----|------|
| 安全/隐私 | 0 | Markdown skill 文件，无敏感数据处理 |
| 可逆性 | 1 | 修改现有 skill 文件（部分可逆，git revert 可回滚） |
| 影响范围 | 0 | 本地插件开发，不影响生产环境 |
| 变更规模 | 2 | 修改/创建约 10 个文件（4 核心 skill + 2 custom + 2 模板 + 2 文档） |
| 外部依赖 | 0 | 无第三方 API，纯 Markdown |
| **总计** | **3** | **🟢 低风险** |

**主要风险**: 修改 4 个核心 skill 文件时，参数解析逻辑错误可能影响现有 `[C][G][P]` 标志行为。**缓解**: 每个 Unit 在修改前检查现有解析逻辑，只追加不替换；Unit 7 验证 check-handoff.sh 通过。

---

## References

- **Origin brainstorm**: `docs/brainstorms/2026-04-08-team-mode-design-brainstorm.md`
- **Existing patterns to follow**:
  - `plugins/compound-engineering/skills/ce-review/SKILL.md:21` — token 解析表格模式
  - `plugins/compound-engineering/skills-custom/review-contract/SKILL.md` — overlay skill 结构
  - `plugins/compound-engineering/skills-custom/patch-approval/SKILL.md` — 隔离 worktree patch 模式
  - `plugins/compound-engineering/skills-custom/task-bundle/SKILL.md` — 多文件状态持久化模式
- **Institutional learnings**:
  - `docs/solutions/workflow/todo-status-lifecycle.md` — 状态门控边界强制
  - `docs/solutions/skill-design/pass-paths-not-content-to-subagents-2026-03-26.md` — 子代理编排效率
  - `docs/solutions/integration-issues/superpowers-architecture-deep-dive-2026-03-11.md` — Markdown 强制执行机制
