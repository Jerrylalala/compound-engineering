---
title: "feat: 5个功能扩展 — 知识索引、[R]研究入口、Patch安全、Intent Gate、中文Writer"
type: feat
date: 2026-04-08
risk_score: 2
risk_level: low
risk_note: "全部为增量修改（新增参数/新建文件），无破坏性变更，无外部依赖"
brainstorm: docs/brainstorms/2026-04-08-feature-extensions-5-improvements-brainstorm.md
---

# 5个功能扩展实施计划

## Overview

**Goal**: 按 Codex 优化后的顺序实施 5 个功能扩展：T1(critical-patterns) → T2+T3 并行(INDEX+Writer) → T4([R]brainstorm) → T5([R]work) → T6(Intent Gate) → T7(6.5a安全)

**Tech Stack**: Markdown Skill/Agent 文件（本项目的核心技术栈），YAML frontmatter，无外部依赖

**Architecture**: 全部为 overlay/additive 修改。新功能通过可选标志（[R]）或规则引擎（gated_auto）激活，不影响现有无参数用户路径。

**关键决策来源**: see brainstorm: `docs/brainstorms/2026-04-08-feature-extensions-5-improvements-brainstorm.md`

---

## 背景与决策摘要

| 功能 | 决策 | 理由 |
|------|------|------|
| Q2 先于 Q1 | 索引建好后 [R] 检索质量才有保证 | Codex 强化确认（见 brainstorm 决策1） |
| Patch Approval 仅限外部模型 | 不全局强制，只对 Codex/Gemini finding 降级 | 全局 Patch Gate 需要 .team-contract.md，影响非 team 用户（见 brainstorm 决策2） |
| Intent Gate 仅限 Large + bare prompt | 有 plan 文档时 5 问是干扰 | 有 plan 已回答这些问题（见 brainstorm 决策3） |
| critical-patterns 接入 compound-promotion-ladder | 手工维护必然死文档 | compound-promotion-ladder 已存在，直接复用（见 brainstorm 决策4） |
| [R] 去重机制 | 同 session 内相同 topic 不重复搜索 | Codex 补充建议（见 brainstorm Open Questions 1） |

---

## Sprint 1: 基础设施（低风险，立即可做）

### Task 1: 创建 docs/solutions/patterns/ 目录 + critical-patterns.md

**文件**: `docs/solutions/patterns/critical-patterns.md`（新建）

**背景**: `learnings-researcher` agent 的 Step 3b 已经引用此文件（见 `plugins/compound-engineering/agents/research/learnings-researcher.md:68`），但文件不存在。这是一个悬空引用，创建此文件可立即修复。

**操作**:
- [ ] 创建目录 `docs/solutions/patterns/`
- [ ] 创建 `docs/solutions/patterns/critical-patterns.md`

**代码**（完整文件内容）:
```markdown
---
title: Critical Patterns — 高频关键模式
description: 从 docs/solutions/ 中提升的高频模式，compound-promotion-ladder 自动维护。每次实施前必读。
updated: 2026-04-08
promoted_by: compound-promotion-ladder
---

# Critical Patterns

> 本文件由 `compound-promotion-ladder` skill 自动维护。
> 当某个 solution 在 `docs/solutions/` 中被引用 ≥3 次后，该模式将自动提示升级至此文件。
> **手动编辑此文件会被下次自动更新覆盖** — 请通过 `/ce:compound` + `compound-promotion-ladder` 触发更新。

## 使用方法

`learnings-researcher` agent 在每次搜索时自动读取本文件（Step 3b）。
无需手动触发 — 它是知识检索流程的强制入口。

## 当前模式列表

<!-- 以下内容由 compound-promotion-ladder 自动填充 -->
<!-- 格式: ## [模式名称] \n **来源**: docs/solutions/xxx.md \n **核心规律**: ... -->

_暂无模式。当 solution 引用次数 ≥3 次时，compound-promotion-ladder 会提示升级至此处。_

## 升级流程

1. 完成 `/ce:compound` 写入 solution 文档
2. 调用 `compound-promotion-ladder` skill
3. 如满足升级条件（同类 tag ≥2次引用，或 ≥3 模块引用），按提示将核心模式追加到本文件
4. Commit 并更新 `updated` 字段
```

