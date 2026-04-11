# Compound Engineering

[![Plugin Version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/Jerrylalala/compound-engineering/main/plugins/compound-engineering/.claude-plugin/plugin.json&query=$.version&label=version&color=blue)](plugins/compound-engineering/.claude-plugin/plugin.json)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-online-blue)](https://jerrylalala.github.io/compound-engineering/)

> **中文增强版** Claude Code 复合工程插件 — 真实 Agent Teams、分层验证、UI 设计联动，让每一个工程单元都比上一个更容易。

📖 **[在线文档](https://jerrylalala.github.io/compound-engineering/)** | 🔄 **[更新日志](CHANGELOG.md)**

---

## 设计哲学

**每一个工程单元都应该让后续单元更容易——而不是更难。**

复合工程反转了技术债务的积累方向。80% 在规划和审查，20% 在执行：
- 写代码前充分规划，审查以发现问题并沉淀经验
- 将知识编码，使其可复用，保持高质量让未来改动更容易

---

## 工作流

```
[Resume] → 0: Ideate/Ideas → 1: Brainstorm → 2: Plan → 3: Work → 4: Review → 5: Compound → Repeat
```

**入口命令**（回到项目 / 选方向）：

| 命令 | 用途 |
|------|------|
| `/ce:resume` | 回归项目入口：读 git log + IDEAS.md + active plan，输出三段摘要 |
| `/ce:ideas` | 管理 IDEAS.md 停车场：无参数选已有方向，有参数生成新方向 |
| `/ce:ideate` | 从零生成新改进方向（无停车场时或想全新探索时） |

**主工作流**：

| # | 命令 | 参数 | 用途 |
|---|------|------|------|
| 1 | `/ce:brainstorm` | `[P][C][G][R]` | 探索需求，生成需求文档；`[P]` 14视角发散+自动收敛 |
| 2 | `/ce:plan` | `[T]` | 制定实施计划，`[T]` 自动生成 `.team-contract.md` |
| 3 | `/ce:work` | `[T][T+][V][V+][R]` | 执行计划，`[T]` 真实 Agent Teams，`[V]` 四层自验证 |
| 4 | `/ce:review` | `[mode:autofix][C][G][T]` | 多代理代码审查，`[T]` 合约白名单门控 |
| 5 | `/ce:compound` | — | 沉淀经验，构建团队知识库 |

---

<!--
  ╔══════════════════════════════════════════════════════════════╗
  ║  点击下方链接，查看每个步骤的参数说明和交互演示              ║
  ╚══════════════════════════════════════════════════════════════╝
-->

### 📊 交互式工作流可视化

> **[→ 打开交互式工作流图](https://jerrylalala.github.io/compound-engineering/workflow.html)**
>
> 点击每个阶段，展开参数详情（真实实现 / 可选增强 / 普通参数三色标注）+ 使用示例代码。

---

## 安装

### Claude Code（推荐）

```bash
/plugin marketplace add Jerrylalala/compound-engineering
/plugin install compound-engineering
```

### 本地开发

```bash
claude --plugin-dir "/path/to/compound-engineering/plugins/compound-engineering"
```

---

## 主要特性

### [T] 真实 Agent Teams（Claude Code 原生）

`ce:work [T]` 使用 Claude Code 原生 Agent Teams，不是角色扮演：

- **TeamCreate** 创建命名团队（时间戳命名，防碰撞）
- **独立 context window** 的 verifier teammate，不受执行上下文污染
- **SendMessage** 实时通信，每 Unit 完成后触发验证
- **TeamDelete** 收尾清理，无资源泄漏

### [V] 四层自验证

`ce:work [V]` 按任务类型自动选择验证层，任务完成必须通过全部激活层：

| Layer | 内容 | 触发条件 |
|-------|------|---------|
| -1.5 | 环境指纹：自动检测应用启动命令（CLAUDE.md 覆盖 → package.json 推导 → 询问一次并持久化） | V/V+ 启用时 |
| 0 | CLI 构建/语法检查 | 始终 |
| 1 | API / 数据库验证 | 后端变更 |
| 2 | 浏览器 UI 验证 | 前端变更 |
| 3 | 独立验收确认 | 始终 |

`[V+]` 额外支持零配置 Electron 桌面应用：自动识别 npm/yarn/pnpm 和 electron-forge，会话内检测启动命令漂移（AI 修改了 package.json scripts 时自动重推导）。

### [P] 派对模式 + 自动收敛

`ce:brainstorm [P]` 14 个专家视角发散讨论（架构/安全/性能/QA…），结束后**自动触发探索者+挑战者结构化收敛**，无需额外参数。

### Codex / Gemini 双重审查 + Claude 裁决

`/ce:review [C][G]` 同时调用 Codex 和 Gemini 进行交叉验证，双方共同发现的问题优先级自动提升。

Claude 收到外部 AI 审核结果后，会先出**裁决表**（`✅ 认同` / `⚠️ 调整实施` / `❌ 不适用`）供用户确认，再动手修复。Claude 是最终裁判，不照单全收——外部 AI 只看局部，Claude 掌握全局上下文。

### 🎨 UI 设计联动（Pencil MCP + Figma）

本插件内置 **UI 设计工作流**，支持从设计到实现的完整链路：

- **Pencil MCP**：在 AI 会话中直接读写 `.pen` 设计文件，生成/修改设计稿，无需切换工具
- **figma-design-sync**：自动对比 Figma 设计图与实现截图，发现视觉偏差，迭代修复
- **frontend-design skill**：生成真实质感的 Web UI（非 AI 模板堆砌），支持响应式、深浅色
- **ce:work Figma 同步**：执行阶段自动检查 UI 实现是否与设计图匹配

```
Pencil 设计 → frontend-design 生成实现 → figma-design-sync 对比验证 → 迭代修复
```

→ **[Pencil MCP 完整设计联动文档](docs/zh-CN/pencil.html)**（工具列表 · 工作流 · 使用示例）

---

## 文档

| 文档 | 说明 |
|------|------|
| [在线文档](https://jerrylalala.github.io/compound-engineering/) | 完整文档站点（自动更新） |
| [交互式工作流](https://jerrylalala.github.io/compound-engineering/workflow.html) | 参数可视化，点击展开详情 |
| [Pencil MCP 设计联动](docs/zh-CN/pencil.html) | AI 设计工作流 · 工具列表 · 使用示例 |
| [安装指南](docs/zh-CN/INSTALL.md) | 详细安装步骤 |
| [核心概念](docs/zh-CN/CONCEPTS.md) | Skills vs Agents vs Commands |
| [更新日志](CHANGELOG.md) | 版本历史 |

---

## 与同类项目对比

> 以下对比基于公开文档和代码，力求客观。各工具侧重点不同，无绝对优劣之分。  
> ✅ = 原生支持 &nbsp; ⚡ = 部分支持 / 需配置 &nbsp; — = 不提供

### 项目概览

| 项目 | 缩写 | 类型 | 核心定位 |
|------|------|------|---------|
| [本项目 (Jerry Fork)](https://github.com/Jerrylalala/compound-engineering) | **CE** | 增强 Fork | 中文 Claude Code 深度工作流，真实 Agent Teams + 分层验证 + UI 设计联动 |
| [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) | **CE-UP** | 上游原版 | 跨平台工程哲学框架（Brainstorm→Compound 循环） |
| [Superpowers plugin](https://github.com/EveryInc/superpowers) | **SP** | Skill 套件 | 规范化工程流程的精选 Skill 集合，无命名 Agent |
| [oh-my-claudecode](https://github.com/oh-my-claudecode/oh-my-claudecode) | **OMCC** | Agent 套件 | 角色化命名 Agent（executor/reviewer/tester…） |
| [ccg-workflow](https://github.com/ccg-workflow/ccg) | **CCG** | Team 命令 | Team 命令式多代理（team-plan/exec/review…） |

---

### Agent / 能力覆盖对比

| 能力维度 | CE（本项目） | CE-UP（上游） | SP（Superpowers） | OMCC | CCG |
|---------|------------|--------------|-----------------|------|-----|
| **需求/范围探索** | ce-brainstorm | ce-brainstorm | brainstorming skill | analyst | — |
| **多视角讨论** | [P] 14 视角 + 自动收敛 | — | — | — | — |
| **规划** | ce-plan | ce-plan | writing-plans skill | planner | /ccg:team-plan |
| **计划审查/挑战** | document-review agents | — | — | — | — |
| **架构/设计评审** | architecture-strategist | — | — | architect | init-architect |
| **调试/根因分析** | systematic-debugging | — | systematic-debugging skill | debugger | — |
| **实现/执行** | ce-work (subagents) | ce-work | executing-plans skill | executor | /ccg:team-exec |
| **代码审查（通用）** | ce-review + 57 agents | ce-review | requesting-code-review skill | code-reviewer | /ccg:team-review |
| **专项审查** | 安全/性能/正确性/可维护性等 10+ 专属 agent | 安全/性能等基础 | — | — | — |
| **测试/TDD** | test-driven-development | — | TDD skill | test-engineer | — |
| **验证/完成证明** | [T] verifier（独立 context） | — | verification-before-completion skill | verifier | /ccg:team-review |
| **知识沉淀** | ce-compound + learnings-researcher | ce-compound | — | — | — |
| **UI 设计联动** | Pencil MCP + figma-design-sync + frontend-design | — | — | — | ui-ux-designer |
| **文档写作** | cn-tech-writer agent | — | — | writer | — |

---

### 关键特性横向对比

| 特性 | CE | CE-UP | SP | OMCC | CCG |
|------|----|----|----|----|-----|
| **真实 Agent Teams** (TeamCreate/SendMessage) | ✅ `[T]` | — | — | — | ⚡ 命令式 |
| **独立 verifier context** | ✅ | — | — | ⚡ 角色模拟 | ⚡ 命令式 |
| **合约白名单门控** | ✅ .team-contract.md | — | — | — | — |
| **分层自验证**（CLI→API→浏览器→验收） | ✅ `[V]` 四层 | — | ⚡ 验证 skill | — | — |
| **双模型交叉审查** | ✅ Codex + Gemini `[C][G]` | — | — | — | — |
| **历史经验检索** | ✅ `[R]` docs/solutions/ | ⚡ | — | — | — |
| **浏览器自动化** | ✅ agent-browser + [V+] | — | — | — | — |
| **UI 设计联动** | ✅ Pencil MCP + Figma | — | — | — | ⚡ |
| **跨 AI 平台支持** | Claude Code 专注 | ✅ 12+ 平台 | Claude Code 专注 | Claude Code 专注 | Claude Code 专注 |
| **中文生态** | ✅ 中英双语 + 在线文档 | 英文 | 英文 | 英文 | 中文 |
| **Skill 数量** | 52+ skills | 40+ skills | 15 skills | — | — |
| **Review Agent 数量** | 57 agents | 40+ agents | — | ~9 agents | — |

---

### 各项目强项总结

| 项目 | 最擅长 | 局限 |
|------|--------|------|
| **CE（本项目）** | 真实 Agent Teams；UI 设计联动；专项审查 agent 最多；中文生态 | 仅 Claude Code；相对新项目，生态较小 |
| **CE-UP（上游）** | 最清晰的工程哲学；跨平台（12+ AI 工具）；社区最成熟 | 无真实 Agent Teams；无分层验证；英文为主 |
| **SP（Superpowers）** | 轻量；Skill 设计模式清晰；适合个人开发者快速上手 | 无命名 Agent；无 Agent Teams；覆盖较少 |
| **OMCC** | 角色化 Agent 设计直观；executor/tester/reviewer 职责清晰 | Agent 协作为角色模拟；无合约机制 |
| **CCG** | Team 命令式多代理架构；有 UI 设计专属 Agent | 命令较固定；知识沉淀弱 |

### 如何选择

- **深度使用 Claude Code / 中文团队** → **本项目 CE**（真实 Agent Teams + 分层验证 + UI 设计联动）
- **多 AI 平台（Codex/Gemini/Copilot 混用）** → **CE-UP 上游**（跨平台最佳）
- **轻量快速启动 / 个人开发** → **SP（Superpowers）**（最简洁）
- **偏好角色化 Agent 分工** → **OMCC** 或 **CCG**

---

## Credits

本项目 fork 自 [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)（由 [EveryInc](https://github.com/EveryInc) 创建，MIT 协议）。

在原版基础上进行了以下扩展：
- 全面中文化（命令提示、文档、注释）
- Claude Code Agent Teams 真实多代理实现（TeamCreate/SendMessage/TeamDelete）
- 四层自验证框架（[V] 参数）
- [P] 派对模式后自动结构化收敛
- Codex / Gemini 双重交叉验证
- Pencil MCP + Figma UI 设计联动
- 私有覆盖层（`skills-custom/`）支持本地扩展

---

## License

MIT — 详见 [LICENSE](LICENSE)
