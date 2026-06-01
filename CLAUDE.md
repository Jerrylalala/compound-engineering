# Compound Engineering Plugin

> 本仓库基于 [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) 独立开发，包含中文化、本地扩展和私有覆盖层。
> 本文件是兼容入口；仓库权威规则以 `AGENTS.md` 为准。若本文件与 `AGENTS.md` 冲突，遵循 `AGENTS.md`。

## 公共仓库维护标准（最高优先级）

本仓库按公共开源项目 `Jerrylalala/compound-engineering` 长期维护。后续所有改动都按“陌生用户能安装、能理解、能信任、能贡献”的标准处理，而不是按个人私有工作区或 Claude Code-only 项目处理。

- **定位**：对外表述为多工具 workflow assets + converter/install CLI。Claude Code 是重要兼容面，但不是唯一主线。
- **稳定性**：公开宣称可用前必须有新鲜验证证据；涉及 CLI/转换器运行 `bun test`，涉及 release/manifest 运行 `bun run release:validate`，涉及文档站运行 `mkdocs build --strict`。
- **社区健康**：维护 `LICENSE`、`SECURITY.md`、`PRIVACY.md`、`CONTRIBUTING.md`、`CODE_OF_CONDUCT.md`、`SUPPORT.md`、issue templates、PR template。漏洞报告入口必须指向当前项目维护方，不能默认指向上游作者。
- **文档架构**：`README.md` 是公共第一入口；`docs/zh-CN/` 是用户文档站；`docs/specs/` 是平台协议；`docs/brainstorms/`、`docs/plans/` 是历史和规划记录；`docs/solutions/` 是知识库，不当作清理对象。
- **兼容策略**：保留 Claude Code 兼容，但不让 Claude-only 假设污染 Codex/Gemini/OpenCode 等目标。旧 `workflows:*` 名称若只剩历史意义，必须标为 deprecated 或从用户文档移除。
- **版本策略**：公共 release 由自动化管理；常规 PR 不手动 bump release-owned version，不手写新 release notes。发现 drift 时优先修 release metadata/sync 机制。
- **规则更新**：用户只要求更新规则时，直接改规则文件，不主动 commit；后续产品代码、文档和 CI 改进另开实现任务。

## AI 助手快速入门

### 仓库定位

```
本仓库 = 上游灵感参考 + 中文化层 + 本地扩展（Harness Fusion 覆盖层）
```

| 角色         | 仓库                                            | 说明                 |
| ------------ | ----------------------------------------------- | -------------------- |
| **参考上游** | EveryInc/compound-engineering-plugin            | 参考方向，不强制同步 |
| **本仓库**   | Jerrylalala/compound-engineering | 独立维护的主仓库     |

### 核心原则

1. **可修改所有文件** - 英文文档和中文文档都可以修改
2. **本地扩展隔离** - `skills-custom/` 存放自定义技能
3. **同步上游时注意冲突** - 见 `docs/zh-CN/SYNC.md`

### 本项目的特殊性

本项目是胶水编程的**元层**：创建编排组件本身。

- **全局规则**：见 `~/.claude/CLAUDE.md` 的"胶水编程思维"（默认生效）
- **本项目例外**：创建新 Skill/Agent/Command 时，不需要搜索 GitHub 现成库
  - 因为本项目的工作就是创建编排组件（Skills/Agents/Commands）
  - 但组件内部仍应遵循胶水编程（调用 git/gh/Codex，而非重写）
- **完整工作流**：需要架构规划时使用 `/glue-coding` 技能

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

**文档保留策略（铁律）**：区分「决策记录」和「过渡草稿」：

| 文档类型 | 判断标准 | 处置方式 |
|----------|----------|----------|
| 架构决策 brainstorm | 记录了技术选型、方案对比、设计理由 | **提交到 Git**（与现有 `docs/brainstorms/` 中 19+ 文件一致） |
| 实施计划 plan | 记录了任务分解、实现策略、完成状态 | **提交到 Git**（与现有 `docs/plans/` 中 51+ 文件一致） |
| 过渡草稿 | `*-original.md`、`*-summary.md`、中间版本 | 先问：内容是否已整合到主文档？已整合 → 删除；未整合 → 先整合再删 |
| 纯临时便签 | 用完即弃的调试记录、单次操作指令 | 删除，不提交 |