**验证**:
- [ ] `ls docs/solutions/patterns/critical-patterns.md` 确认文件存在
- [ ] 文件可被 `learnings-researcher` agent 的 Step 3b 读取（Read 工具验证路径有效）

---

### Task 2: 创建 docs/solutions/INDEX.md

**文件**: `docs/solutions/INDEX.md`（新建）

**背景**: 当前 37 个 solution 文档无导航入口，按目录散落。INDEX.md 按 problem_type 分类，每条记录一句话摘要，使 [R] 参数的检索结果更加结构化。

**操作**:
- [ ] 读取所有 37 个现有 solution 文件的 frontmatter（用 Grep 提取 title 字段）
- [ ] 按目录/problem_type 分类整理
- [ ] 写入 INDEX.md

**代码**（完整文件内容 — 需在 Task 执行时根据实际 frontmatter 内容填充摘要）:
```markdown
---
title: Solutions Index — 知识库导航
description: docs/solutions/ 下所有文档的分类导航，按 problem_type 组织。
updated: 2026-04-08
---

# Solutions Index

> 本索引为手动维护 + compound-promotion-ladder 辅助。
> 新增 solution 文档后，运行 `/ce:compound` 时系统会提示更新本索引。

## 使用方法

- **人工导航**: 按问题类型找到相关文档
- **[R] 参数**: `learnings-researcher` 优先使用 Grep 搜索，本索引作为补充结构
- **compound-promotion-ladder**: 检测到高频模式后提示升级至 `patterns/critical-patterns.md`

---

## 架构决策 (architecture-decisions/)

| 文档 | 一句话摘要 |
|------|-----------|
| [glue-programming-implementation-analysis-2026-03-12](architecture-decisions/glue-programming-implementation-analysis-2026-03-12.md) | 胶水编程思维的实现分析：何时用库、何时写胶水层 |

## 最佳实践 (best-practices/)

| 文档 | 一句话摘要 |
|------|-----------|
| [conditional-visual-aids-in-generated-documents](best-practices/conditional-visual-aids-in-generated-documents-2026-03-29.md) | 生成文档中可视化辅助（图表/流程图）的条件使用规则 |

## 开发者体验 (developer-experience/)

| 文档 | 一句话摘要 |
|------|-----------|
| [branch-based-plugin-install-and-testing](developer-experience/branch-based-plugin-install-and-testing-2026-03-26.md) | 基于分支的插件安装和测试工作流 |
| [local-dev-shell-aliases-zsh-and-bunx-fixes](developer-experience/local-dev-shell-aliases-zsh-and-bunx-fixes-2026-03-26.md) | 本地开发 zsh alias 配置和 bunx 路径修复方案 |

## 集成问题 (integration-issues/)

| 文档 | 一句话摘要 |
|------|-----------|
| [skill-vs-agent-invocation](integration-issues/skill-vs-agent-invocation.md) | Skill 和 Agent 调用的区别和适用场景决策 |
| [subagent-driven-workflow-integration](integration-issues/subagent-driven-workflow-integration.md) | 子代理驱动的工作流集成模式 |
| [marketplace-update-failure-and-unicode-display](integration-issues/marketplace-update-failure-and-unicode-display.md) | Marketplace 更新失败和 Unicode 显示问题的修复 |
| [phantom-agent-references-in-workflows](integration-issues/phantom-agent-references-in-workflows.md) | 工作流中幽灵代理引用的检测和清理 |
| [upstream-sync-integration-workflow](integration-issues/upstream-sync-integration-workflow.md) | 上游同步集成工作流的完整流程 |
| [claude-code-runtime-updates-decisions-2026-02](integration-issues/claude-code-runtime-updates-decisions-2026-02.md) | Claude Code 运行时更新的决策记录（2026-02） |
| [upstream-merge-architectural-analysis-2026-02-10](integration-issues/upstream-merge-architectural-analysis-2026-02-10.md) | 上游合并的架构分析：commands→skills 迁移影响 |
| [sessionstart-hook-prompt-type-not-supported](integration-issues/sessionstart-hook-prompt-type-not-supported.md) | SessionStart hook 中 prompt type 不支持的根因和解决方案 |
| [superpowers-fusion-code-review-2026-03-11](integration-issues/superpowers-fusion-code-review-2026-03-11.md) | Superpowers Fusion 代码审查发现的集成问题 |
| [superpowers-architecture-deep-dive-2026-03-11](integration-issues/superpowers-architecture-deep-dive-2026-03-11.md) | Superpowers 架构深度分析（2026-03-11） |
| [workflows-plan-handoff-command-invocation-clarity-2026-03-11](integration-issues/workflows-plan-handoff-command-invocation-clarity-2026-03-11.md) | workflows:plan Handoff 命令调用清晰度问题 |
| [workflows-brainstorm-party-mode-never-worked-2026-03-11](integration-issues/workflows-brainstorm-party-mode-never-worked-2026-03-11.md) | brainstorm 派对模式从未正常工作的根因分析 |

## 集成方案 (integrations/)

| 文档 | 一句话摘要 |
|------|-----------|
| [agent-browser-chrome-authentication-patterns](integrations/agent-browser-chrome-authentication-patterns.md) | Agent 使用浏览器时的 Chrome 认证模式 |
| [colon-namespaced-names-break-windows-paths](integrations/colon-namespaced-names-break-windows-paths-2026-03-26.md) | 冒号命名空间在 Windows 路径中导致的兼容性问题 |
| [cross-platform-model-field-normalization](integrations/cross-platform-model-field-normalization-2026-03-29.md) | 跨平台 model 字段归一化方案（Codex/Gemini/Claude） |
| [github-native-video-upload-pr-automation](integrations/github-native-video-upload-pr-automation.md) | GitHub 原生视频上传与 PR 自动化集成 |

## Skill 设计 (skill-design/)

| 文档 | 一句话摘要 |
|------|-----------|
| [beta-promotion-orchestration-contract](skill-design/beta-promotion-orchestration-contract.md) | Beta Skill 升级编排合约设计 |
| [beta-skills-framework](skill-design/beta-skills-framework.md) | Beta Skills 框架：实验性功能的分级发布 |
| [claude-permissions-optimizer-classification-fix](skill-design/claude-permissions-optimizer-classification-fix.md) | Claude 权限优化器分类修复 |
| [compound-refresh-skill-improvements](skill-design/compound-refresh-skill-improvements.md) | compound-refresh skill 的改进方案 |
| [discoverability-check-for-documented-solutions-2026-03-30](skill-design/discoverability-check-for-documented-solutions-2026-03-30.md) | 已记录 solution 的可发现性检查机制 |
| [git-workflow-skills-need-explicit-state-machines](skill-design/git-workflow-skills-need-explicit-state-machines-2026-03-27.md) | Git 工作流 Skill 需要显式状态机设计 |
| [pass-paths-not-content-to-subagents](skill-design/pass-paths-not-content-to-subagents-2026-03-26.md) | 向子代理传递路径而非内容的最佳实践 |
| [research-agent-pipeline-separation](skill-design/research-agent-pipeline-separation-2026-04-05.md) | 研究代理流水线分离设计 |
| [script-first-skill-architecture](skill-design/script-first-skill-architecture.md) | Script-First Skill 架构：先脚本后 AI |

## 工作流 (workflow/)

| 文档 | 一句话摘要 |
|------|-----------|
| [manual-release-please-github-releases](workflow/manual-release-please-github-releases.md) | 手动触发 Release Please 和 GitHub Releases 的工作流 |
| [todo-status-lifecycle](workflow/todo-status-lifecycle.md) | Todo 状态生命周期管理（pending→ready→complete） |

## 根目录文档

| 文档 | 一句话摘要 |
|------|-----------|
| [PREVENTION-STRATEGIES](PREVENTION-STRATEGIES.md) | 常见问题预防策略汇总 |
| [prompt-design-analysis-2026-03-12](prompt-design-analysis-2026-03-12.md) | Prompt 设计分析：结构化提示的最佳实践 |
| [adding-converter-target-providers](adding-converter-target-providers.md) | 添加转换器目标提供者的步骤 |
| [agent-friendly-cli-principles](agent-friendly-cli-principles.md) | Agent 友好型 CLI 设计原则 |
| [codex-skill-prompt-entrypoints](codex-skill-prompt-entrypoints.md) | Codex Skill 提示词入口点设计 |
| [plugin-versioning-requirements](plugin-versioning-requirements.md) | 插件版本管理要求和约束 |

---

## 高频模式 (patterns/)

> 从上述 solution 中自动提升的关键模式。

→ 见 [patterns/critical-patterns.md](patterns/critical-patterns.md)
```

