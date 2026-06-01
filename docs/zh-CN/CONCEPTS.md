# 核心概念

## Skills vs Agents

这是 Claude Code 插件系统中最重要的概念区分。

### 对比表

| 特性 | Skills | Agents |
|------|--------|--------|
| **定义** | 知识/流程文档 | 可调度的子代理 |
| **位置** | `skills/` 目录 | `agents/` 目录 |
| **调用方式** | `skill: name` 或在 prompt 中引用 | `Task(agent-name)` |
| **执行者** | 当前代理读取并遵循 | 新的子代理独立执行 |
| **上下文** | 共享当前上下文 | 独立的新鲜上下文 |

### Skills（技能）

Skills 是**知识文档**，告诉 Claude 如何做某事。

```
skills/
├── brainstorming/SKILL.md       # 头脑风暴方法论
├── party-mode/SKILL.md          # 多代理讨论模式
├── systematic-debugging/SKILL.md # 系统化调试流程
└── test-driven-development/SKILL.md # TDD 方法论
```

**如何使用 Skill**：
```markdown
# 方式 1：直接引用
skill: brainstorming

# 方式 2：通过 general-purpose agent
Task(general-purpose): "使用 systematic-debugging skill 调试这个问题"
```

### Agents（代理）

Agents 是**可调度的子代理**，可以独立执行任务。

```
agents/
├── review/
│   ├── code-simplicity-reviewer.md
│   └── kieran-rails-reviewer.md
├── research/
│   └── best-practices-researcher.md
└── workflow/
    └── spec-flow-analyzer.md
```

**如何使用 Agent**：
```markdown
Task(code-simplicity-reviewer): "审查这段代码的复杂度"
Task(best-practices-researcher): "研究 Rails 认证最佳实践"
```

### 常见错误

```markdown
# 错误：把 skill 当 agent 调用
Task(systematic-debugging): "调试问题"  # ❌ systematic-debugging 是 skill

# 正确：通过 general-purpose 使用 skill
Task(general-purpose): "使用 systematic-debugging skill 调试问题"  # ✓
```

---

## Commands（命令）

Commands 是传统斜杠命令目录。上游新版已经把绝大多数用户入口迁移到 `skills/<name>/SKILL.md`，本 fork 也采用 **skill-first**：主工作流和 `ce:` 工具入口都由 skill frontmatter 暴露为斜杠入口。

```
skills/
├── ce-brainstorm/SKILL.md    # /ce:brainstorm
├── ce-plan/SKILL.md          # /ce:plan
├── ce-work/SKILL.md          # /ce:work
├── ce-review/SKILL.md        # /ce:review
├── ce-pr/SKILL.md            # /ce:pr
├── ce-doctor/SKILL.md        # /ce:doctor
└── ce-sync-upstream/SKILL.md # /ce:sync-upstream

commands/
├── codex.md                  # /codex（Claude Code only）
├── gemini.md                 # /gemini（Claude Code only）
└── slfg.md                   # /slfg
```

**命名规范**：
- 用户主入口使用 `ce:` 前缀避免与内置命令冲突
- Claude Code 有内置 `/plan`，所以我们用 `/ce:plan`
- 不要同时创建同名 `commands/ce/*.md` 和 `skills/ce-*/SKILL.md`，否则 Claude Code 补全会重复

---

## 组件关系图

```
用户输入
    │
    ▼
┌─────────────────────────────────────────┐
│  Commands（命令）                        │
│  /ce:plan, /ce:work       │
└─────────────────────────────────────────┘
    │                           │
    ▼                           ▼
┌───────────────┐       ┌───────────────┐
│ Skills        │       │ Agents        │
│ 知识文档       │       │ 子代理        │
│ 当前上下文     │       │ 新鲜上下文     │
└───────────────┘       └───────────────┘
```

---

## 相关文档

- [Skill vs Agent 调用问题](https://github.com/Jerrylalala/compound-engineering/blob/main/docs/solutions/integration-issues/skill-vs-agent-invocation.md)
- [安装与使用指南](INSTALL.md)
