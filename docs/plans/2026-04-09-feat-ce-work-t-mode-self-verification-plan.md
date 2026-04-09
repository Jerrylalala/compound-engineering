---
title: "feat: ce:work [T] 四层自验证模式"
type: feat
status: completed
date: 2026-04-09
origin: docs/brainstorms/2026-04-09-ce-work-t-mode-self-verification-brainstorm.md
risk_score: 2
risk_level: low
risk_note: "Markdown skill 文件修改，完全可逆；影响范围为本地插件工作流，无外部依赖"
plan_protocol: executable_checkboxes_v1
---

# feat: ce:work [T] 四层自验证模式

## Overview

**Goal**: 为 `ce:work` 增加可选 `[T]` 参数，在代码实现后自动执行四层验证（CLI/API/Browser/验收），将"完成"的定义从"代码写完"改为"通过验证"。

**Tech Stack**: Markdown skill files, Bash (agent-browser CLI), Playwright MCP tools（`mcp__playwright__*`）

**Architecture**: 在 ce:work 现有 Phase 体系（-1, 0, 1, 2, 3, 4）中插入 Phase 3.5；Phase -1 扩展检测 [T] 和 [PW] 标志（`[T]`=agent-browser，`[T][PW]`=Playwright MCP）；ce:plan 模板增加"验收场景"章节供 Layer 3 读取。

---

## Problem Frame

ce:work 当前将"任务完成"定义为"代码写完"，所有 bug 在 ce:review 阶段（或 Codex 审查）才被发现。2026-04-09 的真实案例：5 个功能扩展执行完毕后，Codex 审查发现 4 个 P1 问题（其中 3 个本可在执行阶段通过"读回验证"发现）。

参考 SamuelQZQ/auto-coding-agent-demo（775⭐）的 `task.json` passes 状态机模式：完成 = 可重复命令通过，而非 AI 自报。

（see origin: docs/brainstorms/2026-04-09-ce-work-t-mode-self-verification-brainstorm.md）

---

## Requirements Trace

- R1. 新增 `[T]` 可选参数，不强制，不破坏现有 ce:work 行为
- R2. 实现四层验证架构（Layer 0 CLI / Layer 1 API-DB / Layer 2 Browser / Layer 3 验收）
- R3. Layer 2 默认使用 agent-browser，可升级为 Playwright MCP
- R4. 验证状态使用文件系统（.ce-work-verification.json）记录，跨 session 存活
- R5. 最多重试 2 轮，失败 → BLOCKED → AskUserQuestion
- R6. ce:plan 模板增加"验收场景"章节，[T] 模式读取作为 Layer 3 输入
- R7. [T] + [team] 组合时 Layer 3 与 team 验证者 Hook 合并

---

## Scope Boundaries

- 不修改 Phase 0-3 的现有逻辑（[T] 是纯增量）
- 不新建文件（agent-browser skill 和 Playwright MCP 已存在）
- ce:work 本体只修改 Phase -1 和新增 Phase 3.5；Phase 4 不变
- 不适用于插件本身的 Markdown 生产（仅 Layer 0 + Layer 3 有意义，浏览器验证不适用）

---

## Context & Research

### Relevant Code and Patterns

- `plugins/compound-engineering/skills/ce-work/SKILL.md:4` — argument-hint，当前格式：`[team=...] [team:full=...] [R=...]`；新增 `[T=...]`
- `plugins/compound-engineering/skills/ce-work/SKILL.md:21-28` — Phase -1 当前仅检测 [team]；需扩展检测 [T]
- `plugins/compound-engineering/skills/ce-work/SKILL.md:331-376` — Phase 3 Quality Check 末尾；Phase 3.5 插入此后
- `plugins/compound-engineering/skills/ce-plan/SKILL.md:430-554` — Core Plan Template（Phase 4.2）；需添加验收场景模板段
- `plugins/compound-engineering/skills/agent-browser/SKILL.md` — agent-browser 完整 CLI 文档（open/snapshot/click/fill/screenshot）
- `plugins/compound-engineering/CLAUDE.md:196-209` — `[team]` 参数说明表格；需同步添加 [T] 行

### Institutional Learnings

- 无直接相关 `docs/solutions/` 案例（此为新增能力，非 bug 修复）
- 参考现有 [team] 参数实现作为 [T] 的对称模式

---

## Key Technical Decisions

（均见 brainstorm 的 8 条决策）