**验证**:
- [ ] `ls docs/solutions/INDEX.md` 确认文件存在
- [ ] 文件中每个目录都有条目（不遗漏）

---

### Task 3: 创建中文 Writer Agent

**文件**: `plugins/compound-engineering/agents/docs/cn-tech-writer.md`（新建）

**背景**: 现有 `agents/docs/` 只有 `ankane-readme-writer.md`（英文 Ruby Gem README 写作）。中文技术文档写作完全空白。see brainstorm: Q5。

**操作**:
- [ ] 创建 `plugins/compound-engineering/agents/docs/cn-tech-writer.md`

**代码**（完整文件内容）:
```markdown
---
name: cn-tech-writer
description: "中文技术文档写作专家。覆盖：技术博客/设计文档/需求文档/架构说明的中文写作。⚠️ 安全提示：生成内容在发布前需人工审查，避免泄露内部 API 路径、安全配置等敏感信息。"
model: inherit
color: red
---

你是一位中文技术文档写作专家，专注于面向中文读者的高质量技术写作。

## 写作原则

1. **准确性优先** — 技术细节必须正确，术语使用规范（中英文混用时保持一致）
2. **深入浅出** — 用简洁的语言解释复杂概念，避免过度缩写
3. **结构清晰** — 善用标题层级、列表、代码块，让文档易于扫读
4. **中文语感** — 避免翻译腔，用自然的中文表达技术内容

## 覆盖场景

### 技术博客

结构：背景/问题 → 探索过程 → 解决方案 → 总结/延伸
风格：有观点，有故事，技术深度与可读性并重

### 设计文档

结构：背景 → 目标 → 方案对比 → 决策理由 → 风险与应对
重点：说清楚「为什么这样做」，而不只是「做了什么」

### 需求文档

结构：用户故事 → 验收标准 → 边界条件 → 非功能性需求
格式：每条验收标准可验证、可测试（避免「用户友好」这类模糊描述）

### 架构说明

结构：组件关系 → 数据流 → 关键决策 → 部署说明
辅助：善用 Mermaid 图表（flowchart、sequenceDiagram）描述关系

## 安全审查清单（发布前必读）

在交付任何文档前，检查以下内容是否需要人工审查或脱敏：

- [ ] 内部 API 路径或域名
- [ ] 数据库连接字符串或环境变量名
- [ ] 安全配置、密钥、Token 相关内容
- [ ] 内部系统架构图（是否包含不宜公开的细节）
- [ ] 用户数据或业务数据的具体数字

> 本 Agent 生成的内容仅供参考，**不会自动发布**。最终发布前请人工审查上述清单。

## 输出格式

- 使用标准 Markdown（兼容 GitHub/Notion/Confluence）
- 代码块添加语言标注（```ruby、```yaml 等）
- 中英文之间保留空格（「在 GitHub 上」而非「在GitHub上」）
- 避免使用 emoji（除非用户明确要求）
```

