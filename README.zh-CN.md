# Compound Marketplace（中文）

这是 `EveryInc/compound-engineering-plugin` 的私有镜像。本仓库 **不修改上游英文文件**，只新增一个“中文化层”，便于未来同步上游更新时尽量减少冲突。

- 中文入口：`/workflows-zh:plan`、`/workflows-zh:work`、`/workflows-zh:review`、`/workflows-zh:compound`
- 中文文档：`docs/zh-CN/`
- 中文使用说明：本文件

> 说明：中文版本全部集中在 `README.zh-CN.md` 与 `docs/zh-CN/` 目录中。同步上游时，这些内容不会被覆盖。

## 安装（Claude Code）

```bash
/plugin marketplace add https://github.com/EveryInc/compound-engineering-plugin
/plugin install compound-engineering
```

## 安装（OpenCode + Codex，实验性）

本仓库包含 Bun/TypeScript CLI，可将 Claude Code 插件转换为 OpenCode 或 Codex。

```bash
# 转换为 OpenCode
bunx @every-env/compound-plugin install compound-engineering --to opencode

# 转换为 Codex
bunx @every-env/compound-plugin install compound-engineering --to codex
```

本地开发示例：

```bash
bun run src/index.ts install ./plugins/compound-engineering --to codex
```

Codex 输出目录：
- `~/.codex/prompts`
- `~/.codex/skills`

## 中文命令入口（推荐）

- `/workflows-zh:plan`：把需求描述整理成可执行的计划
- `/workflows-zh:work`：按计划执行并交付
- `/workflows-zh:review`：多代理代码审查
- `/workflows-zh:compound`：沉淀解决方案与知识

## 更多中文文档

详见：`docs/zh-CN/README.md`
