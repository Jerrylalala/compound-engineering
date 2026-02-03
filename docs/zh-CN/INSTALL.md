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
| `/workflows:load` | 加载项目上下文，恢复之前的会话 | 开始新会话时 |
| `/workflows:brainstorm` | 探索需求和方案（支持 Party Mode） | 需求不清晰时 |
| `/workflows:plan` | 创建实施计划（Bite-Sized 格式） | 开始新功能前 |
| `/workflows:work` | 执行工作计划（自动选择执行模式） | 有计划文档后 |
| `/workflows:review` | 多代理代码评审 | 代码写完后 |
| `/workflows:compound` | 记录解决方案 | 问题解决后 |
| `/workflows:save` | 保存项目上下文，用于跨会话恢复 | 结束会话时 |

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
| **Marketplace**（推荐） | Claude Code 日常使用 | 通过 `/plugins` 更新 |
| **`--plugin-dir`** | 本地开发调试 | 修改文件后重启 |
| **CLI 转换** | Codex / Gemini 安装 | 重新运行命令 |

### 本地开发模式

```bash
claude --plugin-dir "完整路径\plugins\compound-engineering"
```

---

## Codex / Gemini CLI 安装

### 方式 1：本地转换（推荐）

```bash
# 进入仓库目录
cd F:\StudyFolder\StudyDest\project\compound-engineering-plugin-private

# 转换到 Codex
bun run src/index.ts install ./plugins/compound-engineering --to codex

# 转换到 Gemini（输出到当前目录）
bun run src/index.ts install ./plugins/compound-engineering --to gemini

# 指定 Gemini 输出目录
bun run src/index.ts install ./plugins/compound-engineering --to gemini --gemini-home "你的项目根目录"

# 同时转换多个目标
bun run src/index.ts install ./plugins/compound-engineering --to opencode --also codex,gemini
```

### 方式 2：从私有仓库远程安装

> **注意**：`COMPOUND_PLUGIN_GITHUB_SOURCE` 环境变量只影响 `@every-env/compound-plugin` 这个 CLI 工具，不会影响其他工具。建议**临时设置**，不要添加到永久环境变量。

**Windows PowerShell：**

```powershell
# 临时设置环境变量并安装
$env:COMPOUND_PLUGIN_GITHUB_SOURCE="https://github.com/Jerrylalala/compound-engineering-plugin-private"
bunx @every-env/compound-plugin install compound-engineering --to gemini
bunx @every-env/compound-plugin install compound-engineering --to codex
```

**Linux/macOS：**

```bash
# 一行命令（临时设置）
COMPOUND_PLUGIN_GITHUB_SOURCE=https://github.com/Jerrylalala/compound-engineering-plugin-private \
  bunx @every-env/compound-plugin install compound-engineering --to gemini
```

### 输出位置

| 目标 | 输出位置 | 说明 |
|------|---------|------|
| OpenCode | `~/.config/opencode/` | 全局配置 |
| Codex | `~/.codex/prompts/` 和 `~/.codex/skills/` | 全局配置 |
| Gemini | `<当前目录>/.gemini/GEMINI.md` | 项目级配置 |

### 可选参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--to` | 目标格式 | `opencode` / `codex` / `gemini` |
| `--also` | 额外目标（逗号分隔） | `--also codex,gemini` |
| `--output` | OpenCode 输出目录 | `--output ~/my-project` |
| `--codex-home` | Codex 输出目录 | `--codex-home ~/.codex` |
| `--gemini-home` | Gemini 输出目录 | `--gemini-home ~/my-project` |

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