**判断原则**：如果这个文档记录了「为什么做出这个决定」，就是决策记录，提交。如果只是过渡产物，先确认内容已整合，再删除。

**版本号更新（铁律）**：新增/修改 Agent/Command/Skill 后：
```bash
# 自动更新版本号
powershell -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -BumpType patch

# 验证版本一致性
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```

**新功能/修改必须更新文档（铁律）**：

> 功能代码写完、准备 commit 之前，必须完成以下核查，否则不算完成。**不需要用户提醒，不需要用户询问。**

**触发时机**：写完新 Skill/Command/Agent，或修改了已有命令的行为/参数，准备 commit 时。

**核查清单（逐项确认，跳过需有明确理由）**：

| # | 检查项 | 说明 |
|---|--------|------|
| 1 | `CHANGELOG.md` | 在最新版本号下添加变更描述 |
| 2 | `plugin.json` version | 运行 `bump-version.ps1 -BumpType patch` |
| 3 | `plugin.json` description | 更新组件数量字符串（agents/commands/skills 数字） |
| 4 | `README.md` 工作流表 | 新增命令是否出现在表中；参数变化是否同步 |
| 5 | `README.md` 组件数量 | 比较文本与实际文件数，不一致则更新 |
| 6 | `docs/zh-CN/workflow.html` | **仅当主工作流节点/链路结构变化时**才需更新；纯新增辅助命令可跳过 |

**跳过规则**：
- 第 6 项：新增的是辅助入口命令（非主循环节点）→ 跳过，注明理由
- 第 4/5 项：纯 bug 修复、内部逻辑改动 → 跳过

**外部 AI 审核后综合评判（铁律）**：

> 任何时候调用 Codex / Gemini 审核代码或方案后，Claude 必须做一次**全局综合评判**，而非只采纳外部 AI 的逐条发现。

| 步骤 | 做什么 |
|------|--------|
| 1 | 读取外部 AI 的审核结果 |
| 2 | 逐条独立评判：该发现在本项目上下文中是否成立？（外部 AI 看不到项目全貌） |
| 3 | 全局复查：修复是否引入新的不一致？状态管理、数据流、现有功能是否受影响？ |
| 4 | 修复确认的问题，跳过误判，输出综合结论 |

**适用范围**：`ce:review [C]`（已有裁决协议）、`ce:brainstorm [C]`（方案对比）、`ce:work` 中手动调 Codex 审核（本次场景）——所有调用外部 AI 的场景。

**Codex 集成同步（铁律）**：

> 当修改本仓库中会影响 `brainstorm / plan / review`、共享文档协议、或 Codex 最小技能同步机制的内容时，必须同步更新 Codex 层。

> **严禁**把下面这条命令当作本仓库的日常 Codex 同步方式：
>
> `bun run src/index.ts install ./plugins/compound-engineering --to codex`
>
> 原因：它会把整个转换后的插件重新装进 `~/.codex`，导致多余的 `ce-*`、额外 `workflows-*` 回流，破坏“Codex workflow 只维护 3 个主入口”的目标。

触发条件：
- 修改 `plugins/compound-engineering/commands/workflows/brainstorm.md`
- 修改 `plugins/compound-engineering/commands/workflows/plan.md`
- 修改 `plugins/compound-engineering/commands/workflows/review.md`
- 修改 `docs/brainstorms/` / `docs/plans/` 的共享协议
- 修改 `scripts/sync-codex-workflows.ps1`
- 修改 Codex 工作流使用说明或同步说明

同步目标：
- `.codex/skills/workflows-brainstorm/SKILL.md`
- `.codex/skills/workflows-plan/SKILL.md`
- `.codex/skills/workflows-review/SKILL.md`
- `docs/specs/codex-workflow-compatibility.md`
- `docs/zh-CN/CODEX-WORKFLOWS.md`
- `README.md`
- `scripts/sync-codex-workflows.ps1`

推荐在相关改动完成后运行项目命令：

```text
/sil
```

