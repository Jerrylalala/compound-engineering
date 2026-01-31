# Compound Marketplace（中文）

这是 `EveryInc/compound-engineering-plugin` 的私有镜像。本仓库 **不修改上游英文文件**，只新增中文文档层。

- 中文文档：`docs/zh-CN/`
- 中文使用说明：本文件

> 说明：中文版本全部集中在 `README.zh-CN.md` 与 `docs/zh-CN/` 目录中。同步上游时，这些内容不会被覆盖。

## 本地开发（推荐）

使用 `--plugin-dir` 标志启动 Claude Code：

```bash
claude --plugin-dir "路径/plugins/compound-engineering"
```

或使用启动脚本：
- Windows: 双击 `start-claude.bat`
- macOS/Linux: `./start-claude.sh`

## 工作流命令

| 命令 | 说明 |
|------|------|
| `/workflows:plan` | 把需求描述整理成可执行的计划 |
| `/workflows:work` | 按计划执行并交付 |
| `/workflows:review` | 多代理代码审查 |
| `/workflows:compound` | 沉淀解决方案与知识 |

## 更多中文文档

| 文档 | 说明 |
|------|------|
| `docs/zh-CN/INSTALL.md` | 插件安装指南 |
| `docs/zh-CN/SYNC-WORKFLOW.md` | 上游同步工作流 |
| `docs/zh-CN/README.md` | 中文文档首页 |