- **[T] 可选非强制**（决策 1）：避免对纯文档任务产生无效 token 消耗
- **四层架构**（决策 2）：Layer 0（始终）→ Layer 1（后端条件）→ Layer 2（前端条件）→ Layer 3（始终）
- **工具选择显式参数化**（决策 3 更新）：`[T]` = agent-browser（低 token 默认），`[T][PW]` = Playwright MCP（显式升级）。**不做关键词自动判断**——用户最清楚场景需求，避免意外 token 暴增
- **文件系统状态机**（决策 4）：`.ce-work-verification.json` 跨 session 存活，不依赖内存
- **Layer 触发判断**（决策 7）：关键词 + 文件扩展名 + 路径模式判断是否运行 Layer 2；但 Layer 2 的**工具**由 [PW] 参数决定
- **[T]+[team] 合并**（决策 8）：Layer 3 reviewer = team 验证者 Hook，不重复执行

---

## Open Questions

### Resolved During Planning

- 验收场景是否强制：有 [T] 时 Layer 3 警告（不阻断），宽松核查模式兜底
- BLOCKED 与 team 协调：BLOCKED 时若在 [team] 模式，触发 team 人工检查点而非单独问
- dev server 不存在时：Layer 2 跳过 + 警告，不阻断整体

### Deferred to Implementation

- agent-browser 30 秒超时的具体实现方式（依赖 Bash timeout 包裹）
- `.ce-work-verification.json` 保留策略（默认保留，`.gitignore` 忽略，不自动清理）
- Layer 2 升级到 Playwright MCP 的具体触发判断（实现时参考验收场景中的"Layer"列）

---

## High-Level Technical Design

> *此图展示 [T] 模式的决策流，为方向性指导，不是执行代码。*

```
ce:work [T] 执行流程

Phase -1: 检测参数
  $ARGUMENTS 含 [T] → T_MODE_ENABLED=true → strip [T]
  $ARGUMENTS 含 [team] → team-mode 初始化（现有逻辑）
         ↓
Phase 0-3: 正常执行（不变）
         ↓
Phase 3.5: 四层自验证（仅当 T_MODE_ENABLED=true）
  ┌─ 3.5.0: 初始化 .ce-work-verification.json ─────────────┐
  │                                                         │
  │  3.5.1: Layer 触发判断                                  │
  │    描述/文件含前端信号 → Layer 2                         │
  │    描述/文件含后端信号 → Layer 1                         │
  │    描述含 Markdown/SKILL → 跳过 L1/L2                  │
  │    始终 → Layer 0 + Layer 3                             │
  │                                                         │
  │  3.5.2: 验证循环（max 2 轮）                            │
  │    L0 CLI  → build/test exit code = 0?                 │
  │    L1 API  → curl/DB 响应验证（条件）                   │
  │    L2 UI   → agent-browser（默认）或 Playwright MCP    │
  │    L3 验收 → 独立 reviewer 对照验收场景                 │
  │    任意失败 → 修复 → 重试（同轮次）                     │
  │                                                         │
  │  3.5.3: 结果处理                                        │
  │    全通过 → passes:true → Phase 4                       │
  │    第2轮仍失败 → BLOCKED → AskUserQuestion             │
  └─────────────────────────────────────────────────────────┘
         ↓
Phase 4: Ship It（不变）
```

---

## 验收场景（[T] 模式使用）

> 此章节示例供实现者参考，验证 Phase 3.5 的行为

| # | 场景 | 操作步骤 | 期望结果 | 层级 |
|---|------|----------|----------|------|
| 1 | [T] 参数被识别 | ce:work [T] plan.md | Phase -1 宣告「自验证模式已启用」，不影响 Phase 0-3 | Layer 3 |
| 2 | Layer 0 成功 | 项目含 npm run build | exit code = 0，layers.layer0=pass | Layer 0 |
| 3 | Layer 0 失败触发修复 | build 报错 | 自动修复后重试，第2轮通过 | Layer 0 |
| 4 | 无 [T] 参数 | ce:work plan.md | Phase 3.5 不触发，原有流程不变 | Layer 3 |
| 5 | Markdown 任务跳过 L1/L2 | 任务描述含「SKILL」 | Layer 1/2 = skip，仅 L0+L3 | Layer 3 |
| 6 | 2轮失败 BLOCKED | 修复2次仍失败 | AskUserQuestion 弹出选项 | Layer 3 |
| 7 | 无验收场景时宽松核查 | 计划无「验收场景」章节 | Layer 3 发出警告，继续核查 | Layer 3 |

---

