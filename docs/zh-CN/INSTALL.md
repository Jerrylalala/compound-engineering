# Compound Engineering 安装与使用指南

## 快速开始

**通过 Marketplace 从 GitHub 安装：**

```
/plugins
# 选择 Add marketplace
# 输入：Jerrylalala/compound-engineering
# 选择安装插件
```

### 更新插件后同步到 Codex / Gemini

插件更新后，需要手动同步到其他 CLI 工具：

```
把这个仓库同步到 codex 和 gemini 中
```

然后依次执行：

1. **更新插件市场** — 在 Claude Code 中运行 `/plugins`，选择 marketplace `jerry-marketplace` 进行更新
2. **重新安装插件** — 进入插件列表，更新 `compound-engineering`（会重新克隆仓库）

---

### 故障排除

<details>
<summary><b>插件更新后不生效</b></summary>

清除缓存后重新安装：

1. `/plugins` → 选 marketplace → **Remove marketplace**
2. 重新 **Add marketplace**，输入：`Jerrylalala/compound-engineering`
3. Claude Code 会用 HTTPS 重新克隆仓库
4. **重启 Claude Code**

</details>

<details>
<summary><b>安装报错（残留临时文件）</b></summary>

可能是上次安装失败残留的临时文件（如 `temp_local_*`），手动清除后重试：

```powershell
# 第一步：删除残留临时文件和旧缓存
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\plugins\cache\temp_local_*"
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\plugins\cache\jerry-marketplace"

# 第二步：重新进入 /plugins，更新 marketplace 并重新安装插件
```

</details>

---

## 核心工作流

```
Brainstorm → Plan → Work → Review → Compound → Repeat
    ↓          ↓       ↓        ↓         ↓
  探索需求   规划方案  执行开发  代码评审  记录经验
```

### 工作流命令

| 命令                       | 说明                              | 何时使用     |
| -------------------------- | --------------------------------- | ------------ |
| `/ce:brainstorm`    | 探索需求和方案（支持 Party Mode） | 需求不清晰时 |
| `/ce:plan`          | 创建实施计划（Bite-Sized 格式）   | 开始新功能前 |
| `/ce:work`          | 执行工作计划（自动选择执行模式）  | 有计划文档后 |
| `/ce:review`        | 多代理代码评审                    | 代码写完后   |
| `/ce:compound`      | 记录解决方案                      | 问题解决后   |
| `/ce:sync-upstream` | 检测上游仓库更新，生成分析报告    | 定期同步时   |

### 自动执行模式（v2.32.0 新增）

`/ce:work` 会根据任务数量自动选择执行模式：

| 任务数量 | 执行模式        | 说明                        |
| -------- | --------------- | --------------------------- |
| 1        | 标准模式        | 单代理直接执行              |
| ≥2       | Subagent-Driven | 每任务新子代理 + 两阶段审查 |

**Subagent-Driven 模式特点**：
- 每个任务派遣新的子代理（避免上下文污染）
- 两阶段审查：规范合规 → 代码质量
- 每 3 个任务设置人工检查点

### 辅助命令

| 命令           | 说明                 |
| -------------- | -------------------- |
| `/deepen-plan` | 增强计划（并行研究） |
| `/plan_review` | 计划评审             |
| `/lfg`         | 全自动工程流程       |
| `/glue-coding` | 胶水编程架构规划     |

---

## 典型使用场景

### 场景 1：新功能开发

```
1. /ce:brainstorm 探索用户登录功能
   ↓ 输出决策文档
2. /ce:plan 用户登录功能
   ↓ 输出计划文档
3. /ce:work docs/plans/xxx-plan.md
   ↓ 开发、测试、提交
4. /ce:review [PR号]
   ↓ 评审、修复
5. /ce:compound
   ↓ 记录经验
```

### 场景 2：快速 Bug 修复

```
1. 描述 Bug（跳过 brainstorm）
2. /ce:plan 修复登录页报错
3. /ce:work
4. /ce:compound（可选）
```

### 场景 3：新项目架构

```
1. /glue-coding 我要做一个博客系统
   ↓ 完整技术选型 + 开源库推荐
2. /ce:plan 博客系统基础架构
3. /ce:work
```

---

## 经验库系统（v2.36.0 新增）

### 双层经验库

| 目录                     | 范围 | 说明                                      |
| ------------------------ | ---- | ----------------------------------------- |
| `~/.compound/solutions/` | 全局 | 跨项目、跨工具共享（Claude/Codex/Gemini） |
| `docs/solutions/`        | 项目 | 项目特定经验                              |

### 路径优先级

```
1. COMPOUND_SOLUTIONS_HOME（环境变量，可选）
2. ~/.compound/solutions/（全局默认）
3. docs/solutions/（项目回退）
```

### 跨平台支持