`/sil` 是本仓库的同步检查步骤，用于确保 Claude 侧改动没有让 Codex 适配层漂移，而且只同步这 3 个 Codex workflow skill。

**AI 执行规范（必须遵守）**：

当你是 Claude Code 或其他 AI 代理，并需要把这 3 个 workflow skill 同步到 Codex 时：

1. **只允许**运行：
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/sync-codex-workflows.ps1
   ```
2. **禁止**运行任何 `install --to codex`
3. 如果用户只是说“同步到 Codex”“更新 Codex 里的版本”“让 Codex 用最新 skill”，默认理解为运行 `scripts/sync-codex-workflows.ps1`
4. 完成后检查 `~/.codex/skills/` 顶层是否包含并更新：
   - `workflows-brainstorm`
   - `workflows-plan`
   - `workflows-review`

   其它用户全局 Codex skills 可以继续存在；同步脚本只清理已知旧 workflow 副本，不删除任意用户技能。

**版本号位置（唯一权威来源）：**
- `plugins/compound-engineering/.claude-plugin/plugin.json` → `version`

**快速检查命令：**
```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-versions.ps1
```


### 安装方式

**推荐：通过 Marketplace 从 GitHub 安装**

```
/plugins → Add marketplace → Jerrylalala/compound-engineering
```

**本地开发：**

```bash
claude --plugin-dir "完整路径\plugins\compound-engineering"
```

---

## 目录结构

```
compound-engineering/
├── .claude-plugin/marketplace.json
├── docs/zh-CN/                        # 中文文档
├── scripts/                           # 自动化工具
├── plugins/compound-engineering/
│   ├── agents/
│   ├── commands/
│   ├── skills/
│   └── skills-custom/                 # 本地自定义技能
├── README.md
└── CLAUDE.md
```

---

## 常用操作

| 操作 | 命令 |
|------|------|
| 同步上游 | 见 `docs/zh-CN/SYNC.md` |
| 添加自定义技能 | 直接在 `skills-custom/` 创建目录 |
| 统计组件数量 | `(Get-ChildItem -Recurse plugins/compound-engineering/agents/*.md).Count` |

---

## 更新插件

**推荐**: `scripts/bump-version.ps1 -BumpType patch`（自动更新 + 验证）
**手动**: 见 [版本管理预防策略](docs/zh-CN/VERSION-STRATEGY.md)

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
| `docs/zh-CN/pencil.html`                 | ✏️ **Pencil MCP 设计联动**（工具列表·工作流·示例） |
| `docs/zh-CN/INSTALL.md`                  | 安装与使用指南     |
| `docs/zh-CN/CONCEPTS.md`                 | 核心概念（Skills vs Agents） |
| `docs/zh-CN/SCRIPTS.md`                  | 脚本使用说明       |
| `docs/zh-CN/SYNC.md`                     | 上游同步指南       |
| `docs/zh-CN/VERSION-STRATEGY.md`         | 版本管理预防策略   |
| `docs/zh-CN/FORK-SETUP.md`               | Fork 仓库初始化    |
| `docs/development/VERSIONING.md`         | 版本管理规范（权威） |
| `plugins/compound-engineering/CLAUDE.md` | 插件开发指南       |

---

## 经验库

使用 Grep 搜索：
- 全局: `~/.compound/solutions/`
- 项目: `docs/solutions/`

或使用 `/workflows:plan`，它会自动搜索两个目录。

---

## Codex 模型策略（强制）

> **铁律**：本项目调用 Codex 时，统一使用 `gpt-5.4`（当前最新模型）。

- **不使用** `gpt-4.1`、`gpt-5.3-codex` 等旧版本（ChatGPT 账户不支持 gpt-4.x）
- **调用方式**：不指定 `-m` 或 `-c model=` 参数，使用 Codex 默认（当前即 gpt-5.4）
- **显式指定**（仅在需要覆盖时）：`codex exec -c "model=gpt-5.4" ...`
- **环境变量**：`export CODEX_MODEL=gpt-5.4`（全局覆盖，用于脚本场景）

配置位置：`plugins/compound-engineering/commands/codex.md` Step 2

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
