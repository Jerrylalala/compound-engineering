# Compound Engineering Plugin（私有镜像）

> **重要**：这是 `EveryInc/compound-engineering-plugin` 的私有镜像仓库。

## AI 助手快速入门

### 仓库定位

```
本仓库 = 上游镜像 + 中文化层 + 本地扩展
```

| 角色         | 仓库                                            | 说明                 |
| ------------ | ----------------------------------------------- | -------------------- |
| **upstream** | EveryInc/compound-engineering-plugin            | 上游原始仓库（只读） |
| **origin**   | Jerrylalala/compound-engineering-plugin-private | 用户的私有仓库       |

### 核心原则

1. **可修改所有文件** - 英文文档和中文文档都可以修改
2. **本地扩展隔离** - `skills-custom/` 存放自定义技能
3. **同步上游时注意冲突** - 见 `docs/zh-CN/SYNC.md`

### AI 助手行为规范

**开始工作前检查历史经验**：在修复 bug 或实现功能前，搜索经验库：
```bash
# 搜索全局经验（跨项目）
Grep pattern="关键词" path=~/.compound/solutions/ output_mode=files_with_matches

# 搜索项目经验
Grep pattern="关键词" path=docs/solutions/ output_mode=files_with_matches
```
或直接使用 `/workflows:plan`，它会自动搜索两个目录。

**完成前验证（铁律）**：声明任何工作完成之前，必须有新鲜的验证证据。

```
在声明任何状态或表达满意之前：

1. 识别：什么命令能证明这个声明？
2. 运行：执行完整命令（新鲜的，完整的）
3. 阅读：完整输出，检查退出码，统计失败数
4. 验证：输出是否确认声明？
   - 否 → 陈述实际状态并附证据
   - 是 → 陈述声明并附证据
5. 然后才能：做出声明

跳过任何步骤 = 虚假声明，不是验证
```

| 声明 | 需要 | 不充分 |
|------|------|--------|
| 测试通过 | 测试命令输出：0 失败 | 之前的运行、「应该通过」 |
| 构建成功 | 构建命令：exit 0 | lint 通过、日志看起来正常 |
| Bug 已修复 | 测试原始症状：通过 | 代码改了、假设修好了 |
| 需求满足 | 逐行清单验证 | 测试通过 |

**验证模式**：

| 模式 | 适用场景 | 执行方式 |
|------|----------|----------|
| **Agent 委派验证** | 复杂验证、多文件检查、需要推理 | 创建专门的验证 agent，输入：待验证声明 + 证据要求，输出：通过/失败 + 证据 |
| **TDD 红绿循环验证** | 功能开发、Bug 修复 | 先写失败测试 → 实现 → 测试通过 → 重构（可选）→ 再次验证 |

**危险信号 - 停下来**：
- 使用「应该」「可能」「似乎」
- 在验证前表达满意（「太好了！」「完成！」）
- 准备提交/推送/PR 但没验证
- 想着「就这一次」

**功能完成后必须询问**：当完成用户请求的功能后，必须询问用户是否要推送到 Git：
> "功能已完成。要推送到 Git 吗？"

**Git 提交使用中文**：commit message 使用中文书写。

**新功能/修改必须更新文档（铁律）**：

> 添加新功能或修改现有功能时，**必须同步更新相关文档**，否则不算完成。

| 修改类型 | 必须更新的文档 |
|----------|----------------|
| 新功能 | CHANGELOG.md、版本号、INSTALL.md（如需要） |
| 修改命令/agent | CHANGELOG.md、版本号 |
| 修改工作流 | CHANGELOG.md、版本号、WORKFLOW-VISUAL.md |
| Bug 修复 | CHANGELOG.md、版本号（如重要） |

**版本号位置（必须同步）：**
- `.claude-plugin/marketplace.json` → `plugins[0].version`
- `plugins/compound-engineering/.claude-plugin/plugin.json` → `version`

