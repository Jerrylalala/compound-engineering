---
type: sync-report
date: 2026-04-07
category: ecosystem-analysis
topic: harness-engineering
---

# Harness Engineering 生态分析报告

**日期**: 2026-04-07
**分析目的**: 评估 Harness Engineering 生态中的关键项目，与本仓库对比，推荐新增上游参考
**数据来源**: GitHub、linux.do 社区讨论、博客园对比文章

---

## 一、什么是 Harness Engineering？

2026 年 Q1 最热门的 AI 工程概念。OpenAI 于 2026 年 2 月正式提出。

**核心定义**：

> Harness Engineering = Context Engineering + Tool/Permission 协议 + Agent Loop + 状态/恢复 + 验证/反馈 + 子智能体编排

Harness 解决的问题：**模型这一步能做什么、怎么做、做到哪一步停、失败后怎么恢复、结果如何验证。**

LangChain 实证：同一个 LLM，换上更精巧的 Harness，Terminal Bench 2.0 通过率从 52.8% 提升到 66.5%。

**关键事件**：
- 2026-02: OpenAI 正式提出 "harness engineering" 概念
- 2026-03-31: Claude Code v2.1.88 源码泄露（npm source map），51.2 万行 TypeScript 被逆向
- 2026-01-09: Anthropic 封锁第三方 OAuth Token，社区分裂

---

## 二、生态套件全景

### 2.1 套件缩写对照表

| 缩写 | 全称 | GitHub | 宿主平台 |
|------|------|--------|---------|
| **ECC** | Everything Claude Code / Compound-Engineering | EveryInc/compound-engineering-plugin | Claude Code / Cursor / Codex |
| **ECC-Private** | 本仓库（ECC 私有镜像 + 中文化 + 本地扩展） | Jerrylalala/compound-engineering-plugin-private | Claude Code |
| **SP** | Superpowers | obra/superpowers | Claude Code / Cursor / Copilot CLI |
| **OMOC / OmO** | Oh My OpenCode → Oh My OpenAgent | code-yeongyu/oh-my-openagent | OpenCode |
| **OMCC / OMC** | Oh My Claude Code | Yeachan-Heo/oh-my-claudecode | Claude Code |
| **OMCX / OMX** | Oh My Codex | Yeachan-Heo/oh-my-codex | Codex CLI |
| **CCG** | CCG Workflow | fengshao1227/ccg-workflow | Claude Code (编排 Codex + Gemini) |
| **CCH** | Claude Code Harness | Chachamaru127/claude-code-harness | Claude Code |
| **CX** | Codex (原生) | openai/codex | 独立 CLI |
| **CC** | Claude Code (原生) | anthropics/claude-code | 独立 CLI |

### 2.2 规模对比

| 维度 | **ECC-Private (本仓库)** | **ECC 上游** | **SP** | **OMOC** | **OMCC** | **OMCX** | **CCG** | **CCH** |
|------|------------------------|-------------|--------|----------|----------|----------|---------|---------|
| GitHub Stars | 私有 | 50K+ | — | 49K | 25K | 2.9K | — | — |
| Agents | 29 | 30+ | 子Agent | 11 | 19(+tier) | team式 | team式 | 3 |
| Skills | 32 (26+6) | 136+ | ~20 | 内置 | 36+ | — | — | 5 verb |
| Commands | 39 | 60+ | — | ultrawork | /team等 | /omx等 | 29+ | — |
| Hooks | CC 内置 | 30+ | 流程驱动 | 41 | HUD等 | 插件式 | — | TS guardrail |

---

## 三、Agent 种类职责对比（核心表）

> 基于 linux.do 文章的对比框架，加入本仓库（ECC-Private）和 ECC 上游