## Implementation Units

- [x] **Unit 1: 更新 argument-hint + 扩展 Phase -1 参数检测**

**Goal:** 让 ce:work 识别 [T] 标志，设置 T_MODE_ENABLED 状态

**Requirements:** R1

**Dependencies:** 无

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-work/SKILL.md`

**Approach:**

*argument-hint（第 4 行）末尾追加：*
```
[T=四层自验证:CLI+API/DB+浏览器+验收;完成=通过验证而非写完代码] [PW=Playwright MCP浏览器验证,仅在[T]时生效;默认[T]使用agent-browser]
```

*Phase -1 重构（第 21-28 行区域）*——将标题改为通用参数检测，先检 [T]/[PW] 再检 [team]：

```markdown
### Phase -1: 参数检测与模式初始化

**[T] 自验证标志检测**（独立执行）：
- 如果 `$ARGUMENTS` 包含 `[T]` 或 `[t]`：
  - 设置 T_MODE_ENABLED = true
  - 从参数中移除 `[T]`
  - 宣告：「✅ [T] 自验证模式已启用——执行完成后将运行四层验证（Phase 3.5）」
- 否则：T_MODE_ENABLED = false（Phase 3.5 不触发）

**[PW] Playwright 标志检测**（仅在 T_MODE_ENABLED=true 时有意义）：
- 如果 `$ARGUMENTS` 包含 `[PW]` 或 `[pw]`：
  - 设置 PW_MODE_ENABLED = true
  - 从参数中移除 `[PW]`
  - 宣告：「✅ [PW] Playwright MCP 模式已启用——Layer 2 将使用 Playwright MCP（高精度浏览器验证）」
- 否则：PW_MODE_ENABLED = false（Layer 2 使用 agent-browser）

**[team] / [team:full] 检测**（仅当包含时）：
Strip the team token from arguments before passing to Phase 0.
Load the `team-mode` skill for the complete initialization sequence: token detection, contract loading, role announcement, single-writer law, verifier hooks, and 风险卫 logic.
```

**Patterns to follow:** 现有 [team] 参数的检测模式（strip + 设置状态 + 宣告）

**Test scenarios:**
- Happy path: `[T]` 在参数中 → T_MODE_ENABLED=true，PW_MODE_ENABLED=false，宣告正确
- Happy path: `[T][PW]` → T_MODE_ENABLED=true，PW_MODE_ENABLED=true，两个宣告均出现
- Happy path: `[T][team]` → 三个状态均设置
- Edge case: 无 [T] → T_MODE_ENABLED=false，Phase 3.5 不触发，[PW] 无效
- Edge case: `[t][pw]`（小写）→ 同样识别
- Edge case: 仅 `[PW]` 无 `[T]` → PW_MODE_ENABLED 设置但 Phase 3.5 不触发（[PW] 无意义）

**Verification:**
- 读回修改后的 SKILL.md，确认 argument-hint 含 `[T=四层自验证...]`
- 确认 Phase -1 区域包含 T_MODE_ENABLED 检测逻辑
- 确认 [team] 逻辑完整保留

---

- [x] **Unit 2: 新增 Phase 3.5 四层验证主体**

**Goal:** 实现四层验证闭环（L0 CLI / L1 API-DB / L2 Browser / L3 验收）

**Requirements:** R2, R3, R4, R5, R7

**Dependencies:** Unit 1

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-work/SKILL.md`

**Approach:**

在 Phase 3 末尾（"4. Prepare Operational Validation Plan" 之后）、Phase 4 标题之前，插入完整的 Phase 3.5 节。

Phase 3.5 内容结构如下（完整内容写入 SKILL.md）：

