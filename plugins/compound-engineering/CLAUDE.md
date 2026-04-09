# Compounding Engineering Plugin

## 设计哲学

本插件是编排层：Skills、Agents、Commands 组合现有工具（Claude Code、git、GitHub CLI、Codex、Gemini、Context7）。详见 `/glue-coding` 技能。

## 技能检查协议（每次会话自动生效）

**铁律：如果有技能可能适用于你的任务，你必须使用它。**

这不是可选的。这不是可协商的。你不能合理化跳过这个。

### 检查流程

```
收到用户消息
    ↓
有任何技能可能适用吗？（哪怕 1% 的可能）
    ↓
是 → 调用技能 → 宣布「使用 [技能] 来 [目的]」→ 遵循技能
否 → 正常响应
```

### 宣告格式规范

调用技能时，使用统一格式主动宣告：

**格式**：`使用 [技能名] 来 [具体目的]`

**示例**：
| 场景 | 宣告 |
|------|------|
| 遇到测试失败 | "使用 `systematic-debugging` 来定位测试失败的根因" |
| 开始新功能 | "使用 `test-driven-development` 来实现用户认证" |
| 收到审查反馈 | "使用 `receiving-code-review` 来处理审查反馈" |
| 功能完成收尾 | "使用 `finishing-a-feature` 来完成分支收尾" |

> 宣告的目的是透明度 — 让用户知道 AI 正在使用哪个技能指导行为。

### 危险信号 - 这些想法意味着停下来

| 想法 | 现实 |
|------|------|
| 「这只是个简单问题」 | 问题也是任务。检查技能。 |
| 「技能太重了」 | 简单事情会变复杂。使用它。 |
| 「我先做这一件事」 | 做任何事之前先检查。 |

### 可用技能（按场景）

| 场景 | 推荐技能 |
|------|----------|
| 遇到 bug / 测试失败 | `systematic-debugging` |
| 实现新功能 | `test-driven-development` |
| 代码审查前 | `spec-compliance-review` → `/ce:review` |
| 代码审查 + Codex | `/ce:review [C]`（自动调用 Codex 额外审核） |
| 代码审查 + Gemini | `/ce:review [G]`（自动调用 Gemini 额外审核） |
| 代码审查 + 双重验证 | `/ce:review [C][G]`（同时调用 Codex 和 Gemini） |
| 需求不明确 | `/ce:brainstorm` |
| 需要多视角讨论 | `party-mode`（在 brainstorm 中用 [P]） |
| 规划实现 | `/ce:plan`（生成 Bite-Sized 任务格式） |
| 执行计划 | `/ce:work`（自动选择执行模式） |
| 声称完成之前 | 完成前验证（见 CLAUDE.md） |
| 任务完成后收尾 | `finishing-a-feature`（测试验证 → 合并/PR 决策 → worktree 清理） |
| 收到审查反馈 | `receiving-code-review`（6 步响应 + 禁止表演性同意 + YAGNI 检查） |
| 记录解决方案（可选） | `/ce:compound`（手动调用） |

### Overlay 技能触发时机

以下私有 overlay 技能需**手动加载**，不会自动触发：

| 触发场景 | 加载技能 |
|----------|----------|
| 执行 `ce:work`，任务有 Task Bundle | `ce-work-integration`（启用持久化状态跟踪）|
| 执行 `ce:work`，处理 bare prompt 时分类意图 | `intent-gate`（意图分类路由）|
| 调用 `codex exec` 执行任务 | `executor-capability-gate` + `codex-first-executor`（Codex 路由决策）|
| 完成 `ce:compound` 后，评估是否升级经验 | `compound-promotion-ladder`（经验分层沉淀）|
| 做 UI 相关代码审查 | `ui-review-contract`（UI 审查 Tier 分类）|
| 做代码审查，需严格分类 | `review-contract`（三档 Tier 分类框架）|

### 技能分类（刚性 vs 柔性）

| 分类 | 含义 | 技能 |
|------|------|------|
| **刚性**（铁律） | 必须完整执行每个步骤，不可跳过或简化 | `systematic-debugging`、`test-driven-development`、`finishing-a-feature`、`receiving-code-review` |
| **柔性**（指导） | 必须调用，但可根据上下文调整执行深度 | `brainstorming`、`git-worktree`、`create-agent-skills`、其余技能 |

