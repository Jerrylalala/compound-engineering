# Compound Marketplace（中文）

这是 `EveryInc/compound-engineering-plugin` 的私有镜像。本仓库 **不修改上游英文文件**，只新增中文文档层。

- 中文文档：`docs/zh-CN/`
- 中文使用说明：本文件

> 说明：中文版本全部集中在 `README.zh-CN.md` 与 `docs/zh-CN/` 目录中。同步上游时，这些内容不会被覆盖。

## 安装方式

**推荐：通过 Marketplace 安装**

```
/plugins → Add marketplace → Jerrylalala/compound-engineering-plugin-private
```

**本地开发（可选）：**

```bash
claude --plugin-dir "路径/plugins/compound-engineering"
```

## 工作流命令

| 命令 | 说明 |
|------|------|
| `/workflows:load` | 加载项目上下文，恢复之前的会话 |
| `/workflows:brainstorm` | 探索需求和方案 |
| `/workflows:plan` | 把需求描述整理成可执行的计划 |
| `/workflows:work` | 按计划执行并交付 |
| `/workflows:review` | 多代理代码审查 |
| `/workflows:compound` | 沉淀解决方案与知识 |
| `/workflows:save` | 保存项目上下文，用于跨会话恢复 |

## 更多文档

| 文档 | 说明 |
|------|------|
| `docs/zh-CN/INSTALL.md` | 插件安装指南 |
| `docs/zh-CN/SYNC.md` | 上游同步指南 |
| `CLAUDE.md` | 项目指令 |