```markdown
### Phase 3.5: 四层自验证（仅当 `[T]` 时）

**触发条件**：T_MODE_ENABLED = true（在 Phase -1 中设置）

---

#### 3.5.0 初始化验证状态

创建 `.ce-work-verification.json`（项目根目录，已在 .gitignore）：

```json
{
  "task_id": "<任务描述前20字>",
  "description": "<完整任务描述>",
  "verification_rounds": 0,
  "layers": {
    "layer0": "pending",
    "layer1": "pending",
    "layer2": "pending",
    "layer3": "pending"
  },
  "passes": false
}
```

#### 3.5.1 Layer 触发判断

扫描当前任务描述 + 已变更文件列表，判断激活层：

| 触发信号 | 激活层 | 判断依据 |
|----------|--------|----------|
| 描述含「前端/UI/组件/页面/样式/交互」或变更含 `.tsx/.vue/.html/.css` | Layer 2 | 关键词 + 扩展名 |
| 描述含「API/接口/数据库/路由/endpoint/migration」或变更含 `routes/controllers/models/migrations` | Layer 1 | 关键词 + 路径 |
| 描述含「Markdown/文档/提示词/SKILL」| 跳过 Layer 1/2，仅 Layer 0 + Layer 3 | 关键词 |
| 项目 CLAUDE.md 含构建/测试命令 | Layer 0（始终激活） | — |

不确定时：激活 Layer 0 + Layer 3，Layer 1/2 使用 AskUserQuestion 询问用户确认。

#### 3.5.2 验证循环（最多 2 轮）

当 `passes: false` 且 `verification_rounds < 2`，执行以下四层：

---

**Layer 0：CLI 静态检查**（始终执行）

1. 读取项目 CLAUDE.md，提取构建/测试命令（如 `npm run build`、`pytest`、`cargo test`、`bash scripts/check-versions.ps1`）
2. 执行命令，捕获 exit code + stderr
3. exit code = 0 → 更新 `layers.layer0 = "pass"`
4. exit code ≠ 0 → 分析错误 → 修复代码/配置 → 重试 Layer 0（计入 verification_rounds）

---

**Layer 1：API/DB 验证**（条件执行）

*如未触发*：`layers.layer1 = "skip"`

*如触发*：
1. 读取计划验收场景中标注「Layer 1」的行
2. 执行对应的 curl 请求或 DB CLI 查询
3. 验证响应码 + 返回体结构 + 数据库状态
4. 成功 → `layers.layer1 = "pass"`；失败 → 修复 → 重试

---

**Layer 2：浏览器 UI 验证**（条件执行）

*如未触发*：`layers.layer2 = "skip"`

*如 dev server 未运行*：尝试启动；若失败则跳过 Layer 2，记录警告 "⚠️ dev server 未运行，Layer 2 跳过"

**工具选择（由 Phase -1 中的 PW_MODE_ENABLED 决定，用户显式控制，不自动切换）**：

*PW_MODE_ENABLED = false（默认 `[T]`，使用 agent-browser，token 低 30-50 倍）*：

```bash
Skill("agent-browser")                               # 加载 agent-browser skill
agent-browser open <dev-server-url>                  # 从 CLAUDE.md 或计划获取 URL
agent-browser snapshot -i --json                     # 获取可交互元素（带 ref）
agent-browser click @e<N>                            # 根据验收场景执行操作
agent-browser screenshot verification-$(date +%s).png  # 捕获视觉证据
```

*PW_MODE_ENABLED = true（用户显式传入 `[PW]`，使用 Playwright MCP）*——适用于网络拦截、JS执行、拖拽、文件上传：
- `mcp__playwright__browser_navigate` + `mcp__playwright__browser_snapshot`
- `mcp__playwright__browser_console_messages`（捕获 console 错误）
- `mcp__playwright__browser_network_requests`（拦截 API 调用）
- `mcp__playwright__browser_evaluate`（执行 JS 断言）

**铁律：不基于关键词自动升级到 Playwright MCP。用户传 [PW] 才用。**

成功 → `layers.layer2 = "pass"`；失败 → 修复 → 重试

---

**Layer 3：验收确认**（始终执行——独立 reviewer 视角）

> 「不信任实现者报告」原则（Superpowers spec-reviewer 原则）：独立读取文件，不依赖执行阶段的自我声明。

1. 读取计划文件中的「验收场景」章节
2. **若无验收场景章节**：输出警告 "⚠️ 计划中无验收场景，切换宽松核查模式"，转为对照任务需求逐条检查已修改文件
3. 逐条读取所有变更文件（使用 Read 工具，不信任内存），对照验收场景核查：
   - 功能是否实现？（检查代码/Markdown 逻辑）
   - 是否遗漏边界条件？
   - 与验收场景逐条比对
4. 发现未达标项 → 列出 → 修复 → 重试 Layer 3

**[T] + [team] 组合时**：
- Layer 3 reviewer = team-mode 验证者 Hook（角色复用，不重复执行）
- BLOCKED 状态触发 team-mode 人工检查点

---

#### 3.5.3 更新状态并处理结果

每层执行后更新 `.ce-work-verification.json`；`verification_rounds` 每轮+1。

**全部激活层通过（passes: true）**：

```json
{
  "verification_rounds": 1,
  "layers": { "layer0": "pass", "layer1": "skip", "layer2": "pass", "layer3": "pass" },
  "passes": true
}
```

展示验证摘要：
```
✅ [T] 验证通过（第 N 轮）
  Layer 0: pass  ✅
  Layer 1: skip  —
  Layer 2: pass  ✅ (截图: verification-<ts>.png)
  Layer 3: pass  ✅