| Agent 种类 | **ECC-Private (本仓库)** | **CC** | **CX** | **OMOC** | **OMCC** | **OMCX** | **CCG** | **SP** |
|-----------|------------------------|--------|--------|----------|----------|----------|---------|--------|
| **通用 / 兜底** | general-purpose (继承CC) | General-purpose | default | Sisyphus | 无 | 无 | 无 | 无 |
| **探索 / 检索** | Explore + 5个research agents | Explore | explorer | Explore | explore | explore | /ccg:team-research | Explore (继承CC) |
| **需求 / 范围分析** | spec-flow-analyzer | 无 | 无 | Metis | analyst | 无 | /ccg:team-research | brainstorming skill |
| **规划** | Plan + ce:plan | Plan | 无 | Prometheus | planner | planner | /ccg:team-plan | writing-plans skill |
| **计划审查 / 反驳** | plan_review + document-review | 无 | 无 | Momus | critic | critic | /ccg:team-review | 无 |
| **架构 / 设计评审** | architecture-strategist | 无 | 无 | Oracle | architect | architect | init-architect | 无 |
| **调试 / 根因分析** | bug-reproduction-validator + systematic-debugging | 无 | 无 | Oracle | debugger | debugger | 无 | systematic-debugging |
| **实现 / 执行** | ce:work (subagent) | General-purpose | worker | Hephaestus / Sisyphus-Jr | executor | executor | /ccg:team-exec | executing-plans skill |
| **代码审查** | 15个review agents ⭐ | 无 | 无 | Oracle | code-reviewer | 无 | /ccg:team-review | requesting-code-review |
| **测试工程 / TDD** | TDD skill (继承SP) | 无 | 无 | 无 | test-engineer | test-engineer | 无 | test-driven-development ⭐ |
| **验证 / 验收** | verification skill (继承SP) | 无 | 无 | Atlas | verifier | verifier | /ccg:team-review | verification-before-completion |
| **文档/知识检索** | 5个research agents ⭐ | 无 | 无 | Librarian | 无 | 无 | 无 | 无 |
| **文档写作** | ankane-readme-writer | 无 | 无 | 无 | writer | writer | 无 | 无 |
| **多模态分析** | design agents (3个) | 无 | 无 | Multimodal-Looker | 无 | 无 | ui-ux-designer | 无 |
| **安全审计** | security-sentinel ⭐ | 无 | 无 | 无 | 无 | 无 | 无 | 无 |
| **性能分析** | performance-oracle ⭐ | 无 | 无 | 无 | 无 | 无 | 无 | 无 |
| **数据迁移** | data-migration-expert + data-integrity-guardian ⭐ | 无 | 无 | 无 | 无 | 无 | 无 | 无 |
| **部署验证** | deployment-verification-agent ⭐ | 无 | 无 | 无 | 无 | 无 | 无 | 无 |
| **经验积累** | ce:compound ⭐ | 无 | 无 | 无 | /learner | 无 | 无 | 无 |
| **多模型调度** | ❌ | ❌ | ❌ | ✅ 自动路由 | ✅ /ccg模式 | ✅ team式 | ✅ Claude+Codex+Gemini | ❌ |
| **Hash锚定编辑** | ❌ | ❌ | ❌ | ✅ Hashline | ❌ | ❌ | ❌ | ❌ |
| **LSP/AST** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **意图分类** | ❌ | ❌ | ❌ | ✅ Intent Gate | ❌ | ❌ | ✅ 自动路由 | ❌ |

⭐ = 该套件独有或领先的能力

---

## 四、本仓库深度分析

### 4.1 本仓库当前组件清单

**Agents (29个，5大类)**：

| 类别 | 数量 | 具体 Agent |
|------|------|-----------|
| review | 15 | agent-native-reviewer, architecture-strategist, code-simplicity-reviewer, data-integrity-guardian, data-migration-expert, deployment-verification-agent, dhh-rails-reviewer, julik-frontend-races-reviewer, kieran-python-reviewer, kieran-rails-reviewer, kieran-typescript-reviewer, pattern-recognition-specialist, performance-oracle, schema-drift-detector, security-sentinel |
| research | 5 | best-practices-researcher, framework-docs-researcher, git-history-analyzer, learnings-researcher, repo-research-analyst |
| design | 3 | design-implementation-reviewer, design-iterator, figma-design-sync |
| workflow | 5 | bug-reproduction-validator, every-style-editor, lint, pr-comment-resolver, spec-flow-analyzer |
| docs | 1 | ankane-readme-writer |

**Skills (32个 = 26 原生 + 6 自定义)**：

