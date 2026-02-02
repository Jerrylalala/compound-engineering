# Compound Engineering 安装与使用指南

## 快速开始

**通过 Marketplace 从 GitHub 安装：**

```
/plugins
# 选择 Add marketplace
# 输入：Jerrylalala/compound-engineering-plugin-private
# 选择安装插件
```

安装后重启 Claude Code 即可使用。

---

## 核心工作流

```
Brainstorm → Plan → Work → Review → Compound → Repeat
    ↓          ↓       ↓        ↓         ↓
  探索需求   规划方案  执行开发  代码评审  记录经验
```

### 工作流命令

| 命令 | 说明 | 何时使用 |
|------|------|---------|
| `/workflows:brainstorm` | 探索需求和方案（支持 Party Mode） | 需求不清晰时 |
| `/workflows:plan` | 创建实施计划（Bite-Sized 格式） | 开始新功能前 |
| `/workflows:work` | 执行工作计划（自动选择执行模式） | 有计划文档后 |
| `/workflows:review` | 多代理代码评审 | 代码写完后 |
| `/workflows:compound` | 记录解决方案 | 问题解决后 |

### 自动执行模式（v2.32.0 新增）

`/workflows:work` 会根据任务数量自动选择执行模式：

| 任务数量 | 执行模式 | 说明 |
|---------|---------|------|
| 1 | 标准模式 | 单代理直接执行 |
| ≥2 | Subagent-Driven | 每任务新子代理 + 两阶段审查 |

**Subagent-Driven 模式特点**：
- 每个任务派遣新的子代理（避免上下文污染）
- 两阶段审查：规范合规 → 代码质量
- 每 3 个任务设置人工检查点

### 辅助命令

| 命令 | 说明 |
|------|------|
| `/deepen-plan` | 增强计划（并行研究） |
| `/plan_review` | 计划评审 |
| `/lfg` | 全自动工程流程 |
| `/glue-coding` | 胶水编程架构规划 |

---

## 典型使用场景

### 场景 1：新功能开发

```
1. /workflows:brainstorm 探索用户登录功能
   ↓ 输出决策文档
2. /workflows:plan 用户登录功能
   ↓ 输出计划文档
3. /workflows:work docs/plans/xxx-plan.md
   ↓ 开发、测试、提交
4. /workflows:review [PR号]
   ↓ 评审、修复
5. /workflows:compound
   ↓ 记录经验
```

### 场景 2：快速 Bug 修复

```
1. 描述 Bug（跳过 brainstorm）
2. /workflows:plan 修复登录页报错
3. /workflows:work
4. /workflows:compound（可选）
```

### 场景 3：新项目架构

```
1. /glue-coding 我要做一个博客系统
   ↓ 完整技术选型 + 开源库推荐
2. /workflows:plan 博客系统基础架构
3. /workflows:work
```

---

## 文件输出位置

```
docs/
├── brainstorms/          # Brainstorm 输出
│   └── YYYY-MM-DD-<topic>-brainstorm.md
├── plans/                # Plan 输出
│   └── YYYY-MM-DD-<type>-<name>-plan.md
├── solutions/            # Compound 输出
│   ├── build-errors/
│   ├── test-failures/
│   └── ...
└── architecture/         # 架构文档
    └── YYYY-MM-DD-<project>-glue-plan.md
```

---

## 安装方式对比

| 方式 | 适用场景 | 更新方式 |
|------|---------|---------|
| **Marketplace**（推荐） | 日常使用 | 通过 `/plugins` 更新 |
| **`--plugin-dir`** | 开发调试 | 修改文件后重启 |

### 本地开发模式

```bash
claude --plugin-dir "完整路径\plugins\compound-engineering"
```

---

## MCP 服务器

本插件自带 **Context7** MCP 服务器，用于获取最新库文档。

### 推荐额外安装的 MCP（需全局安装）

| MCP | 安装命令 | 用途 |
|-----|---------|------|
| **GitHub** | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` | 搜索仓库 |

安装后通过 `/mcp` 命令进行认证。

---

## Claude Code 扩展系统

| 类型 | 存放位置 | 调用方式 |
|------|---------|---------|
| **独立技能** | `~/.claude/skills/` | 直接名称 |
| **插件技能** | 插件内 `skills/` | `插件名:技能名` |
| **插件命令** | 插件内 `commands/` | 斜杠命令 |

---

## 常见问题

### Q：如何查看插件的所有命令？

```
/help
```

或查看项目的 `commands/` 目录。

### Q：修改插件后怎么生效？

- **Marketplace 安装**：重新安装或等待自动更新
- **`--plugin-dir`**：重启 Claude Code

### Q：SSH 认证失败怎么办？

```bash
# 检查 SSH 密钥
ssh -T git@github.com

# 或改用本地开发模式
claude --plugin-dir "本地路径\plugins\compound-engineering"
```

---

## 参考资料

- [Create plugins - Claude Code Docs](https://code.claude.com/docs/en/plugins)
- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp)
