# Compound Marketplace（中文）

这是 `EveryInc/compound-engineering-plugin` 的私有镜像。本仓库 **不修改上游英文文件**，只新增中文文档层。

- 中文文档：`docs/zh-CN/`
- 中文使用说明：本文件

> 说明：中文版本全部集中在 `README.zh-CN.md` 与 `docs/zh-CN/` 目录中。同步上游时，这些内容不会被覆盖。

## 安装方式

**推荐：通过 Marketplace 安装**

```
/plugins → Add marketplace → Jerrylalala/compound-engineering
```

**本地开发（可选）：**

```bash
claude --plugin-dir "路径/plugins/compound-engineering"
```

**CLI 转换（Codex / Gemini）：**

```bash
# 本地转换（推荐）
cd 你的项目目录
bun run src/index.ts install ./plugins/compound-engineering --to codex
bun run src/index.ts install ./plugins/compound-engineering --to gemini

# 从私有仓库远程安装（临时设置环境变量）
# Windows PowerShell:
$env:COMPOUND_PLUGIN_GITHUB_SOURCE="https://github.com/Jerrylalala/compound-engineering"
bunx @every-env/compound-plugin install compound-engineering --to gemini

# Linux/macOS:
COMPOUND_PLUGIN_GITHUB_SOURCE=https://github.com/Jerrylalala/compound-engineering \
  bunx @every-env/compound-plugin install compound-engineering --to gemini
```

**输出位置：**
- Codex: `~/.codex/prompts/` 和 `~/.codex/skills/`
- Gemini: `<当前目录>/.gemini/GEMINI.md`

> **注意**：`COMPOUND_PLUGIN_GITHUB_SOURCE` 只影响这个 CLI 工具，不会影响其他工具。建议临时设置，不要添加到永久环境变量。

## 工作流命令

| 命令 | 说明 |
|------|------|
| `/ce:brainstorm` | 探索需求和方案 |
| `/ce:plan` | 把需求描述整理成可执行的计划 |
| `/ce:work` | 按计划执行并交付 |
| `/ce:review` | 多代理代码审查 |
| `/ce:compound` | 沉淀解决方案与知识 |

## 更多文档

| 文档 | 说明 |
|------|------|
| `docs/zh-CN/INSTALL.md` | 插件安装指南 |
| `docs/zh-CN/SYNC.md` | 上游同步指南 |
| `CLAUDE.md` | 项目指令 |

