# 平台支持矩阵

本文档说明当前公共仓库对不同 AI coding 工具的支持边界。它区分“原生插件能力”和“转换后可用能力”，避免把 Claude Code 专属能力误写成所有平台都支持。

## 总览

| 平台 | 当前状态 | 推荐安装方式 | 能力边界 |
|------|----------|--------------|----------|
| Claude Code | 主支持面 | Marketplace 或 `--plugin-dir` | 完整 `ce:*` 工作流、agents、skills、MCP、Agent Teams |
| Codex | 最小工作流 + 转换支持 | repo-scoped `.codex/skills` 或 CLI 转换 | 适合 brainstorm / plan / review；不等同 Claude Code 执行编排 |
| Gemini CLI | 转换支持 | CLI 转换 | 适合安装 skills 和上下文文件；Claude Code 专属 team/tool 语义会降级 |
| OpenCode | 转换支持 | CLI 转换 | agents、skills、MCP 配置可写入；权限默认保守 |
| Cursor / Copilot / Kiro / Windsurf / Qwen / Pi / Droid / OpenClaw | 转换器覆盖 | CLI 转换 | 以各平台 writer/converter 测试为准；不是所有 Claude Code 运行时能力都有等价物 |

## Claude Code

Claude Code 是本 fork 的完整体验目标：

- `/ce:brainstorm`
- `/ce:plan`
- `/ce:work`
- `/ce:review`
- `/ce:compound`
- Agent Teams: `[T]` / `[T+]`
- 四层自验证: `[V]` / `[V+]`
- Codex / Gemini 外部审查标记: `[C]` / `[G]`

## Codex

Codex 的最优解不是完整复制 Claude Code 插件面，而是保留适合 Codex 的最小工作流：

- `workflows-brainstorm`
- `workflows-plan`
- `workflows-review`

这些入口用于产出共享文档和做审查。执行型编排仍以 Claude Code 的 `ce:work` 为主，除非用户明确要求在 Codex 中执行。

## CLI 转换

CLI 转换命令依赖 [Bun](https://bun.sh/)。公共 CLI 当前 `package.json` 名称为 `@jerry-jian/compound-plugin`，但该包尚未发布到 npm。发布前，公开安装说明应使用已发布的 `@every-env/compound-plugin`，并显式设置：

```bash
COMPOUND_PLUGIN_GITHUB_SOURCE=https://github.com/Jerrylalala/compound-engineering
```

发布 `@jerry-jian/compound-plugin` 后，再把文档默认命令切换为 Jerry 包。过渡期使用 `@every-env/compound-plugin` 时，Codex 完整 standalone 输出需要 `--includeSkills`，Gemini 输出目录使用 `--output`。

## 验证要求

修改任一平台转换逻辑后，至少运行：

```bash
bun test
bun run release:validate
```

修改中文文档站后，运行：

```bash
mkdocs build --strict
```