**快速检查命令：**
```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

### 当前组件统计

| 组件        | 数量 | 位置                                     |
| ----------- | ---- | ---------------------------------------- |
| Agents      | 29   | `plugins/compound-engineering/agents/`   |
| Commands    | 43   | `plugins/compound-engineering/commands/` |
| Skills      | 26   | `plugins/compound-engineering/skills/`   |
| MCP Servers | 1    | Context7（HTTP 服务）                    |

### 安装方式

**推荐：通过 Marketplace 从 GitHub 安装**

```
/plugins → Add marketplace → Jerrylalala/compound-engineering-plugin-private
```

**本地开发：**

```bash
claude --plugin-dir "完整路径\plugins\compound-engineering"
```

---

## 目录结构

```
compound-engineering-plugin-private/
├── .claude-plugin/
│   └── marketplace.json
├── docs/
│   └── zh-CN/                        # 📌 中文文档
│       ├── INSTALL.md                # 安装与使用指南
│       ├── SYNC.md                   # 上游同步指南
│       ├── VERSION-STRATEGY.md       # 📌 版本管理预防策略
│       └── FORK-SETUP.md             # 📌 Fork 初始化清单
├── scripts/                          # 📌 自动化工具
│   ├── check-versions.ps1            # 版本一致性检查
│   ├── check-versions.sh             # Bash 版本
│   ├── bump-version.ps1              # 自动更新版本号
│   └── pre-commit                    # Git hook
├── plugins/
│   └── compound-engineering/
│       ├── .claude-plugin/plugin.json
│       ├── agents/                   # 29 个 agents
│       ├── commands/                 # 31 个 commands
│       ├── skills/                   # 23 个 skills
│       └── skills-custom/            # 📌 本地自定义技能
├── README.md                         # 上游英文说明（不修改）
└── CLAUDE.md                         # 本文件
```

**📌 标记** = 本地新增内容

---

## 常用操作

| 操作         | 命令                                     |
| ------------ | ---------------------------------------- |
| 同步上游     | 见 `docs/zh-CN/SYNC.md`                  |
| 添加自定义技能 | 直接在 `skills-custom/` 创建目录       |
| 统计组件数量 | 见下方                                   |

### 统计组件数量

```powershell
(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count
(Get-ChildItem -Recurse plugins/compound-engineering/commands/*.md).Count
(Get-ChildItem -Directory plugins/compound-engineering/skills/).Count
```

---

## 更新插件时的检查清单

> **⚠️ 版本号必须同步！** 详见 [版本管理预防策略](docs/zh-CN/VERSION-STRATEGY.md)

### 自动化工具（推荐）

```powershell
# 自动更新版本号（推荐）
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch

# 验证版本一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1

# 安装 pre-commit hook（一次性）
copy scripts\pre-commit .git\hooks\pre-commit
```

### 手动检查清单

- [ ] **同步版本号** - `marketplace.json` = `plugin.json`
- [ ] **更新组件数量** - 本文件、`marketplace.json`、`plugin.json`、README.md
- [ ] **更新 CHANGELOG.md** - 在 `plugins/compound-engineering/CHANGELOG.md` 添加版本记录
- [ ] **更新 README.md** - 在 `plugins/compound-engineering/README.md` 更新功能描述
- [ ] **更新使用说明** - 在 `docs/zh-CN/INSTALL.md` 添加新命令/功能说明
- [ ] **🔄 更新工作流可视化** - 若修改了 workflows 命令，同步更新 `docs/zh-CN/WORKFLOW-VISUAL.md`
- [ ] **更新 Key Learnings** - 在本文件添加重要学习经验（如有）
- [ ] **创建解决方案文档** - 非 trivial 问题添加到 `docs/solutions/`

### 快速检查版本

```powershell
(Get-Content .claude-plugin/marketplace.json | ConvertFrom-Json).plugins[0].version
(Get-Content plugins/compound-engineering/.claude-plugin/plugin.json | ConvertFrom-Json).version
```

---

## 提交规范

```
Add [agent/command name] - 添加新功能
Update [file] to [what changed] - 更新文件
Fix [issue] - Bug 修复

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 相关文档

| 文档                                     | 说明               |
| ---------------------------------------- | ------------------ |
| `docs/zh-CN/WORKFLOW-VISUAL.md`          | 🔄 **工作流可视化指南**（用户必读） |
| `docs/zh-CN/INSTALL.md`                  | 安装与使用指南     |
| `docs/zh-CN/CONCEPTS.md`                 | 核心概念（Skills vs Agents） |
| `docs/zh-CN/SCRIPTS.md`                  | 脚本使用说明       |
| `docs/zh-CN/SYNC.md`                     | 上游同步指南       |
| `docs/zh-CN/VERSION-STRATEGY.md`         | 版本管理预防策略   |
| `docs/zh-CN/FORK-SETUP.md`               | Fork 仓库初始化    |
| `docs/development/VERSIONING.md`         | 版本管理规范（权威） |
| `plugins/compound-engineering/CLAUDE.md` | 插件开发指南       |
| `UPSTREAM-MERGE-RECOMMENDATION.md`       | 🚨 **上游合并推荐**（关键） |
| `docs/MERGE-VISUAL-SUMMARY.md`           | 上游合并可视化摘要 |

---

## 经验与解决方案索引

本项目积累的解决方案文档在 `docs/solutions/`。遇到问题时先搜索这里。

### 集成问题

| 文档 | 关键词 |
|------|--------|
| [🚨 上游合并架构影响分析](docs/solutions/integration-issues/upstream-merge-architectural-analysis-2026-02-10.md) | **上游合并、架构分析、选择性合并、文件删除风险** |
| [Subagent-Driven 工作流整合](docs/solutions/integration-issues/subagent-driven-workflow-integration.md) | 多任务执行、上下文污染、两阶段审查 |
| [Skill 与 Agent 调用方式](docs/solutions/integration-issues/skill-vs-agent-invocation.md) | Task 工具、skills 目录、agents 目录 |
| [Marketplace 更新与终端显示](docs/solutions/integration-issues/marketplace-update-failure-and-unicode-display.md) | 版本号同步、Unicode 特殊字符 |
| [幻影 Agent 引用问题](docs/solutions/integration-issues/phantom-agent-references-in-workflows.md) | 不存在的 agent、上游同步、YAGNI |
| [SessionStart hook type:prompt 不被支持](docs/solutions/integration-issues/sessionstart-hook-prompt-type-not-supported.md) | SessionStart、type:prompt、终端卡死、CLAUDE.md |
| [上游同步整合的完整工作流](docs/solutions/integration-issues/upstream-sync-integration-workflow.md) | git merge --squash、YAML frontmatter、CHANGELOG 标准、多方审核 |
| [Claude Code 运行时更新整合决策](docs/solutions/integration-issues/claude-code-runtime-updates-decisions-2026-02.md) | **runtime updates、Agent Teams、memory frontmatter、hooks、PDF pages、fast mode** |

### 开发规范

| 文档 | 用途 |
|------|------|
| [版本管理策略](docs/zh-CN/VERSION-STRATEGY.md) | 版本号同步、发版检查清单 |
| [脚本使用说明](docs/zh-CN/SCRIPTS.md) | check-versions、bump-version、pre-commit |
| [核心概念](docs/zh-CN/CONCEPTS.md) | Skills vs Agents、组件类型 |

### 快速参考

- **MCP 服务器限制**：插件只能配置无需认证的 HTTP 类型 MCP（如 Context7）
- **安装方式**：`/plugins → Add marketplace → Jerrylalala/compound-engineering-plugin-private`

---

## Codex 审核（可选）

### 方式一：通过 `/workflows:review [C]`（推荐，插件功能）

```bash
# 审核当前分支 + 自动 Codex 审核
/workflows:review [C]

# 审核 PR #123 + 自动 Codex 审核
/workflows:review 123 [C]

# 仅 Claude 多代理审核（不调用 Codex）
/workflows:review
```

**特点：**
- Codex 结果**同步显示在当前会话**
- 自动整合 Claude + Codex 审核结果
- 双方一致的发现优先级更高

### 方式二：手动脚本（开发者工具，不随插件分发）

```bash
# 审核未提交的更改
./scripts/codex-review-now.sh uncommitted

# 审核暂存的更改
./scripts/codex-review-now.sh staged

# 审核整个分支
./scripts/codex-review-now.sh branch
```

### 前提条件

- 安装 Codex CLI: `npm install -g @openai/codex`
- 登录 OpenAI 账户: `codex`（首次运行时）
