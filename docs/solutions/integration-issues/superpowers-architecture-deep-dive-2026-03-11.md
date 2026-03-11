---
title: "Superpowers 插件架构深度分析"
category: integration-issues
tags: [superpowers, architecture, enforcement-mechanisms, skill-system, hooks, tdd, worktrees, yagni]
date_created: "2026-03-11"
status: reference
severity: low
module: research
symptoms:
  - "需要理解 Superpowers 的核心特性实现方式"
  - "分析强制 TDD、硬性检查点、YAGNI 原则的技术实现"
  - "评估移植难度和实现复杂度"
root_cause: "深入研究 obra/superpowers 的架构设计，为 CE 融合提供技术参考"
resolution_type: research
---

# Superpowers 插件架构深度分析

## Executive Summary

本文档深度分析 [obra/superpowers](https://github.com/obra/superpowers) 插件的核心架构和实现机制，重点关注以下 5 个特性：

1. **强制 TDD** - 测试未通过代码会被删除
2. **硬性检查点** - 无法跳过关键阶段
3. **YAGNI 原则** - 如何在代码中强制执行
4. **Git Worktrees 隔离** - 自动创建隔离环境、测试基线验证、清理/合并决策
5. **Socratic 设计细化** - 结构化提问引导需求

**核心发现**：Superpowers 的强制执行机制**不是通过代码实现的**，而是通过**精心设计的 Markdown 文档 + SessionStart hook 注入 + 三层优先级系统**实现的。

## 1. 强制 TDD 实现机制

### 1.1 核心原理

**DELETE 规则**：如果代码存在但没有配套测试，agent 被指示删除它。

**实现方式**：纯 Markdown 文档约束，不是代码强制。

**关键文件**：`skills/test-driven-development/SKILL.md`

**执行流程**：

```
1. 写失败测试 → 2. 验证失败 → 3. 最小实现 → 4. 重构
```

**验证门控**：使用 git worktrees 创建隔离环境，agent 必须证明代码在干净环境中工作。

### 1.2 "Iron Law"（铁律）

> **核心原则**：如果你没有观察到测试失败，你就不知道它测试的是对的东西。

**实施方式**：

- 在 `test-driven-development/SKILL.md` 中使用强语气（"Iron Law"、"MUST"、"NEVER"）
- 列出常见的合理化借口（"这太简单了不需要测试"）并明确拒绝
- 提供"当卡住时"表格，引导 agent 简化设计而非跳过测试

**示例表格**：

| 问题 | 解决方案 |
|------|---------|
| 不知道怎么测试 | 写理想 API。先写断言。问协作者。 |
| 测试太复杂 | 设计太复杂。简化接口。 |
| 必须 mock 所有东西 | 代码耦合太紧。使用依赖注入。 |
| 测试 setup 太庞大 | 提取辅助函数。还是复杂？简化设计。 |

### 1.3 实现复杂度

| 维度 | 评分 | 说明 |
|------|:---:|------|
| 代码复杂度 | 0/10 | 无代码，纯文档 |
| 文档复杂度 | 6/10 | 需要精心设计语言和反模式列表 |
| 移植难度 | 2/10 | 直接复制 Markdown 即可 |
| 维护成本 | 3/10 | 需要持续观察 agent 行为并关闭漏洞 |

**结论**：TDD 强制执行是通过**文档设计**而非代码实现的。移植成本极低。

## 2. 硬性检查点实现机制

### 2.1 核心原理

**HARD-GATE 语言**：在 `brainstorming/SKILL.md` 中使用明确的阻断语言：

```markdown
<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project,
or take any implementation action until you have presented a design and the
user has approved it.
</HARD-GATE>
```

**三阶段强制流程**：

```
brainstorming → writing-plans → implementation
```

每个阶段只有一个合法的退出点（调用下一个 skill）。

### 2.2 Subagent-Driven Development

**核心机制**：每个任务派发给一个新的 subagent，而非单个 Claude 实例管理整个功能。

**两阶段审查**：

1. **Spec 合规审查**：检查是否遗漏需求
2. **代码质量审查**：检查实现质量

**关键设计**：审查结果分为严重等级，critical 问题阻止进入下一个任务。

**实现方式**：

- `agents/code-reviewer.md` 定义审查 agent
- `skills/subagent-driven-development/SKILL.md` 定义派发协议
- 使用 `TodoWrite` 创建任务清单，强制按顺序完成

### 2.3 Status Protocol

**实现者 prompt 定义的状态码**：

- `DONE` - 任务完成
- `DONE_WITH_CONCERNS` - 完成但有疑虑
- `BLOCKED` - 阻塞
- `NEEDS_CONTEXT` - 需要更多上下文

**控制器 agent 根据状态码决定下一步**：

- `DONE` → 进入下一个任务
- `BLOCKED` → 停止并报告
- `DONE_WITH_CONCERNS` → 记录疑虑但继续

### 2.4 实现复杂度

| 维度 | 评分 | 说明 |
|------|:---:|------|
| 代码复杂度 | 0/10 | 无代码，纯文档 |
| 文档复杂度 | 8/10 | 需要设计 agent 协议和状态机 |
| 移植难度 | 5/10 | 需要理解 subagent 派发机制 |
| 维护成本 | 6/10 | 需要维护多个 agent prompt |

**结论**：硬性检查点通过 **HARD-GATE 语言 + subagent 派发 + 状态协议** 实现。移植需要理解 agent 系统。

## 3. YAGNI 原则强制执行

### 3.1 核心原理

**YAGNI 不是独立特性**，而是嵌入到多个 skill 中的设计原则。

**实施位置**：

1. **brainstorming skill**：在设计阶段就要求"YAGNI ruthlessly"
2. **receiving-code-review skill**：审查反馈时检查功能是否被使用
3. **writing-plans skill**：计划阶段避免过度设计

### 3.2 YAGNI 检查示例

在 `receiving-code-review/SKILL.md` 中提供的检查模板：

```bash
# 审查者建议"正确实施"某功能时
grep -r "function_name" . --include="*.rb"

IF 未使用: "此端点未被调用。删除它（YAGNI）？"
IF 使用: 则正确实施
```

### 3.3 何时推回审查建议

明确列出推回审查建议的场景：

- 建议会破坏现有功能
- 审查者缺少完整上下文
- **违反 YAGNI（未使用的功能）**
- 对当前技术栈不正确

### 3.4 实现复杂度

| 维度 | 评分 | 说明 |
|------|:---:|------|
| 代码复杂度 | 0/10 | 无代码，纯文档 |
| 文档复杂度 | 4/10 | 需要在多个 skill 中嵌入原则 |
| 移植难度 | 1/10 | 直接复制文档即可 |
| 维护成本 | 2/10 | 原则稳定，维护成本低 |

**结论**：YAGNI 通过**文档中的明确指令 + 检查示例**实现。移植成本极低。

## 4. Git Worktrees 隔离机制

### 4.1 核心原理

**目标**：为每个功能创建隔离的 git worktree，避免污染主分支。

**关键文件**：`skills/using-git-worktrees/SKILL.md`

### 4.2 工作流程

**1. 目录选择优先级**：

```
1. 检查现有 .worktrees 或 worktrees 目录
2. 查阅 CLAUDE.md 中的偏好设置
3. 询问用户
```

**2. 安全验证**：

创建项目本地 worktree 前，**必须验证目录已被 gitignore**。

**原因**：防止意外提交 worktree 内容到仓库。

**3. 自动设置**：

```bash
# 创建 worktree 后自动执行
1. 检测项目类型（Node.js/Rust/Python/Go）
2. 运行依赖安装（npm install / cargo build / pip install / go mod download）
3. 执行基线测试（确认干净起点）
```

**4. 基线测试验证**：

如果基线测试失败，**必须获得用户明确许可**才能继续。

### 4.3 清理/合并决策

**实现位置**：`skills/finishing-a-development-branch/SKILL.md`

**5 步流程**：

1. **验证测试**：运行完整测试套件，有失败则停止
2. **确认基础分支**：`git merge-base --fork-point main HEAD`
3. **呈现 4 个选项**：
   - 本地合并
   - 推送创建 PR
   - 保留现状
   - 丢弃
4. **执行选择**：本地合并时必须二次测试
5. **清理 Worktree**：仅在合并和丢弃时清理

**关键设计**：

- 使用 `AskUserQuestion` 呈现选项，避免假设用户意图
- 本地合并时强制二次测试（合并后可能引入冲突）
- 丢弃时要求输入 `discard` 确认，防止误操作

### 4.4 实现复杂度

| 维度 | 评分 | 说明 |
|------|:---:|------|
| 代码复杂度 | 0/10 | 无代码，纯 bash 命令 |
| 文档复杂度 | 7/10 | 需要设计完整的决策树 |
| 移植难度 | 3/10 | 需要理解 git worktree 命令 |
| 维护成本 | 4/10 | 需要维护多种项目类型的检测逻辑 |

**结论**：Worktrees 隔离通过**文档化的 bash 命令序列 + 决策树**实现。移植难度中等。

## 5. Socratic 设计细化机制

### 5.1 核心原理

**目标**：通过结构化提问引导用户细化需求，而非直接跳到实现。

**关键文件**：`skills/brainstorming/SKILL.md`

### 5.2 提问技术

**4 条原则**：

1. **多选优先**：当存在自然选项时，使用 `AskUserQuestion` 提供多选
2. **先宽后窄**：从目的和用户开始，逐渐收窄到约束和边缘案例
3. **显式验证假设**：不要隐含假设，说出来让用户确认或纠正
4. **早问成功标准**：尽早确定"什么算完成"

**一次一个问题**：

```markdown
Ask ONE question per message. Wait for answer before asking next.
```

**多选格式示例**：

```markdown
Which approach do you prefer?
A) Server-side rendering with caching
B) Client-side rendering with API
C) Hybrid approach
```

### 5.3 反模式表格

| 反模式 | 正确做法 |
|--------|---------|
| 一次提 5 个问题 | 一次一个，等待回答 |
| 跳到实现细节 | 保持在 WHAT 层面，HOW 留给 plan |
| 忽视现有代码库模式 | 先 repo 研究，再提问 |
| 不验证假设 | 显式说出假设让用户确认 |
| 过早收敛 | 保持开放直到用户说 "proceed" |
| 遗漏成功标准 | 第一轮就问"什么算完成" |

### 5.4 设计呈现格式

**分段呈现**：

- 简单项目：几句话
- 复杂项目：200-300 字/段

**覆盖内容**：

- 架构
- 组件
- 数据流
- 错误处理
- 测试

**增量验证**：

```markdown
Present design in sections. Request approval after EACH section.
Revise if rejected before proceeding.
```

### 5.5 实现复杂度

| 维度 | 评分 | 说明 |
|------|:---:|------|
| 代码复杂度 | 0/10 | 无代码，纯文档 |
| 文档复杂度 | 7/10 | 需要设计提问策略和反模式列表 |
| 移植难度 | 2/10 | 直接复制文档即可 |
| 维护成本 | 3/10 | 需要持续观察 agent 行为并补充反模式 |

**结论**：Socratic 设计细化通过**文档化的提问策略 + 反模式列表**实现。移植成本低。

## 6. 架构核心：Skills 系统

### 6.1 Dual Repository Design

**分离架构**：

- **Plugin Repository** (`obra/superpowers`)：平台集成、hooks、agents
- **Skills Repository** (`obra/superpowers-skills`)：平台无关的 skill 库

**同步机制**：

```bash
# 每次 session start 时自动执行
1. 首次运行：clone github.com/obra/superpowers-skills 到 ~/.config/superpowers/skills/
2. 后续运行：git fetch && git merge --ff-only
3. 分歧处理：警告用户需要手动同步
```

**优势**：

- 独立版本控制
- 透明更新（无需重装插件）
- 社区贡献友好
- 降低耦合

### 6.2 SessionStart Hook

**核心执行链**：

```
SessionStart 事件
→ hooks/session-start 脚本（同步执行）
→ lib/initialize-skills.sh
→ 注入 using-superpowers skill 到 session context
→ Agent 开始时已加载 skill-checking 协议
```

**关键配置** (`hooks/hooks.json`)：

```json
{
  "SessionStart": {
    "command": "hooks/session-start",
    "async": false
  }
}
```

**`async: false` 的重要性**：

确保 hook 在 agent 首次响应前执行完毕，防止 agent 在 skills 加载前行动。

### 6.3 Meta-Skill: using-superpowers

**1% 规则**：

```markdown
If even 1% chance a skill applies, you MUST invoke it.
```

**注入方式**：

直接注入到 session context（不需要工具调用）。

**内容包括**：

- 指令优先级层次（用户指令 > skills > 默认系统 prompt）
- 常见的合理化借口模式
- 明确的 skill-checking 协议

### 6.4 三层优先级系统

**Skill 发现优先级**：

1. **项目 skills** (`.superpowers/skills/`) - 最高优先级
2. **个人 skills** (`~/.claude/skills/` 或 `~/.agents/skills/`) - 中等优先级
3. **Superpowers skills** (`skills/` in repo) - 最低优先级

**用途**：

允许用户用项目特定的 skill 覆盖内置 skill。

### 6.5 Skill 结构

**每个 skill 是一个 `SKILL.md` 文件**：

```markdown
---
name: test-driven-development
description: Use when implementing new behavior or fixing bugs via tests-first
---

# Test-Driven Development

[Skill content...]
```

**Description 字段的重要性**：

- Agent 根据 description 匹配自然语言请求
- **Description = 何时使用，不是做什么**
- ✅ 好：`Use when executing implementation plans with independent tasks`
- ❌ 差：`Dispatches subagent per task with code review between tasks`

### 6.6 平台集成

**支持的平台**：

- **Claude Code / Cursor**：原生 `Skill` 工具，命名空间格式 `superpowers:skill-name`
- **OpenCode**：JavaScript 插件，`use_skill()` 自定义工具
- **Codex**：原生发现，通过 symlink 到 `~/.agents/skills/superpowers/`

## 7. 强制执行的本质

### 7.1 核心洞察

**Superpowers 的强制执行不是通过代码实现的**，而是通过：

1. **精心设计的 Markdown 文档**：使用强语气（Iron Law、HARD-GATE、MUST）
2. **SessionStart hook 注入**：确保 agent 在首次响应前加载 skills
3. **三层优先级系统**：允许覆盖但保持默认行为
4. **Meta-skill 1% 规则**：强制 agent 检查 skill 适用性
5. **反模式列表**：预先识别并拒绝常见的合理化借口

### 7.2 为什么这样有效？

**原理**：

> "非合规比合规更难"

**实施方式**：

- 将最佳实践设为默认路径
- 使用 HARD-GATE 语言阻断捷径
- 提供"当卡住时"表格引导正确方向
- 通过 subagent 派发限制单个 agent 的上下文

**对比传统 prompting**：

| 传统 Prompting | Superpowers |
|---------------|-------------|
| "请遵循 TDD" | "Iron Law: 如果你没有观察到测试失败..." |
| "建议先设计" | "HARD-GATE: Do NOT invoke any implementation skill..." |
| "考虑 YAGNI" | "grep -r function_name . → IF 未使用: 删除它" |

### 7.3 TDD for Skills 框架

**核心原则**：

> 如果你没有观察到 Agent 在没有该 Skill 时失败，你就不知道 Skill 教的是对的。

**RED-GREEN-REFACTOR 循环**：

| TDD 概念 | Skill 创建 |
|----------|-----------|
| 测试用例 | 子代理压力场景 |
| 生产代码 | SKILL.md 文档 |
| 测试失败（RED） | Agent 在没有 Skill 时违反规则 |
| 测试通过（GREEN） | Agent 在有 Skill 时遵守规则 |
| 重构 | 关闭漏洞，保持合规 |

**铁律**：

```
没有失败测试，就没有新 Skill
```

## 8. 移植难度评估

### 8.1 总体评分

| 特性 | 实现复杂度 | 移植难度 | 维护成本 | 推荐移植 |
|------|:----------:|:--------:|:--------:|:--------:|
| 强制 TDD | 0/10 | 2/10 | 3/10 | ✅ 是 |
| 硬性检查点 | 0/10 | 5/10 | 6/10 | ⚠️ 部分 |
| YAGNI 原则 | 0/10 | 1/10 | 2/10 | ✅ 是 |
| Git Worktrees | 0/10 | 3/10 | 4/10 | ✅ 是 |
| Socratic 设计 | 0/10 | 2/10 | 3/10 | ✅ 是 |

### 8.2 移植策略

**Wave 1：低成本高价值**（已完成）

- ✅ 验证门控函数（CLAUDE.md）
- ✅ finishing-a-feature skill
- ✅ receiving-code-review skill

**Wave 2：工作流细节**（已完成）

- ✅ TDD "当卡住时"表格
- ✅ Brainstorming 提问技术和反模式
- ✅ TDD for Skills 框架

**Wave 3：可选增强**（未实施）

- ⚠️ Subagent-driven development（CE 已有类似机制）
- ⚠️ Status Protocol（需要重新设计 agent 协议）

### 8.3 不推荐移植的部分

**1. Dual Repository Design**

- **原因**：CE 已有稳定的单仓库结构，拆分成本高
- **替代方案**：保持现有结构，通过 git submodule 管理外部 skills（如需要）

**2. 完整的 Subagent-Driven Development**

- **原因**：CE 已有 `workflows:work` 和 agent 系统，重复投资
- **替代方案**：增强现有 workflows，添加 STOP 协议和 finishing-a-feature 引用

## 9. 关键学习

### 9.1 文档即代码

**教训**：强制执行不需要代码，精心设计的文档就足够。

**应用**：

- 使用强语气（Iron Law、HARD-GATE、MUST）
- 列出反模式并明确拒绝
- 提供"当卡住时"表格引导正确方向

### 9.2 SessionStart Hook 的威力

**教训**：同步 hook 确保 agent 在首次响应前加载 skills。

**应用**：

- CE 已有 SessionStart hook 机制
- 确保 `async: false` 防止竞态条件

### 9.3 Meta-Skill 1% 规则

**教训**：通过 meta-skill 强制 agent 检查 skill 适用性。

**应用**：

- CE 的 `using-superpowers` 等效于 SP 的 meta-skill
- 在 CLAUDE.md 中明确指令优先级

### 9.4 TDD for Skills 框架

**教训**：编写 Skill 就是将 TDD 应用于流程文档。

**应用**：

- 每个新 Skill 必须有对应的"失败场景"记录
- 观察 Agent 在没有 Skill 时违反规则（RED）
- 编写 SKILL.md 文档（GREEN）
- 关闭漏洞，保持合规（REFACTOR）

### 9.5 Description 的正确写法

**教训**：Description = 何时使用，不是做什么。

**应用**：

- ✅ 好：`Use when executing implementation plans with independent tasks`
- ❌ 差：`Dispatches subagent per task with code review between tasks`

## 10. 相关文档

### 项目内文档

- **融合实施**：`docs/solutions/integration-issues/superpowers-fusion-code-review-2026-03-11.md`
- **Brainstorm**：`docs/brainstorms/2026-03-11-superpowers-fusion-brainstorm.md`
- **Plan**：`docs/plans/2026-03-11-feat-superpowers-fusion-plan.md`

### 外部参考

- **Superpowers 仓库**：https://github.com/obra/superpowers
- **Superpowers Skills 仓库**：https://github.com/obra/superpowers-skills
- **Superpowers 文档**：https://strapi.telesim.com/obra/superpowers
- **TDD 强制执行博客**：https://yuv.ai/blog/stop-ai-agents-from-writing-spaghetti-enforcing-tdd-with-superpowers
- **Subagent-Driven Development 博客**：https://richardporter.dev/blog/superpowers-plugin-claude-code-big-features

## Sources

- [obra/superpowers GitHub Repository](https://github.com/obra/superpowers)
- [obra/superpowers-skills GitHub Repository](https://github.com/obra/superpowers-skills)
- [Superpowers Documentation](https://strapi.telesim.com/obra/superpowers)
- [Stop AI Agents from Writing Spaghetti: Enforcing TDD with Superpowers](https://yuv.ai/blog/stop-ai-agents-from-writing-spaghetti-enforcing-tdd-with-superpowers)
- [Superpowers Plugin for Claude Code: How I Ship Big Features with Confidence](https://richardporter.dev/blog/superpowers-plugin-claude-code-big-features)
- [The Superpowers Framework: Structured Development for AI Coding Agents](https://betterstack.com/community/guides/ai/superpowers-framework/)
- [Brainstorming and Design](https://strapi.telesim.com/obra/superpowers/6.2-brainstorming-and-design)
- [Using Git Worktrees](https://strapi.telesim.com/obra/superpowers/6.3-using-git-worktrees)
- [Test-Driven Development](https://strapi.telesim.com/obra/superpowers/7.3-test-driven-development)
- [Complete Workflow Pipeline](https://strapi.telesim.com/obra/superpowers/6.1-complete-workflow-pipeline)
- [Directory Structure](https://strapi.telesim.com/obra/superpowers/10.1-directory-structure)
- [Dual Repository Design](https://strapi.telesim.com/obra/superpowers/4.1-dual-repository-design)