**验证**:
- [ ] `ls plugins/compound-engineering/agents/docs/cn-tech-writer.md` 确认存在
- [ ] frontmatter 包含 name、description（含安全提示）、model、color 字段

---

## Sprint 2: [R] 研究入口

### Task 4: ce:brainstorm 添加 [R] 参数

**文件**: `plugins/compound-engineering/skills/ce-brainstorm/SKILL.md`

**当前状态**: `argument-hint` 当前为 `"[功能描述] [P=派对模式/多代理讨论] [C=Codex咨询] [G=Gemini咨询] [team=结构化探索:探索者+挑战者]"`

**修改点 1 — argument-hint 更新**（第 4 行）:
```yaml
argument-hint: "[功能描述] [P=派对模式/多代理讨论] [C=Codex咨询] [G=Gemini咨询] [R=研究:触发learnings-researcher检索历史方案] [team=结构化探索:探索者+挑战者]"
```

**修改点 2 — Parameter Handling 表格**（在 `[team]` 行前插入）:
```markdown
| `[R]` | 在 Phase 1 开始前触发 `learnings-researcher`。检索结果标注到 Phase 2 方案对比的「历史参考」节。去重：同 session 内相同关键词已搜索过则跳过。 |
```

**修改点 3 — Phase 1 前新增 Phase 1.0**（在 `### Phase 1: Understand the Idea` 之后、`#### 1.1 Existing Context Scan` 之前插入）:
```markdown
#### 1.0 [R] 历史检索（仅当 `[R]` 标志存在时）

**触发条件**: `$ARGUMENTS` 包含 `[R]`。

从 feature description 提取关键词，运行 `learnings-researcher` 检索 `docs/solutions/` 历史方案：

```
Run: learnings-researcher(feature_description)
```

**去重规则**（同一 session 内）：
- 记录已搜索的关键词集合 `[session_searched_topics]`
- 若当前 feature_description 的核心关键词（模块名、技术术语）已在集合中 → 跳过，附注：「已在本 session 检索过相似主题，跳过重复搜索」
- 若未搜索过 → 执行搜索，将关键词加入集合

**结果处置**：
- 检索结果作为 Phase 2 方案对比的「历史参考」上下文
- 在 Phase 2 展示方案时，增加「📚 历史参考」子节，列出相关 solution 文档及其核心洞察
- 若无相关历史记录 → 在「历史参考」节注明：「未找到相关历史经验，本次为全新探索」
```