```

继续 **Phase 4（Ship It）**。

**第 2 轮结束仍有层失败（BLOCKED）**：

使用 **AskUserQuestion** 工具询问：
> "⚠️ [T] 验证未通过（已重试 2 轮）
> 失败层：[层名] — [失败原因摘要]
> 
> 1. 查看详细错误，手动修复后继续验证
> 2. 跳过验证，降级为标准模式继续 Phase 4
> 3. 停止，稍后处理"

Based on selection:
- 选 1 → 展示完整错误，等用户修复后重新执行 Phase 3.5（重置 verification_rounds=0）
- 选 2 → 继续 Phase 4，在 PR 描述中标注「⚠️ 验证未通过，人工跳过」
- 选 3 → 结束流程，保留 `.ce-work-verification.json` 供后续参考
```

**Patterns to follow:** Phase -1 的条件执行模式；Layer 2 中使用 `Skill("agent-browser")` 加载方式（参见 Phase 4 Step 1 的 agent-browser 用法）

**Test scenarios:**
- Happy path: 前端任务 → L0+L2+L3 全通过 → passes:true → 进入 Phase 4
- Happy path: 纯 CLI 任务 → L0+L3 通过，L1/L2 skip → passes:true
- Edge case: Markdown 任务 → L1/L2 skip，L0+L3 运行
- Edge case: L0 第1轮失败 → 修复 → 第2轮通过
- Error path: 2轮均失败 → BLOCKED → AskUserQuestion 弹出
- Error path: dev server 未运行 → L2 跳过，继续 L3
- Error path: 无验收场景 → Layer 3 宽松核查模式，带警告
- Integration: [T]+[team] → Layer 3 与 team 验证者 Hook 合并不重复

**Verification:**
- 读回 SKILL.md 确认 Phase 3.5 节存在于 Phase 3 之后、Phase 4 之前
- 确认四层的触发/跳过逻辑均有文字描述
- 确认 BLOCKED 状态使用 AskUserQuestion tool
- 确认 agent-browser 和 Playwright MCP 均有引用

---

- [x] **Unit 3: ce:plan 模板增加验收场景章节**

**Goal:** ce:plan 生成的计划文件包含"验收场景"章节，供 ce:work [T] 的 Layer 3 读取

**Requirements:** R6

**Dependencies:** 无（可与 Unit 1/2 并行）

**Files:**
- Modify: `plugins/compound-engineering/skills/ce-plan/SKILL.md`

**Approach:**

在 Phase 4.2 的 Core Plan Template（`#### 4.2 Core Plan Template`）的代码块中，在 `## System-Wide Impact` 和 `## Risks & Dependencies` 之间插入：

```markdown
<!-- 当计划预期使用 ce:work [T] 模式时包含此章节；否则可省略。 -->
## 验收场景（[T] 模式使用）

> 每条场景对应 ce:work [T] 的验证层。Layer 3 独立 reviewer 将逐条核查变更文件是否满足以下标准。

| # | 场景 | 操作步骤 | 期望结果 | 层级 |
|---|------|----------|----------|------|
| 1 | [功能场景描述] | [用户操作步骤] | [可观测的期望结果] | Layer 0/1/2/3 |
```

同时在 Phase 4.3 规则末尾（Planning Rules）添加一条：
> - 若计划预期使用 `ce:work [T]`，必须包含 `## 验收场景` 章节；Layer 3 验证器将在此处读取验收标准。

**Patterns to follow:** ce:plan 模板中已有的 `<!-- 可选: ... -->` 注释风格

**Test scenarios:**
- Happy path: 新生成的 plan 含「验收场景」章节，格式正确（表格 + 注释）
- Edge case: 章节为可选，不包含时 ce:work [T] 退回宽松核查模式（已在 Unit 2 处理）

**Verification:**
- 读回 ce:plan SKILL.md，确认模板中 `## 验收场景` 章节存在于 `## System-Wide Impact` 之后
- 确认注释标注"可省略"（非强制）
- 确认 Phase 4.3 Planning Rules 有新增条目

---

- [x] **Unit 4: .gitignore + CLAUDE.md 更新**