**区分标准**：
- 刚性技能 = 跳过会导致可观测的质量下降（如：不调试就猜原因、不测试就提交）
- 柔性技能 = 跳过不会立即出错，但长期降低效率

> **注意**：两种分类都必须通过技能检查协议（1% 规则不变）。区别仅在于执行弹性。

### `/ce:work` 自动执行模式

```
任务数量 = 1  → 标准模式（单代理执行）
任务数量 ≥ 2 → Subagent-Driven 模式（自动启用）
                ├─ 每任务新子代理（避免上下文污染）
                ├─ 两阶段审查（spec-compliance-review → 代码质量）
                └─ 批量 3 任务 + 人工检查点
```

### 技能优先级

当多个技能可能适用时，使用此顺序：

1. **流程技能优先**（brainstorming, debugging）- 这些决定如何处理任务
2. **实现技能其次**（TDD, spec-review）- 这些指导执行

「让我们构建 X」→ 先 brainstorming，再实现技能。
「修复这个 bug」→ 先 debugging，再领域特定技能。

---

## Agent Teams 集成

**Claude Code Teammates 功能**：在 Claude Code 设置中开启 "Agent Teams" / "Teammates" 实验性功能后，`ce:work` 会在任务数量 ≥10 时自动启用 Swarm 模式。

| 启用方式 | 说明 |
|---------|------|
| Claude Code 设置 → 开启 Teammates | 平台层功能，一次性配置 |
| 自动触发 | `ce:work` 检测到 ≥10 个任务时自动路由到 Swarm |
| 手动触发 | 在 `ce:work` 中说「启用 swarm」或「use swarm mode」 |

**Swarm 模式特点**：
- 每个子任务由独立的 Teammate 实例执行（真正的并行）
- Teammate 之间互相验证输出，减少单点失误
- 相比 `parallel-subagents` 模式，Teammates 有独立上下文窗口

**与插件的关系**：Agent Teams 是 Claude Code 平台能力，本插件通过 `ce:work` 的任务路由策略自动利用它，用户无需手动选择。

---

# Plugin Development

## Versioning Requirements

> **详细规范**：见 [版本管理规范](../../docs/development/VERSIONING.md)

**快速检查**：
```powershell
powershell -ExecutionPolicy Bypass -File ../../scripts/check-versions.ps1
```

**快速更新**：
```powershell
powershell -ExecutionPolicy Bypass -File ../../scripts/bump-version.ps1 -BumpType patch
```

### Directory Structure

```
agents/
├── review/     # Code review agents
├── research/   # Research and analysis agents
├── design/     # Design and UI agents
├── workflow/   # Workflow automation agents
└── docs/       # Documentation agents

commands/
├── workflows/  # 独立工具命令（doctor, pr, sync-upstream）
└── *.md        # 工具命令（gemini, codex 等）

skills/
└── *.md        # All skills at root level
```

## Command Naming Convention

**主工作流通过 Skills 提供**，使用 `ce:` 前缀（如 `/ce:brainstorm`）。

**Why `ce:`?** Claude Code 有内置 `/plan` 和 `/review` 命令。Skills 使用 `name: ce:plan` 创建不冲突的 `/ce:plan` 调用路径。

### 主工作流 Skills（用 `ce:` 调用）

| 命令 | 说明 |
|------|------|
| `/ce:brainstorm` | 探索需求和方案 `[P][C][G][R][team]` |
| `/ce:plan` | 创建实施计划 `[team]` |
| `/ce:work` | 执行工作计划 `[team][team:full][R][T=四层自验证][PW=Playwright浏览器][C=Codex参与标记][G=Gemini参与标记]` |
| `/ce:review` | 代码审查 `[mode:autofix] [C][G][team]` |

**独立工具命令（手动调用）：**

| 命令 | 说明 |
|------|------|
| `/ce:compound` | 记录解决方案（可选） |
| `/workflows:sync-upstream` | 检测上游更新 |
| `/workflows:pr` | 创建 PR |
| `/workflows:doctor` | 健康检查 |