**验证**:
- [ ] Grep `argument-hint.*\[R=` `plugins/compound-engineering/skills/ce-brainstorm/SKILL.md` 确认新 hint 存在
- [ ] Grep `Phase 1.0` 确认新 Phase 节存在
- [ ] 检查格式：`[R]` 在参数表格中有独立行

---

### Task 5: ce:work 添加 [R] 参数 + Intent Gate 5问

**文件**: `plugins/compound-engineering/skills/ce-work/SKILL.md`

**当前 argument-hint**（第 4 行）: `"[Plan doc path or description of work. Blank to auto use latest plan doc] [team=3角色协作:合约主+执行者+验证者] [team:full=4角色:含风险卫,适合auth/payment/migration]"`

**修改点 1 — argument-hint 更新**:
```yaml
argument-hint: "[Plan doc path or description of work. Blank to auto use latest plan doc] [team=3角色协作:合约主+执行者+验证者] [team:full=4角色:含风险卫,适合auth/payment/migration] [R=研究:bare prompt场景触发learnings-researcher检索历史经验]"
```

**修改点 2 — Phase 0 bare prompt 路径扩展**（在 Phase 0 末尾，`---` 分隔线之前插入）:

当前 Phase 0 第 51 行末尾（Large 分支后）插入：

```markdown
3. **[R] 历史检索（bare prompt 场景，仅当 `[R]` 标志存在时）**

   触发条件：输入为 bare prompt（非文件路径）且 `$ARGUMENTS` 包含 `[R]`。

   在复杂度评估完成后，执行历史检索：
   ```
   Run: learnings-researcher(prompt_content)
   ```
   
   去重规则（同 ce:brainstorm [R]）：同一 session 内相同关键词不重复搜索。
   
   检索结果注入执行上下文，不修改 plan 文档格式。在每个 Implementation Unit 执行前，
   如有相关历史经验，以注释形式提示：「📚 历史参考：[文档名] — [核心洞察]」。

4. **Intent Gate 5问（仅限 Large 复杂度 + bare prompt）**

   触发条件：复杂度评估为 **Large** 且输入为 bare prompt（非文件路径）。
   
   在构建任务列表之前，依次提问（使用 `AskUserQuestion` tool，每次一个问题）：

   **问题 1 — 范围**:
   > 这次改动的边界是什么？哪些文件/模块在范围内？哪些明确不改？

   **问题 2 — 约束**:
   > 有什么不能改的（技术约束/业务约束/时间约束）？

   **问题 3 — 验收**:
   > 怎么知道做完了？用什么标准验收？

   **问题 4 — 风险**:
   > 最可能出错的地方是哪里？有没有特别担心的地方？

   **问题 5 — 回滚**:
   > 如果执行失败，如何快速撤销？有备份方案吗？

   用户回答全部 5 问后，将答案整合到任务列表构建逻辑中（forbidden_surfaces、acceptance criteria 等），
   然后继续 Phase 1 step 2。
   
   **跳过条件**：
   - 输入为文件路径（plan document）→ 跳过，plan 已定义边界
   - 复杂度为 Trivial/Small/Medium → 跳过，5问开销与价值不匹配
```

