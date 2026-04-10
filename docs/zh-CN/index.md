# Compound Engineering

> **中文增强版** Claude Code 复合工程插件 — AI 技能、代理和工作流，让每一个工程单元都比上一个更容易。

[![Plugin Version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/Jerrylalala/compound-engineering/main/plugins/compound-engineering/.claude-plugin/plugin.json&query=$.version&label=version&color=blue)](https://github.com/Jerrylalala/compound-engineering)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/Jerrylalala/compound-engineering/blob/main/LICENSE)

---

## 设计哲学

**每一个工程单元都应该让后续单元更容易——而不是更难。**

复合工程反转了技术债务的积累方向：
- 写代码前充分规划（brainstorm → plan）
- 审查以发现问题并沉淀经验（review → compound）
- 将知识编码，使其可复用（solutions 经验库）

---

## 工作流

```
Brainstorm → Plan → Work → Review → Compound → Repeat
```

| 命令 | 用途 | 参数 |
|------|------|------|
| `/ce:brainstorm` | 通过对话探索需求，生成需求文档 | `[P][C][G][R]` |
| `/ce:plan` | 将需求转化为可执行实施计划 | `[T]` |
| `/ce:work` | 执行计划，支持 Agent Teams 和多层自验证 | `[T][T+][V][V+][R]` |
| `/ce:review` | 多代理代码审查，支持自动修复 | `[mode:autofix][C][G][T]` |
| `/ce:compound` | 记录解决方案，构建经验库 | — |

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

### 真实 Agent Teams（Claude Code 原生）

`ce:work [T]` 使用 Claude Code 原生 Agent Teams：

- **TeamCreate** 创建命名团队（秒级时间戳，防碰撞）
- **独立 context window** 的 verifier，不受执行上下文污染
- **SendMessage** 每 Unit 完成后实时通信验证
- **TeamDelete** 收尾自动清理

### [P] 派对模式 + 自动收敛

14 个视角发散讨论，结束后自动触发**探索者+挑战者结构化收敛**，找到漏洞，无需额外参数。

### [V] 四层自验证

按任务类型自动选择：构建检查 → 单元测试 → 集成测试 → Playwright 浏览器验收。

---

## 快速导航

- [安装与使用](INSTALL.md) — 详细安装步骤和配置
- [工作流指南](WORKFLOW-VISUAL.md) — 可视化流程图和参数说明
- [Pencil MCP 设计联动](pencil.html) — AI 设计工作流 · 工具列表 · 使用示例
- [核心概念](CONCEPTS.md) — Skills vs Agents vs Commands
- [更新日志](https://github.com/Jerrylalala/compound-engineering/blob/main/CHANGELOG.md) — 版本历史

---

## Credits

Fork 自 [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)（EveryInc，MIT 协议）。  
在原版基础上增加：中文化 · Agent Teams · 四层自验证 · 双重 AI 审查 · 私有覆盖层。
