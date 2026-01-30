# 中文文档（zh-CN）

本目录用于存放中文说明与使用指南。**我们不修改上游英文文件**，中文内容集中在 `README.zh-CN.md` 与 `docs/zh-CN/`，以降低未来同步上游时的冲突概率。

## 快速上手

1) 转换并安装到 Codex：

```bash
bun run src/index.ts install ./plugins/compound-engineering --to codex
```

2) 在 Codex 中使用中文命令入口：

- `/workflows-zh:plan`
- `/workflows-zh:work`
- `/workflows-zh:review`
- `/workflows-zh:compound`

## 中文化层说明

- 本仓库的中文内容 **仅新增**，不改动上游英文文件。
- 中文命令入口放在 `plugins/compound-engineering/commands/workflows-zh/`。
- 中文说明在 `README.zh-CN.md` 与 `docs/zh-CN/`。

## 自定义技能（skills）

- 投递箱：`plugins/compound-engineering/skills-inbox/`
- 生效目录：`plugins/compound-engineering/skills-custom/`
- 导入脚本：`scripts/import-skills.ps1`

导入流程：把每个技能放入 `skills-inbox/<skill-dir>/`（其中应包含 `SKILL.md` 等文件），然后运行：

```powershell
pwsh scripts/import-skills.ps1
```

脚本会把技能复制到 `skills-custom/<skill-dir>/`，不删除原始文件。

## 同步上游

将来同步上游请运行：

```powershell
pwsh scripts/sync-upstream.ps1
```