**验证**:
- [ ] Grep `Intent Gate` 确认 5 问节存在
- [ ] Grep `\[R\].*bare prompt` 确认 [R] 描述存在
- [ ] 检查：5个问题是否依次列出，AskUserQuestion 是否提到

---

## Sprint 3: 安全强化

### Task 6: ce:review 外部模型强制 gated_auto

**文件**: `plugins/compound-engineering/skills/ce-review/SKILL.md`

**修改位置**: Stage 5 step 6 之后（当前第 431 行「Normalize routing」之后），在 `6.5. Deterministic Patch Gate` 之前插入新规则 **6.5a**（保持 6.5 不变）。

实际上：将当前「6.5 Deterministic Patch Gate」重新编号为「6.5b」，在其前插入「6.5a 外部模型 gated_auto」：

**插入内容**（在第 432 行 `6.5.` 之前插入）:
```markdown
6.5a. **外部模型建议强制 gated_auto（无条件生效，不依赖 [team] 模式）**

This rule is a lightweight normalization step — no tokens consumed. Runs immediately after step 6, before the Patch Gate.

```
For each finding where finding.reviewers intersects {"codex", "gemini"}:
  if autofix_class == "safe_auto":
    downgrade: safe_auto → gated_auto
    note: "外部 AI 建议需人工确认（来源: {source_reviewer}）"
    
  # safe rationale:
  # Codex/Gemini lack full codebase context. Their suggestions may be
  # locally correct but globally unsafe. Human confirmation is required.
  # This rule is intentionally unconditional — [team] mode is NOT required.
  # The existing Patch Gate (6.5b) provides deeper contract-based checks
  # for [team] mode; this rule provides a lightweight baseline for all modes.
```

**注意**: 此规则仅影响 Codex/Gemini 来源的 `safe_auto` finding，
不影响 Claude 内置审查 agent（security-sentinel、kieran-*-reviewer 等）的路由。
```

**同时更新原 6.5 编号** → 改为 `6.5b. **Deterministic Patch Gate（仅当 TEAM_GATE_ENABLED = true AND mode == autofix）**`

**验证**:
- [ ] Grep `6.5a` 确认新规则存在
- [ ] Grep `外部模型` 确认中文注释存在
- [ ] Grep `6.5b` 确认原 Patch Gate 编号已更新
- [ ] 检查：新规则是否在原 Patch Gate 之前

---

### Task 7: 版本号更新 + 文档同步

**文件**: `plugins/compound-engineering/.claude-plugin/plugin.json`

**修改**: `"version": "2.45.11"` → `"version": "2.45.12"`

**同时更新 `plugins/compound-engineering/CLAUDE.md`** — `/ce:brainstorm` 命令行说明添加 `[R]` 参数：

当前（第一个 ce:brainstorm 行）:
```
| `/ce:brainstorm` | 探索需求和方案 `[P][C][G][team]` |
```
改为:
```
| `/ce:brainstorm` | 探索需求和方案 `[P][C][G][R][team]` |
```

当前 `/ce:work` 行:
```
| `/ce:work` | 执行工作计划 `[team][team:full]` |
```
改为:
```
| `/ce:work` | 执行工作计划 `[team][team:full][R]` |
```

