# Compound Engineering

[![Plugin Version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/Jerrylalala/compound-engineering/main/plugins/compound-engineering/.claude-plugin/plugin.json&query=$.version&label=version&color=blue)](plugins/compound-engineering/.claude-plugin/plugin.json)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-online-blue)](https://jerrylalala.github.io/compound-engineering/)

> **中文增强版** Claude Code 复合工程插件 — AI 技能、代理和工作流，让每一个工程单元都比上一个更容易。

📖 **[在线文档](https://jerrylalala.github.io/compound-engineering/)** | 🔄 **[更新日志](CHANGELOG.md)**

---

## 设计哲学

**每一个工程单元都应该让后续单元更容易——而不是更难。**

复合工程反转了技术债务的积累方向。80% 在规划和审查，20% 在执行：
- 写代码前充分规划
- 审查以发现问题并沉淀经验
- 将知识编码，使其可复用
- 保持高质量，让未来的改动更容易

---

## 工作流

```
Brainstorm → Plan → Work → Review → Compound → Repeat
```

| 命令 | 参数 | 用途 |
|------|------|------|
| `/ce:brainstorm` | `[P][C][G][R]` | 通过对话探索需求，生成需求文档 |
| `/ce:plan` | `[team]` | 将需求转化为可执行的实施计划，`[team]` 自动生成 `.team-contract.md` |
| `/ce:work` | `[team][team:full][T][PW][R][C][G]` | 执行计划，`[team]` 启用真实 Agent Teams，`[T]` 四层自验证 |
| `/ce:review` | `[mode:autofix][C][G][team]` | 多代理代码审查，`[team]` 激活合约白名单门控 |
| `/ce:compound` | — | 记录解决方案，构建经验库 |

📊 **[交互式工作流可视化](https://jerrylalala.github.io/compound-engineering/workflow.html)** — 点击每个步骤查看参数说明和使用示例

---

## 安装

### Claude Code（推荐）

```bash
/plugin marketplace add Jerrylalala/compound-engineering
/plugin install compound-engineering
```

### 本地开发

```bash
# 克隆后直接加载本地版本
claude --plugin-dir "/path/to/compound-engineering/plugins/compound-engineering"
```

---

## 主要特性

### [team] 真实 Agent Teams（Claude Code 原生）

`ce:work [team]` 使用 Claude Code 原生 Agent Teams，不是角色扮演：

- **TeamCreate** 创建命名团队（时间戳命名，防碰撞）
- **独立 context window** 的 verifier teammate，不受执行上下文污染
- **SendMessage** 实时通信，每 Unit 完成后触发验证
- **TeamDelete** 收尾清理，无资源泄漏

### [P] 派对模式 + 自动收敛

`ce:brainstorm [P]` 14 个视角发散讨论，结束后**自动触发探索者+挑战者结构化收敛**，无需额外参数。

### [T] 四层自验证

`ce:work [T]` 按任务类型自动选择验证层：
- Layer 0：构建/语法检查
- Layer 1：单元测试
- Layer 2：集成测试
- Layer 3：Playwright 浏览器验收

### Codex / Gemini 双重审查

`/ce:review [C][G]` 同时调用 Codex 和 Gemini 进行交叉验证，对共同发现的问题提升优先级。

---

## 文档

| 文档 | 说明 |
|------|------|
| [在线文档](https://jerrylalala.github.io/compound-engineering/) | 完整文档站点（自动更新） |
| [工作流可视化](docs/zh-CN/WORKFLOW-VISUAL.md) | 流程图和参数说明 |
| [安装指南](docs/zh-CN/INSTALL.md) | 详细安装步骤 |
| [核心概念](docs/zh-CN/CONCEPTS.md) | Skills vs Agents vs Commands |
| [更新日志](CHANGELOG.md) | 版本历史 |

---

## 与同类项目对比

> **项目定位**：本项目不是工具集合，而是在 EveryInc 工程哲学之上，增加了真实多代理编排、分层验证和中文生态支持。

| 项目 | 类型 | 核心特性 | 适合谁 |
|------|------|---------|--------|
| **[EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)** | 工程框架（上游） | Brainstorm→Plan→Work→Review→Compound 工作流哲学；支持 12+ AI 平台转换（Codex/Gemini/Copilot 等） | 任何团队，尤其是多 AI 平台用户 |
| **[本项目](https://github.com/Jerrylalala/compound-engineering)** | 增强 Fork | 在上游基础上：真实 Agent Teams `[team]`、四层自验证 `[T]`、Codex+Gemini 双重审查 `[C][G]`、中文文档 | Claude Code 深度用户，中文团队 |
| **[hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)** | 资源目录 | 500+ 社区技能、工具、Hooks 聚合；最全面的 Claude Code 生态地图 | 想发现 Claude Code 工具的开发者 |
| **[nyldn/claude-octopus](https://github.com/nyldn/claude-octopus)** | 多模型编排 | 同时调度 8 个 AI 模型协作 | 需要跨模型并行的研究/工程场景 |
| **[jarrodwatts/claude-hud](https://github.com/jarrodwatts/claude-hud)** | 状态展示 | Claude Code 状态栏 HUD 插件 | 关注实时状态可见性的用户 |
| **[thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)** | 记忆持久化 | 跨会话记忆系统 | 需要长期上下文保持的用户 |

### 本项目 vs 上游的核心差异

| 能力 | EveryInc 上游 | 本项目 |
|------|--------------|--------|
| Agent Teams | 概念级（角色模拟） | **真实 TeamCreate/SendMessage/TeamDelete** |
| 验证框架 | 无正式分层 | **四层：CLI → API/DB → 浏览器 → 验收** |
| 双模型审查 | 无 | **Codex + Gemini 交叉验证，共识发现提权** |
| 派对模式 | 无 | **14 视角发散 + 自动收敛** |
| 文档语言 | 英文 | **中英双语，在线文档站点** |
| 平台覆盖 | 12+ AI 平台 | **专注 Claude Code 深度集成** |

### 选哪个？

- **用上游** — 你的团队使用多个 AI 平台（Codex/Gemini/Copilot），或者英文优先
- **用本项目** — 你深度使用 Claude Code，需要真实 Agent Teams 和多层验证，或中文团队
- **同时关注** — awesome-claude-code 作为工具发现入口，本项目作为执行框架

---

## Credits

本项目 fork 自 [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)（由 [EveryInc](https://github.com/EveryInc) 创建，MIT 协议）。

在原版基础上进行了以下扩展：
- 全面中文化（命令提示、文档、注释）
- Claude Code Agent Teams 真实多代理实现（TeamCreate/SendMessage/TeamDelete）
- 四层自验证框架（[T] 参数）
- [P] 派对模式后自动结构化收敛
- Codex / Gemini 双重交叉验证
- 私有覆盖层（`skills-custom/`）支持本地扩展

---

## License

MIT — 详见 [LICENSE](LICENSE)
