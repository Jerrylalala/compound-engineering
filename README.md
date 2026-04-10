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

| 命令 | 用途 |
|------|------|
| `/ce:brainstorm` | 通过对话探索需求，生成需求文档 `[P][C][G][R]` |
| `/ce:plan` | 将需求转化为可执行的实施计划 `[team]` |
| `/ce:work` | 执行计划，支持 Agent Teams、自验证、Playwright `[team][T][PW][C][G]` |
| `/ce:review` | 多代理代码审查，支持自动修复 `[mode:autofix][C][G][team]` |
| `/ce:compound` | 记录解决方案，构建经验库 |

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