### `[team]` 参数说明

多代理协作稳定性框架。核心机制：合约白名单 + 单写者原则 + 事件驱动验证前移。

| 参数 | 阶段 | 效果 |
|------|------|------|
| `[team]` | ce:brainstorm | 探索者 + 挑战者结构化验证角色对 |
| `[team]` | ce:plan | 合约主 + 追溯审查，自动生成 `.team-contract.md` |
| `[team]` | ce:work | 3角色默认（合约主+执行者+验证者），每任务后运行验证者 Hook |
| `[team:full]` | ce:work | 4角色（加风险卫），适合 auth/payment/migration 高风险路径 |
| `[team]` | ce:review | autofix 路径增加 Deterministic Patch Gate（规则引擎，不耗额外 token） |

**使用流程**：
```bash
/ce:plan [team]           # 生成计划 + .team-contract.md
/ce:work [team]           # 执行（合约边界保护 + 验证者 Hook）
/ce:review mode:autofix [team]  # autofix 受合约白名单门控
```

加载 `team-mode` skill 查看完整角色定义和行为规则。

### 序号格式规范

> ⚠️ 避免使用 Unicode 特殊字符（①②③），在某些终端显示异常。

```yaml
# 正确
description: "Step X: 描述内容"

# 错误
description: ① 描述内容
```

新增 workflow 命令时，按顺序分配 Step 编号。

### Workflow Handoff 协议（铁律）

所有 `commands/workflows/*.md` 命令必须遵循（终端命令 save/doctor 除外）。

#### 协议分级

| 档位 | 适用命令 | 规则要求 |
|------|----------|----------|
| **主链档** | brainstorm, plan, work, review, compound | 6 条全满足 |
| **工具档** | load, sync-upstream, deepen-plan, plan_review | 至少满足规则 2/4/5 |

#### 6 条规则

1. 命令的最后一个 Phase 必须是 Handoff（主链档严格，工具档宽松）
2. Handoff 必须使用 **AskUserQuestion tool** 呈现选项 ✅ 必须
3. 第一个选项必须是流程中的下一步命令（含完整参数如文件路径）（主链档严格，工具档宽松）
4. 必须有"跳过/停止"选项 ✅ 必须
5. Handoff 后需 `Based on selection:` 内嵌行为约束（禁止 AI 在选项外自由发挥）✅ 必须
6. 选项描述使用中文，命令名保持英文（主链档严格，工具档宽松）

**流程链路**：
```
brainstorm → plan → [deepen-plan] → [plan_review] → work → review
```

**可选工具（手动调用）**：
- `/workflows:compound` - 记录解决方案
- `/workflows:sync-upstream` - 检测上游更新
- `/workflows:pr` - 创建 PR

**快速验证**：
```bash
bash scripts/check-handoff.sh
```

**检查清单**（新增/修改 workflow 命令时验证）：
- [ ] 最后一个 Phase 是否为 Handoff？
- [ ] 是否使用 AskUserQuestion？
- [ ] 第一个选项是否为流程中的下一步命令 + 完整路径？
- [ ] 是否有"停止"选项？
- [ ] 是否有 `Based on selection:` 行为约束？
- [ ] 描述语言是否为中文？

## Command Frontmatter 参考

### `claude-code-only: true`

标记命令仅在 Claude Code 中可用。转换到 Codex/Gemini 格式时，标记为 `claude-code-only` 的命令会被自动跳过。

适用于依赖 Claude Code 特有能力（如 Bash 工具、对话上下文分析）的命令，例如 `/gemini`、`/codex`。

```yaml
---
name: gemini
description: 向 Gemini 寻求更优方案
claude-code-only: true
---
```

## Documentation

- [版本管理规范](../../docs/development/VERSIONING.md)
- [脚本使用说明](../../docs/zh-CN/SCRIPTS.md)
- [核心概念](../../docs/zh-CN/CONCEPTS.md)
- [Skill 开发规范](../../docs/development/SKILL-DEVELOPMENT.md)（Skill Compliance Checklist 已移至此处）