**Goal:** 防止验证状态文件被提交；更新用户文档记录 [T] 参数

**Requirements:** R4

**Dependencies:** 无（可与其他 Unit 并行）

**Files:**
- Modify: `.gitignore`
- Modify: `plugins/compound-engineering/CLAUDE.md`

**Approach:**

*.gitignore*：在现有 `.claude/` 相关条目附近追加：
```
.ce-work-verification.json
```

*CLAUDE.md*：在 `### [team] 参数说明` 章节的参数表格行末（`| `[team]` | ce:work | ...`）**之前**插入 [T] 独立说明段，或在主工作流 Skills 表格中更新 ce:work 行的描述（添加 `[T]` 参数说明）。

在 `| `/ce:work` | 执行工作计划 `[team][team:full][R]`|` 这一行改为：
```
| `/ce:work` | 执行工作计划 `[team][team:full][R][T=四层自验证][PW=Playwright浏览器]` |
```

**Test scenarios:**
- Edge case: `.ce-work-verification.json` 不会出现在 `git status` 中（.gitignore 生效）
- Happy path: CLAUDE.md 中 ce:work 命令行显示 [T] 参数

**Verification:**
- 读回 `.gitignore`，确认包含 `.ce-work-verification.json`
- 读回 `plugins/compound-engineering/CLAUDE.md`，确认 ce:work 行包含 `[T]`

---

- [x] **Unit 5: 版本号更新**

**Goal:** 插件版本从 2.45.13 → 2.45.14（patch）

**Requirements:** CLAUDE.md 铁律

**Dependencies:** Units 1-4 全部完成后执行

**Files:**
- Modify: `plugins/compound-engineering/.claude-plugin/plugin.json`（由脚本自动更新）

**Approach:**

```bash
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch
```

**Test scenarios:**
- Happy path: 脚本运行后 plugin.json 版本变为 2.45.14

**Verification:**
- 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 确认版本一致

---

## System-Wide Impact

- **Interaction graph:** Phase -1 现有 [team] 逻辑不受影响；Phase 3.5 仅当 T_MODE_ENABLED=true 才执行，其余 Phase 流程完全不变
- **Error propagation:** Layer 失败 → 修复重试（2轮）→ BLOCKED → AskUserQuestion；不自动中止，让用户决策
- **State lifecycle risks:** `.ce-work-verification.json` 在任务开始时创建，任务完成或 BLOCKED 后保留（不自动删除）；由 .gitignore 防止误提交
- **API surface parity:** CLAUDE.md 的 ce:work 命令描述同步更新；ce:plan argument-hint 已含 [team] 说明，ce:plan 本身无需额外改动
- **Integration coverage:** [T]+[team] 时 Layer 3 = team 验证者 Hook（合并，不重复）
- **Unchanged invariants:** ce:work 无 [T] 时完全保持原有行为（T_MODE_ENABLED=false 时 Phase 3.5 不执行）

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| agent-browser 未安装时 Layer 2 失败 | 先检查 `command -v agent-browser`，不存在则自动升级为 Playwright MCP 或跳过 L2 + 警告 |
| Phase 3.5 插入位置错误（插到 Phase 4 之后） | 实现后读回验证：确认 "### Phase 3.5" 在 "### Phase 4" 之前 |
| ce:plan 模板修改破坏现有模板结构 | 只在 `## System-Wide Impact` 之后插入，不修改现有字段 |
| [T] 参数被误解为 [t]（大小写）| Phase -1 同时检测 `[T]` 和 `[t]` |

---

## Documentation / Operational Notes

- 无需更新 CHANGELOG.md（由版本号和 PR 描述覆盖）
- ce:work 的 SKILL.md 是本次主要工件，修改后建议通过 `/ce:review` 进行一次人工阅读核查（[T] 模式的 Layer 3 原则）

---

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-09-ce-work-t-mode-self-verification-brainstorm.md](docs/brainstorms/2026-04-09-ce-work-t-mode-self-verification-brainstorm.md)
- **参考模式**: `plugins/compound-engineering/skills/ce-work/SKILL.md:21-28`（Phase -1 [team] 检测）
- **参考模式**: `plugins/compound-engineering/skills/agent-browser/SKILL.md`（浏览器工具用法）
- **参考文档**: SamuelQZQ/auto-coding-agent-demo `task.json` passes 状态机（见 brainstorm 背景分析）
- **参考原则**: Superpowers `spec-reviewer-prompt.md`（不信任实现者报告）
