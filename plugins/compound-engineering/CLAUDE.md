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
| 代码审查前 | `spec-compliance-review` → `/workflows:review` |
| 代码审查 + Codex | `/workflows:review [C]`（自动调用 Codex 额外审核） |
| 代码审查 + Gemini | `/workflows:review [G]`（自动调用 Gemini 额外审核） |
| 代码审查 + 双重验证 | `/workflows:review [C][G]`（同时调用 Codex 和 Gemini） |
| 需求不明确 | `/workflows:brainstorm` |
| 需要多视角讨论 | `party-mode`（在 brainstorm 中用 [P]） |
| 规划实现 | `/workflows:plan`（生成 Bite-Sized 任务格式） |
| 执行计划 | `/workflows:work`（自动选择执行模式） |
| 声称完成之前 | 完成前验证（见 CLAUDE.md） |
| 任务完成后收尾 | `finishing-a-feature`（测试验证 → 合并/PR 决策 → worktree 清理） |
| 收到审查反馈 | `receiving-code-review`（6 步响应 + 禁止表演性同意 + YAGNI 检查） |
| 记录解决方案（可选） | `/workflows:compound`（手动调用） |

### 技能分类（刚性 vs 柔性）

| 分类 | 含义 | 技能 |
|------|------|------|
| **刚性**（铁律） | 必须完整执行每个步骤，不可跳过或简化 | `systematic-debugging`、`test-driven-development`、`finishing-a-feature`、`receiving-code-review` |
| **柔性**（指导） | 必须调用，但可根据上下文调整执行深度 | `brainstorming`、`git-worktree`、`create-agent-skills`、其余技能 |

**区分标准**：
- 刚性技能 = 跳过会导致可观测的质量下降（如：不调试就猜原因、不测试就提交）
- 柔性技能 = 跳过不会立即出错，但长期降低效率

> **注意**：两种分类都必须通过技能检查协议（1% 规则不变）。区别仅在于执行弹性。

### `/workflows:work` 自动执行模式

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
├── workflows/  # Core workflow commands (workflows:plan, workflows:review, etc.)
└── *.md        # Utility commands

skills/
└── *.md        # All skills at root level
```

## Command Naming Convention

**Workflow commands** use `workflows:` prefix to avoid collisions with built-in commands.

**Why `workflows:`?** Claude Code has built-in `/plan` and `/review` commands. Using `name: workflows:plan` in frontmatter creates a unique `/workflows:plan` command with no collision.

### Workflow 命令

主命令使用 `workflows:` 前缀，避免与内置命令冲突。

| 命令 | 说明 |
|------|------|
| `/workflows:brainstorm` | 探索需求和方案 |
| `/workflows:plan` | 创建实施计划 |
| `/workflows:work` | 执行工作计划 |
| `/workflows:review` | 代码审查 |

**独立工具（手动调用）：**

| 命令 | 说明 |
|------|------|
| `/workflows:compound` | 记录解决方案（可选） |
| `/workflows:sync-upstream` | 检测上游更新 |
| `/workflows:pr` | 创建 PR |

**别名兼容**: 所有命令均有 `/ce:*` 别名（如 `/ce:plan` → `/workflows:plan`）

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