| 类型 | 技能 |
|------|------|
| 核心工作流 | brainstorming, document-review, create-agent-skills, setup |
| 开发方法 | test-driven-development, systematic-debugging, front-end-design, agent-native-architecture |
| Ruby/Rails | dhh-rails-style, dspy-ruby, andrew-kane-gem-writer |
| Git | git-worktree, finishing-a-feature |
| 工具集成 | agent-browser, gemini-imagegen, rclone, party-mode |
| 审查 | spec-compliance-review, receiving-code-review |
| 编排 | orchestrating-swarms, glue-coding, resolve-pr-parallel |
| 自定义 | findings-triage, review-prompt, root-cause-analysis, sync-targets, user-first-design |

**Commands (39+，含 workflows 子命令)**：

核心 workflows: brainstorm, plan, work, review, compound, pr, doctor, sync-upstream

### 4.2 Harness Engineering 支持度评估

| Harness 能力 | 支持度 | 实现方式 | 对比最佳实践 |
|-------------|--------|---------|-------------|
| Context Engineering | ✅ 强 | Skills 系统 + CLAUDE.md + 经验库 | 与 ECC 上游持平 |
| Tool/Permission 协议 | ✅ 强 | Agent 定义中的工具限制 | 与 ECC 上游持平 |
| Agent Loop | ✅ 强 | ce:work 执行循环 | 不如 OMCC 的 ralph 循环 |
| 状态/恢复 | ⚠️ 弱 | 依赖 CC 内置 | 不如 OMOC 的 MCP 状态服务器 |
| 验证/反馈 | ✅ 强 | 15 个 review agents + TDD | **领先**，审查管线最深 |
| 子智能体编排 | ✅ 强 | 29 个专用 Agent + 并行 | 与 ECC/OMCC 持平 |
| 跨模型调度 | ❌ 缺失 | — | 不如 OMOC/CCG |
| 持续学习 | ✅ 独有 | ce:compound 经验库 | **领先**，仅 OMCC 的 /learner 有类似功能 |

### 4.3 本仓库的核心优势（⭐ 独有或领先）

1. **审查管线最深**：15 个专用 review agents，覆盖安全/性能/架构/数据迁移/部署/前端竞态/Rails/Python/TypeScript —— **没有任何其他套件达到这个细粒度**
2. **经验积累闭环**：ce:compound → docs/solutions/ 的知识沉淀是**独有能力**
3. **完整工作流闭环**：brainstorm → plan → work → review → compound → pr，5 阶段全覆盖
4. **中文本地化**：唯一提供完整中文文档和中文交互的 Harness 套件
5. **双上游跟踪**：ECC + Superpowers，集两家之长
6. **Codex 集成**：已有 Codex 工作流同步机制

### 4.4 本仓库的核心劣势

1. **无跨模型调度**：OMOC 的自动路由、CCG 的三模型协作、OMCC 的 /ccg 模式都已实现
2. **无持久执行循环**：OMCC 的 ralph 模式（失败重试直到成功）、OMOC 的 Sisyphus 循环
3. **无 Hash 锚定编辑**：OMOC 独有，编辑成功率 6.7% → 68.3%
4. **无 LSP/AST 集成**：OMOC 独有
5. **无意图分类**：OMOC 的 Intent Gate、CCG 的自动路由
6. **上游落后 ~270 commits**：plan/review/brainstorm 已被上游全面重写
7. **无自动技能学习**：OMCC 的 /learner 可自动从调试中提取 skill

---

## 五、各套件适用场景与选型建议

| 场景 | 推荐套件 | 理由 |
|------|---------|------|
| 严格工程纪律，代码质量优先 | **ECC-Private (本仓库)** 或 **Superpowers** | 15 个 review agents 无人匹敌 |
| 多模型协作，成本敏感 | **CCG** | Claude 编排 + Codex 后端 + Gemini 前端，安全隔离 |
| 最大并行度，快速出活 | **OMCC** 或 **OMOC** | team 模式、ralph 循环、ultrawork 爆发 |
| 中文团队，经验积累 | **ECC-Private (本仓库)** | 唯一中文化 + compound 经验库 |
| OpenCode 用户 | **OMOC** | 唯一 OpenCode 增强方案 |
| Codex 用户 | **OMCX** | Codex 专用编排 |
| 入门低门槛 | **OMCC** | 零配置，Claude Code 插件一键安装 |

