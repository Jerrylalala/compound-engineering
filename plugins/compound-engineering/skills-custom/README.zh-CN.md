# 自定义技能（skills-custom）

本目录用于存放自定义技能的“生效位置”。每个技能一个目录，目录内至少包含 `SKILL.md`（可附带 `assets/`、`references/`、`scripts/` 等）。

## 命名规范（建议）

- 全小写
- 使用短横线分隔（kebab-case）
- 简短、语义清晰

示例：

```
skills-custom/
  code-review-helper/
    SKILL.md
    assets/
    references/
```

## 推荐流程（配合投递箱）

1. 将技能放入：`plugins/compound-engineering/skills-inbox/<skill-dir>/`
2. 运行导入脚本：

```powershell
pwsh scripts/import-skills.ps1
```

脚本会把技能复制到本目录（`skills-custom/<skill-dir>/`），**不会删除原始 inbox 内容**。

如果 inbox 中的技能缺少 `SKILL.md`，脚本会生成模板并提示你补齐。