| 平台        | 全局路径                             |
| ----------- | ------------------------------------ |
| Windows     | `%USERPROFILE%\.compound\solutions\` |
| macOS/Linux | `$HOME/.compound/solutions/`         |

### 自动化

- **首次运行** `/ce:compound` 时自动创建目录和配置
- **搜索**：`/ce:plan` 自动搜索两个目录
- **记录**：`/ce:compound` 自动判断写入位置

---

## 文件输出位置

```
~/.compound/
└── solutions/            # 全局经验（跨项目）

docs/
├── brainstorms/          # Brainstorm 输出
│   └── YYYY-MM-DD-<topic>-brainstorm.md
├── plans/                # Plan 输出
│   └── YYYY-MM-DD-<type>-<name>-plan.md
├── sync-reports/         # Sync-Upstream 输出
│   ├── upstream-repos.json
│   └── YYYY-MM-DD-upstream-sync.md
├── solutions/            # 项目经验（Compound 输出）
│   ├── build-errors/
│   ├── test-failures/
│   └── ...
└── architecture/         # 架构文档
    └── YYYY-MM-DD-<project>-glue-plan.md
```

---

## 安装方式对比

| 方式                    | 适用场景             | 更新方式             |
| ----------------------- | -------------------- | -------------------- |
| **Marketplace**（推荐） | Claude Code 日常使用 | 通过 `/plugins` 更新 |
| **`--plugin-dir`**      | 本地开发调试         | 修改文件后重启       |
| **CLI 转换**            | Codex / Gemini 安装  | 重新运行命令         |

### 本地开发模式

```bash
claude --plugin-dir "完整路径\plugins\compound-engineering"
```

---

## Codex / Gemini CLI 安装

### 方式 1：本地转换（推荐）

```bash
# 进入仓库目录
cd /path/to/compound-engineering

# 转换到 Codex
bun run src/index.ts install ./plugins/compound-engineering --to codex

# 转换到 Gemini（输出到当前目录）
bun run src/index.ts install ./plugins/compound-engineering --to gemini

# 指定 Gemini 输出目录
bun run src/index.ts install ./plugins/compound-engineering --to gemini --gemini-home "你的项目根目录"

# 同时转换多个目标
bun run src/index.ts install ./plugins/compound-engineering --to opencode --also codex,gemini
```

### 方式 2：从当前公共仓库远程安装

> **注意**：当前 npm 上已发布的是 `@every-env/compound-plugin`。`@jerry-jian/compound-plugin` 发布前，请使用 `COMPOUND_PLUGIN_GITHUB_SOURCE` 显式指向本公共仓库。

**Windows PowerShell：**

```powershell
$env:COMPOUND_PLUGIN_GITHUB_SOURCE="https://github.com/Jerrylalala/compound-engineering"
bunx @every-env/compound-plugin install compound-engineering --to gemini
bunx @every-env/compound-plugin install compound-engineering --to codex
```

**Linux/macOS：**

```bash
COMPOUND_PLUGIN_GITHUB_SOURCE=https://github.com/Jerrylalala/compound-engineering \
  bunx @every-env/compound-plugin install compound-engineering --to gemini
```

### 输出位置

| 目标     | 输出位置                                  | 说明       |
| -------- | ----------------------------------------- | ---------- |
| OpenCode | `~/.config/opencode/`                     | 全局配置   |
| Codex    | `~/.codex/prompts/` 和 `~/.codex/skills/` | 全局配置   |
| Gemini   | `<当前目录>/.gemini/GEMINI.md`            | 项目级配置 |

### 可选参数

| 参数            | 说明                 | 示例                            |
| --------------- | -------------------- | ------------------------------- |
| `--to`          | 目标格式             | `opencode` / `codex` / `gemini` |
| `--also`        | 额外目标（逗号分隔） | `--also codex,gemini`           |
| `--output`      | OpenCode 输出目录    | `--output ~/my-project`         |
| `--codex-home`  | Codex 输出目录       | `--codex-home ~/.codex`         |
| `--gemini-home` | Gemini 输出目录      | `--gemini-home ~/my-project`    |

---

## MCP 服务器

本插件自带 **Context7** MCP 服务器，用于获取最新库文档。

### 推荐额外安装的 MCP（需全局安装）

| MCP        | 安装命令                                                                    | 用途     |
| ---------- | --------------------------------------------------------------------------- | -------- |
| **GitHub** | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` | 搜索仓库 |

安装后通过 `/mcp` 命令进行认证。

---

## Claude Code 扩展系统

| 类型         | 存放位置            | 调用方式        |
| ------------ | ------------------- | --------------- |
| **独立技能** | `~/.claude/skills/` | 直接名称        |
| **插件技能** | 插件内 `skills/`    | `插件名:技能名` |
| **插件命令** | 插件内 `commands/`  | 斜杠命令        |

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