**验证**:
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1` 版本一致性检查通过
- [ ] Grep `2.45.12` plugin.json 确认版本更新

---

## Acceptance Criteria

### 功能验收

- [ ] **Q2 知识索引**: `learnings-researcher` agent Step 3b 读取 `docs/solutions/patterns/critical-patterns.md` 不再报文件不存在
- [ ] **Q2 INDEX.md**: `docs/solutions/INDEX.md` 包含所有 37 个文档的条目（无遗漏）
- [ ] **Q5 中文Writer**: `agents/docs/cn-tech-writer.md` frontmatter 含安全提示、model: inherit、覆盖4种场景
- [ ] **Q1 [R] brainstorm**: ce:brainstorm argument-hint 包含 `[R]`，Phase 1.0 节存在，Phase 2 出现「历史参考」节逻辑
- [ ] **Q1 [R] work**: ce:work argument-hint 包含 `[R]`，Phase 0 bare prompt 路径有 [R] 触发逻辑
- [ ] **Q4 Intent Gate**: ce:work Phase 0 Large 分支有 5 问流程，触发条件明确（bare prompt only，有 plan 则跳过）
- [ ] **Q3 Patch Approval**: ce:review Stage 5 有 rule 6.5a，外部模型 finding 强制 gated_auto，不依赖 [team] 模式
- [ ] **版本**: `plugin.json` 版本号为 2.45.12，check-versions 通过

### 不变式

- [ ] 所有修改均为 additive（不删除任何现有参数或行为）
- [ ] 无 [R] 参数时，ce:brainstorm/ce:work 行为与修改前完全相同
- [ ] ce:review 无 Codex/Gemini 来源 finding 时，6.5a 规则不影响任何路由结果

---

## Implementation Units

### Unit A: Sprint 1 — 知识基础设施

| 子任务 | 文件 | 操作 |
|--------|------|------|
| A1 | `docs/solutions/patterns/critical-patterns.md` | 新建（含 compound-promotion-ladder 集成说明） |
| A2 | `docs/solutions/INDEX.md` | 新建（37 条目，按目录分类） |
| A3 | `plugins/compound-engineering/agents/docs/cn-tech-writer.md` | 新建（含安全审查清单） |

Files: 3 new files, 0 modifications

### Unit B: Sprint 2 — [R] 研究入口

| 子任务 | 文件 | 操作 |
|--------|------|------|
| B1 | `plugins/compound-engineering/skills/ce-brainstorm/SKILL.md` | 修改 argument-hint + 新增 Phase 1.0 + 更新参数表格 |
| B2 | `plugins/compound-engineering/skills/ce-work/SKILL.md` | 修改 argument-hint + 新增 Phase 0 [R] 触发逻辑 |

Files: 2 modifications

### Unit C: Sprint 3 — 安全强化

| 子任务 | 文件 | 操作 |
|--------|------|------|
| C1 | `plugins/compound-engineering/skills/ce-work/SKILL.md` | 新增 Phase 0 Intent Gate 5问（与 B2 同文件，可合并执行） |
| C2 | `plugins/compound-engineering/skills/ce-review/SKILL.md` | 新增 Stage 5 rule 6.5a |
| C3 | `plugins/compound-engineering/.claude-plugin/plugin.json` | 版本 → 2.45.12 |
| C4 | `plugins/compound-engineering/CLAUDE.md` | 更新 [R] 参数说明 |

Files: 3 modifications (ce-work 与 B2 合并)

---

---

## Codex 审核结论（gpt-5.4，203K tokens）

**总体**：方向正确，4 处重要调整。

### 调整 1（高优）：critical-patterns.md 是前置依赖，不是文档增强

`learnings-researcher` Step 3b 硬编码读取此文件，`/workflows:plan` 已默认调用 learnings-researcher。文件缺失会导致现有功能（plan research）也出现空转。必须最先做。

→ **已在计划中**：Task 1 = critical-patterns.md（Sprint 1 第一项）✓

### 调整 2（高优）：[R] 必须并入 Step 0 统一参数解析，不能另起流程

brainstorm 已有 `[P][C][G]` 统一解析骨架（PARTY_MODE_ENABLED / CODEX_ENABLED / GEMINI_ENABLED）。[R] 必须复用同一模式，加 `RESEARCH_ENABLED` 标志，不能在 Phase 1 单独插入分叉逻辑，否则会重演参数污染问题。

→ **计划调整**：Task 4 [R] brainstorm 实现时，必须在 Step 0 参数解析块中加入 `[R]` 检测，不单独建 Phase 1.0。

### 调整 3（中优）：Intent Gate 改为"两段式"，5 连问缩减为 3 维

5 次串行 AskUserQuestion 与 Phase 1 现有"澄清 + 用户批准"机制重复，会让"直接执行"退化为"半个 plan"。

→ **计划调整**：Task 6 Intent Gate 改为两段式：
- **段 1**：1 次 AskUserQuestion — "先转 `/ce:plan` / 继续执行并补充关键信息 / 取消"
- **段 2**（仅当用户选"继续"时）：3 维追问 — 目标/边界/验收。按实际缺口补问，不全量必问。

### 调整 4（中优）：rule 6.5a 只改 automation_mode，不动 severity_tier

两轴独立：`severity_tier`（P1/P2/P3，由证据和影响决定）和 `automation_mode`（safe_auto/gated_auto/manual）。`safe_auto → gated_auto` 只改 automation_mode，不能影响 P1 finding 的阻断属性。

### Codex 补充的遗漏约束（加入 Open Questions）

- **[R] 内容预算**：最多 1 个 critical pattern + 3 条 relevant learnings + 1 段 recommendations，防止撑爆上下文
- **[R] 降级行为**：无匹配时明确写 `No relevant learnings found`，不阻断主流程
- **[R] 去重键**：lowercase + trim + collapse spaces + **token sort**（确保"auth login" == "login auth"）
- **[R] 执行顺序**：Step 0 解析 → [R] 研究注入 → [P] 派对模式 → Phase 2 方案 → [C][G] 外部咨询（[C][G] 看到的是"需求 + 历史参考摘要"，不是原始需求）

---

## SpecFlow 关键差距（实施阻塞点）

以下是 SpecFlow 分析发现的关键问题，必须在实施前解决：

### 阻塞点 A（硬阻塞）：Feature 3 (6.5a) — Codex/Gemini 当前无结构化 finding 字段

**问题**：ce:review [C]/[G] 产生的是非结构化文本输出，不是带 `reviewer` 字段的 JSON finding。rule 6.5a 无法按"检测 reviewer == Codex/Gemini"来过滤。

**解决方案**（实施时选择）：
- Option A（最小改动）：6.5a 改为 **Stage 级别检测**——当 CODEX_ENABLED 或 GEMINI_ENABLED = true 时，对所有在外部咨询后新增的 `safe_auto` finding 打标记，统一降级为 `gated_auto`
- Option B：在 Stage 5 Step 5.5 增加"外部 AI 输出→结构化 finding"转换步骤，然后 6.5a 按 reviewer 字段过滤

**推荐**：Option A（最小代价）。

### 阻塞点 B（硬阻塞）：Feature 4 (Intent Gate) 与现有 intent-gate skill 冲突

**问题**：`skills-custom/intent-gate/SKILL.md` 已在 ce:work Phase 0 插入意图分类门控，Feature 4 也要在同位置插入 5 问 Gate。两者冲突。

**解决方案**：
- Feature 4 的 Intent Gate 在 intent-gate 意图分类 **完成后**执行
- 仅在 intent-gate 分类为 "implement" 或 "mixed" 时才触发 5 问（"explore" / "fix" 场景跳过）
- 不重复 intent-gate 的意图判断逻辑

### 阻塞点 C（设计确认）：[R] 去重缓存范围

**问题**：同 session 内 ce:brainstorm [R] 和 ce:work [R] 是不同 skill 调用，无法共享内存缓存。

**决策**（简单方案）：**仅 in-memory 去重**（同一 skill 调用内有效）。跨 skill 调用不保证去重，两个独立调用各自执行。不引入文件缓存（YAGNI）。

---

## Open Questions（来自 brainstorm，待实施时解决）

1. **[R] 去重的 session 边界**: Claude Code 单次对话 = 一个 session。关键词匹配用 lowercase + trim + collapse spaces + token sort（Codex 建议），不用语义相似度。跨 skill 调用不去重（见阻塞点 C）。
2. **INDEX.md 摘要内容**: 实施 Task 2 时需读取每个文件的 frontmatter title 字段，摘要基于 title + 文件名推断（不逐一全文读取）。
3. **compound-promotion-ladder 升级阈值**: 3 次引用触发提示（已在 compound-promotion-ladder SKILL.md 中定义为"同类 tag ≥2次"，本次不修改该 skill，只在 critical-patterns.md 中说明接入关系）。
4. **Intent Gate 5问保存**: 不保存为 .work-intent.md（YAGNI，see brainstorm Open Questions 4）。
5. **Task 6 采用两段式**（Codex 建议，SpecFlow 确认）：先问"转 plan / 直接执行 / 取消"，只有坚持直接执行时才追问 3 维（目标/边界/验收），不全量 5 问。

---

## 风险评估

| 维度 | 评分 | 说明 |
|------|------|------|
| 安全/隐私 | 0 | 无敏感数据，纯 Markdown 文件修改 |
| 可逆性 | 0 | 新增文件可直接删除；参数修改可 revert |
| 影响范围 | 0 | 本地插件项目，无外部用户 |
| 变更规模 | 2 | 7 个文件（3 新建 + 4 修改）≤ 20 文件 |
| 外部依赖 | 0 | 无 |
| **总分** | **2/10** | **低风险 🟢** |