---

## 六、推荐新增上游参考

### 强烈推荐

| 仓库 | 角色 | Stars | 理由 |
|------|------|-------|------|
| `Yeachan-Heo/oh-my-claudecode` | reference | 25K | **同宿主平台 (Claude Code)**，团队编排、/learner 自动学习、ralph 持久循环。可直接参考其 Agent 设计和编排模式 |
| `code-yeongyu/oh-my-openagent` | reference | 49K | Hash 锚定编辑、Intent Gate、多模型调度。虽然宿主不同 (OpenCode)，但设计理念可借鉴 |

### 建议参考

| 仓库 | 角色 | 理由 |
|------|------|------|
| `fengshao1227/ccg-workflow` | reference | 多模型安全协作模式：外部模型只返回 patch，Claude 审批后才写入。适合参考多模型安全架构 |

### 可选参考

| 仓库 | 角色 | 理由 |
|------|------|------|
| `Chachamaru127/claude-code-harness` | reference | TypeScript guardrail 引擎、5 verb skills 极简设计。另一种 Harness 思路 |

---

## 七、oh-my-claudecode 详细分析（用户重点关注）

### 7.1 基本信息

- **仓库**: [Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)
- **Stars**: 25.3K
- **安装**: `/plugin marketplace add` 一键安装
- **定位**: Teams-first 多智能体编排框架

### 7.2 核心能力

| 能力 | 说明 | 本仓库是否有 |
|------|------|------------|
| Team 编排 | plan→prd→exec→verify→fix 管线 | ✅ 有（brainstorm→plan→work→review） |
| Autopilot | 自动化单 lead 执行 | ⚠️ 部分（ce:work） |
| Ralph 循环 | 持久模式，失败自动重试直到完成 | ❌ 无 |
| Ultrawork | 最大并行爆发 | ⚠️ 部分（resolve_parallel） |
| Deep Interview | 苏格拉底式需求澄清 | ✅ 有（brainstorm） |
| /ccg 模式 | Codex + Gemini + Claude 合成 | ❌ 无 |
| /learner | 自动从调试中提取 skill | ❌ 无（compound 是手动触发） |
| HUD Statusline | 实时编排指标 | ⚠️ 有（claude-hud，但非 OMCC 原生） |
| 速率限制恢复 | 被限速后自动等待恢复 | ❌ 无 |
| 自定义 Skill | .omc/skills/ 目录 + trigger 自动注入 | ✅ 有（skills-custom/） |

### 7.3 与本仓库互补性分析

| 维度 | OMCC 强 / 本仓库弱 | 本仓库强 / OMCC 弱 |
|------|-------------------|-------------------|
| 执行韧性 | ralph 循环、速率限制恢复 | — |
| 多模型 | /ccg 三模型合成 | — |
| 自动学习 | /learner 自动提取 | ce:compound 更结构化 |
| 审查深度 | — | 15 个 review agents（OMCC 只有 code-reviewer） |
| 经验积累 | — | compound 经验库（OMCC 无） |
| 工作流闭环 | — | 5 阶段完整闭环（OMCC 偏执行） |
| 工程纪律 | — | TDD、document-review、spec-compliance |

**结论**：OMCC 和本仓库是**互补关系**，不是替代关系。OMCC 强在执行层（并行、韧性、多模型），本仓库强在质量层（审查、经验、纪律）。

---

## 八、行动建议

### 立即执行

1. ✅ 合并 ECC 上游 270 commits（基础能力对齐）
2. ✅ 新增 oh-my-claudecode、oh-my-openagent、ccg-workflow 到 `upstream-repos.json`
3. ✅ 安装 oh-my-claudecode 进行实际体验和功能验证

### 短期探索

4. 📋 评估 OMCC 的 ralph 循环是否可作为 ce:work 的增强模式
5. 📋 评估 OMCC 的 /learner 自动学习是否可融入 ce:compound
6. 📋 评估 CCG 的多模型安全架构（外部模型只返回 patch）

### 中长期方向

7. 🔮 意图分类层（参考 OMOC Intent Gate）
8. 🔮 跨模型调度（参考 CCG 三模型模式）
9. 🔮 持久执行循环（参考 OMCC ralph）
